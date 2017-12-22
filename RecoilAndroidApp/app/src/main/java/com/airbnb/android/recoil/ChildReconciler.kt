package com.airbnb.android.recoil

data class TraversalContext(
  var root: RecoilRoot?
) {
  var childInstances: MutableMap<String, RecoilInstance> = mutableMapOf()
}

object ChildReconciler {

  // This *right here* is why keys are critical to preventing reordering issues.
  // React will reuse an existing instance if there is one in this subtree.
  // The instance identity here is determined by the generated key based on
  // depth in the tree, parent, and (in React) the key={} prop.
  fun instantiateChild(context: TraversalContext, child: Element, name: String) {
    if (context.childInstances[name] == null) {
      context.childInstances[name] = Reconciler.instantiateComponent(child, context.root)
    }
  }

  fun instantiateChildren(children: Element, root: RecoilRoot?): Map<String, RecoilInstance> {
    // We store the child instances here, which are in turn used passed to
    // instantiateChild. We'll store this object for reuse when doing updates.
    val context = TraversalContext(root)
    traverseAllChildren(children, context, ChildReconciler::instantiateChild)

    return context.childInstances
  }

  fun updateChildren(
      prevChildren: Map<String, RecoilInstance>, // Instances, as created above
      nextChildren: Map<String, Element>, // Actually elements
      mountImages: MutableList<RecoilView?>,
      removedChildren: MutableMap<String, RecoilInstance>,
      root: RecoilRoot?
  ): Map<String, RecoilInstance> {
    val nextChildrenInstances = LinkedHashMap<String, RecoilInstance>()
    // Loop over our new children and determine what is being updated, removed,
    // and created.
    for ((childKey, nextElement) in nextChildren) {
      val prevChild = prevChildren[childKey]
      val prevElement = prevChild?.currentElement

      if (
        prevChild != null &&
        Reconciler.shouldUpdateComponent(prevElement, nextElement)
      ) {
        // Update the existing child with the reconciler. This will recurse
        // through that component's subtree.
        Reconciler.receiveComponent(prevChild, nextElement)

        // We no longer need the new instance, so replace it with the old one.
        nextChildrenInstances[childKey] = prevChild
      } else {
        // Otherwise
        // Remove the old child. We're replacing.
        if (prevChild != null) {
          // TODO: make this work for composites
          removedChildren[childKey] = prevChild
          Reconciler.unmountComponent(prevChild)
        }

        // Instantiate the new child.
        val nextChild = Reconciler.instantiateComponent(nextElement, root)
        nextChildrenInstances[childKey] = nextChild

        // React does this here so that refs resolve in the correct order.
        mountImages.add(Reconciler.mountComponent(nextChild))
      }
    }

    // Last but not least, remove the old children which no longer have any presense.
    for ((childKey, prevChild) in prevChildren) {
      if (nextChildren[childKey] == null) {
        removedChildren[childKey] = prevChild
        Reconciler.unmountComponent(prevChild)
      }
    }
    return nextChildrenInstances
  }

  fun unmountChildren(renderedChildren: Map<String, RecoilInstance>?) {
    if (renderedChildren == null) { return }
    for ((_, child) in renderedChildren) {
      Reconciler.unmountComponent(child)
    }
  }
}
