package com.airbnb.android.recoil

import android.view.ViewGroup

enum class OperationType {
  Insert,
  Move,
  Remove
}

data class Operation(
  val type: OperationType,
  val content: ViewGroup? = null
) {
  var toIndex: Int = -1
  var fromIndex: Int = -1
}


private fun flatten(children: Element?): Map<String, Element> {
  var flattenedChildren = mutableMapOf<String, Element>()

  traverseAllChildren(children, flattenedChildren) { context, child, name ->
    context[name] = child
  }

  return flattenedChildren
}

// In React we do this in an injection point, allowing MultiChild to be used
// across renderers. We don't do that here to reduce overhead.
private fun processQueue(parentNode: ViewGroup, updates: List<Operation>) {
  for (update in updates) {
    when (update.type) {
      OperationType.Insert -> if (update.content != null) parentNode.insertRecoilSubview(update.content, update.toIndex) else return
      OperationType.Move -> parentNode.moveRecoilSubview(update.fromIndex, update.toIndex)
      OperationType.Remove -> parentNode.removeRecoilSubview(update.fromIndex)
    }
  }
}

class RecoilHostInstance(
  override var currentElement: Element,
  override var root: RecoilRoot?
): RecoilInstance {
  override var mountIndex: Int = -1
  override var view: ViewGroup? = null
  var component: HostComponent<*, *>? = null
  var children: Element? = null
  var renderedChildren: Map<String, RecoilInstance>? = null

  override fun mountComponent(): ViewGroup? {
    val root = root ?: throw IllegalStateException()

    val instance = currentElement.makeHostInstance()
    this.component = instance

    val view = instance.mountComponentInternal(root.context)
    this.view = view

    val children = instance.renderChildren()
    this.children = children

    if (children != null) {
      val mountedChildren = mountChildren(children)

      var i = 0
      for (child in mountedChildren) {
        if (child != null) {
          view.insertRecoilSubview(child, i)
          i += 1
        }
      }
    }

    root.enqueueLayout()
    instance.childrenDidMountInternal(view)

    return view
  }

  override fun receiveComponent(element: Element) {
    updateComponent(currentElement, element)
  }

  override fun updateComponent(prevElement: Element, nextElement: Element) {
    val component = this.component ?: throw IllegalStateException()
    val view = this.view ?: throw IllegalStateException()

    currentElement = nextElement

//    val prevHostElement = getHostElement(prevElement)

    // update props
    component.setPropsInternal(nextElement.props)
    component.updateComponentInternal(view, prevElement.props)

    val prevChildren = children
    children = component.renderChildren()

    // update children. skip in the case of no children
    if (prevChildren != null || children != null) {
      updateChildren(children)
    }
    root?.enqueueLayout()
    component.childrenDidUpdateInternal(view, prevElement.props)
  }

  override fun performUpdateIfNecessary() {
    // host components dont have this... does this need to be part of the protocol?
  }

  override fun unmountComponent() {
    // React needs to do some special handling for some node types, specifically
    // removing event handlers that had to be attached to this node and couldn't
    // be handled through propagation.
    unmountChildren()

    root?.enqueueLayout()
  }

  private fun unmountChildren() {
    ChildReconciler.unmountChildren(renderedChildren)
  }

  private fun mountChildren(children: Element): List<ViewGroup?> {
    // Instantiate all of the actual child instances into a flat object. This
    // handles all of the complicated logic around flattening subarrays.
    val rendered = ChildReconciler.instantiateChildren(children, root)
    this.renderedChildren = rendered

    /*
     {
     '.0.0': {_currentElement, ...}
     '.0.1': {_currentElement, ...}
     }
     */

    // We'll turn that renderedChildren object into a flat array and recurse,
    // mounting their children.
    var i = 0
    return rendered.map { (_, child) ->
      child.mountIndex = i
      i += 1
      Reconciler.mountComponent(child)
    }
  }

  private fun updateChildren(nextChildren: Element?) {
    val prevRenderedChildren = renderedChildren ?: mutableMapOf()

    val mountImages = mutableListOf<ViewGroup>()
    val removedNodes = mutableMapOf<String, RecoilInstance>()

    val nextRenderedChildren = flatten(nextChildren)

    val updatedNextRenderedChildren = ChildReconciler.updateChildren(
      prevRenderedChildren,
      nextRenderedChildren,
      mountImages,
      removedNodes,
      root
    )

    // The following is the bread & butter of React. We'll compare the current
    // set of children to the next set.
    // We need to determine what nodes are being moved around, which are being
    // inserted, and which are getting removed. Luckily, the removal list was
    // already determined by the ChildReconciler.

    // We'll store a serious of update operations here.
    var updates = mutableListOf<Operation>()

    var lastIndex = 0
    var nextMountIndex = 0
//    var lastPlacedNode: UIView? = nil
    var nextIndex = 0

    // TODO(lmr): ordered iteration is important here
    for ((childKey, nextChild) in updatedNextRenderedChildren) {
      val prevChild = prevRenderedChildren[childKey]

      // If the are identical, record this as an update. We might have inserted
      // or removed nodes.
      if (prevChild  != null && prevChild == nextChild) {
        // We don't actually need to move if moving to a lower index. Other
        // operations will ensure the end result is correct.
        if (prevChild.mountIndex < lastIndex) {
          val op = Operation(OperationType.Move, null)
          op.fromIndex = prevChild.mountIndex
          op.toIndex = nextIndex
          updates.plus(op)
        }
        lastIndex = maxOf(prevChild.mountIndex, lastIndex)
        prevChild.mountIndex = nextIndex
      } else {
        // Otherwise we need to record an insertion. Removals will be handled below
        // First, if we have a prevChild then we know it's a removal.
        // We want to update lastIndex based on that.
        if (prevChild != null) {
          lastIndex = maxOf(prevChild.mountIndex, lastIndex)
        }

        nextChild.mountIndex = nextIndex
        val content = mountImages[nextMountIndex]
        if (content == null) {
          // this maybe shouldnt be a fatal... i'm not sure...
          throw IllegalStateException("")
        }

        val op = Operation(OperationType.Insert, content)
        op.toIndex = nextChild.mountIndex
        updates.plus(op)
        nextMountIndex += 1
      }

      nextIndex += 1
//      lastPlacedNode = nextChild.view
    }

    // Enqueue removals
    for ((childKey, _) in removedNodes) {
      val prevInstance = prevRenderedChildren[childKey]
      if (prevInstance == null) {
        throw IllegalStateException("")
      }
      val op = Operation(OperationType.Remove, null)
      op.fromIndex = prevInstance.mountIndex
      updates.plus(op)
    }

    val view = this.view ?: throw IllegalStateException("")

    processQueue(view, updates)

    renderedChildren = updatedNextRenderedChildren
  }
}
