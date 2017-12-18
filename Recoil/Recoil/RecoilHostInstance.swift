//
//  RecoilHostInstance.swift
//  Recoil
//
//  Created by Leland Richardson on 12/14/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation

enum Operation {
  case insert(content: UIView, toIndex: Int /*, afterNode: UIView? */)
  case move(fromIndex: Int, toIndex: Int /*, afterNode: UIView? */)
  case remove(fromIndex: Int /*, fromNode: UIView */)
}

private func getHostElement(_ element: Element) -> HostElement {
  switch element {
  case .host(let hostElement):
    return hostElement
  default:
    fatalError()
  }
}

private func flatten(children: Element?) -> [String: Element] {
  var flattenedChildren: [String: Element] = [:]

  let _ = traverseAllChildren(children, &flattenedChildren) { (context: inout [String: Element], child: Element, name: String) in
    context[name] = child
  }

  return flattenedChildren
}

// In React we do this in an injection point, allowing MultiChild to be used
// across renderers. We don't do that here to reduce overhead.
private func processQueue(parentNode: UIView, updates: [Operation]) {
  for update in updates {
    switch update {
    case let .insert(content, toIndex):
      parentNode.insertRecoilSubview(content, at: toIndex)
      break
    case let .move(fromIndex, toIndex):
      parentNode.moveRecoilSubview(from: fromIndex, to: toIndex)
      break
    case let .remove(fromIndex):
      parentNode.removeRecoilSubview(from: fromIndex)
      break
    }
  }
}

class RecoilHostInstance: RecoilInstance {
  var currentElement: Element {
    didSet {
      hostElement = getHostElement(currentElement)
    }
  }
  var mountIndex: Int = -1
  var hostElement: HostElement
  var view: UIView?
  var root: RecoilRoot?
  var component: HostComponentProtocol?
  var children: Element?
  var renderedChildren: [String: RecoilInstance]?

  init(element: Element, root: RecoilRoot?) {
    currentElement = element
    hostElement = getHostElement(element)
    self.root = root
  }

  func mountComponent() -> UIView? {

    let instance = hostElement.type.init(props: hostElement.props)
    self.component = instance

    let view = instance.mountComponentInternal()
    self.view = view

    self.children = instance.renderChildren()

    if let children = children {
      let mountedChildren = mountChildren(children: children)

      var i = 0
      for child in mountedChildren {
        if let child = child {
          view.insertRecoilSubview(child, at: i)
          i += 1
        }
      }
    }

    root?.enqueueLayout()
    component?.childrenDidMountInternal(view: view)

    return view
  }

  func receiveComponent(element: Element) {
    updateComponent(from: currentElement, to: element)
  }

  func updateComponent(from prevElement: Element, to nextElement: Element) {
    guard let component = component, let view = view else {
      // not sure how this would happen
      fatalError()
    }
    currentElement = nextElement

    let prevHostElement = getHostElement(prevElement)

    // update props
    component.setPropsInternal(props: hostElement.props)
    component.updateComponentInternal(view: view, prevProps: prevHostElement.props)

    let prevChildren = children
    children = component.renderChildren()

    // update children. skip in the case of no children
    if prevChildren != nil || children != nil {
      updateChildren(nextChildren: children)
    }
    root?.enqueueLayout()
    component.childrenDidUpdateInternal(view: view, prevProps: prevHostElement.props)
  }

  func performUpdateIfNecessary() {
    // host components dont have this... does this need to be part of the protocol?
  }

  func unmountComponent() {
    // React needs to do some special handling for some node types, specifically
    // removing event handlers that had to be attached to this node and couldn't
    // be handled through propagation.
    unmountChildren()

    root?.enqueueLayout()
  }

  func unmountChildren() {
    ChildReconciler.unmountChildren(renderedChildren: renderedChildren)
  }

  func mountChildren(children: Element) -> [UIView?] {
    // Instantiate all of the actual child instances into a flat object. This
    // handles all of the complicated logic around flattening subarrays.
    let rendered = ChildReconciler.instantiateChildren(children: children, root: root)
    self.renderedChildren = rendered

    /*
     {
     '.0.0': {_currentElement, ...}
     '.0.1': {_currentElement, ...}
     }
     */

    // We'll turn that renderedChildren object into a flat array and recurse,
    // mounting their children.
    var i = 0

    return rendered.map({ (key: String, child: RecoilInstance) -> UIView? in
      child.mountIndex = i
      i += 1
      return Reconciler.mountComponent(instance: child)
    })
  }

  func updateChildren(nextChildren: Element?) {
    let prevRenderedChildren = renderedChildren ?? [:]

    var mountImages: [UIView?] = []
    var removedNodes: [String: RecoilInstance] = [:]

    let nextRenderedChildren = flatten(children: nextChildren)

    let updatedNextRenderedChildren = ChildReconciler.updateChildren(
      prevChildren: prevRenderedChildren,
      nextChildren: nextRenderedChildren,
      mountImages: &mountImages,
      removedChildren: &removedNodes,
      root: root
    )

    // The following is the bread & butter of React. We'll compare the current
    // set of children to the next set.
    // We need to determine what nodes are being moved around, which are being
    // inserted, and which are getting removed. Luckily, the removal list was
    // already determined by the ChildReconciler.

    // We'll store a serious of update operations here.
    var updates: [Operation] = []

    var lastIndex = 0
    var nextMountIndex = 0
//    var lastPlacedNode: UIView? = nil
    var nextIndex = 0

    // TODO(lmr): ordered iteration is important here
    for (childKey, nextChild) in updatedNextRenderedChildren {
      let prevChild = prevRenderedChildren[childKey]

      // If the are identical, record this as an update. We might have inserted
      // or removed nodes.
      if let prevChild = prevChild /*, prevChild === nextChild */ {
        // We don't actually need to move if moving to a lower index. Other
        // operations will ensure the end result is correct.
        if prevChild.mountIndex < lastIndex {
          updates.append(
            .move(
              fromIndex: prevChild.mountIndex,
              toIndex: nextIndex
//              afterNode: lastPlacedNode
            )
          )
        }
        lastIndex = max(prevChild.mountIndex, lastIndex)
        prevChild.mountIndex = nextIndex
      } else {
        // Otherwise we need to record an insertion. Removals will be handled below
        // First, if we have a prevChild then we know it's a removal.
        // We want to update lastIndex based on that.
        if let prevChild = prevChild {
          lastIndex = max(prevChild.mountIndex, lastIndex)
        }

        nextChild.mountIndex = nextIndex
        guard let content = mountImages[nextMountIndex] else {
          // this maybe shouldnt be a fatal... i'm not sure...
          fatalError()
        }
        updates.append(
          .insert(
            content: content,
            toIndex: nextChild.mountIndex
//            afterNode: lastPlacedNode
          )
        )
        nextMountIndex += 1
      }

      nextIndex += 1
//      lastPlacedNode = nextChild.view
    }

    // Enqueue removals
    for (childKey, _) in removedNodes {
      guard let prevInstance = prevRenderedChildren[childKey] else {
        fatalError()
      }
      updates.append(
        .remove(
          fromIndex: prevInstance.mountIndex
//          fromNode: removedInstance.view
        )
      )
    }

    guard let view = view else {
      fatalError()
    }

    processQueue(parentNode: view, updates: updates)

    renderedChildren = updatedNextRenderedChildren
  }
}
