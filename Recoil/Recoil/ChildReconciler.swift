//
//  ChildReconciler.swift
//  Recoil
//
//  Created by Leland Richardson on 12/13/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation

class TraversalContext {
  init() {}
  var root: RecoilRoot?
  var childInstances: [String: RecoilInstance] = [:]
}

class ChildReconciler {

  // This *right here* is why keys are critical to preventing reordering issues.
  // React will reuse an existing instance if there is one in this subtree.
  // The instance identity here is determined by the generated key based on
  // depth in the tree, parent, and (in React) the key={} prop.
  static func instantiateChild(context: inout TraversalContext, child: Element, name: String) {
    if context.childInstances[name] == nil {
      context.childInstances[name] = Reconciler.instantiateComponent(element: child, root: context.root)
    }
  }

  static func instantiateChildren(children: Element, root: RecoilRoot?) -> [String: RecoilInstance] {
    // We store the child instances here, which are in turn used passed to
    // instantiateChild. We'll store this object for reuse when doing updates.
    var context = TraversalContext()
    context.root = root
    let _ = traverseAllChildren(children, &context, instantiateChild)

    return context.childInstances
  }

  static func updateChildren(
    prevChildren: [String: RecoilInstance], // Instances, as created above
    nextChildren: [String: Element], // Actually elements
    mountImages: inout [UIView?],
    removedChildren: inout [String: RecoilInstance],
    root: RecoilRoot?) -> [String: RecoilInstance] {
    var nextChildrenInstances: [String: RecoilInstance] = [:]
    // Loop over our new children and determine what is being updated, removed,
    // and created.
    for (childKey, nextElement) in nextChildren {
      let prevChild = prevChildren[childKey]
      let prevElement = prevChild?.currentElement

      if
        let prevChild = prevChild,
        Reconciler.shouldUpdateComponent(prev: prevElement, next: nextElement) {
        // Update the existing child with the reconciler. This will recurse
        // through that component's subtree.
        Reconciler.receiveComponent(instance: prevChild, element: nextElement)

        // We no longer need the new instance, so replace it with the old one.
        nextChildrenInstances[childKey] = prevChild
      } else {
        // Otherwise
        // Remove the old child. We're replacing.
        if let prevChild = prevChild {
          // TODO: make this work for composites
          removedChildren[childKey] = prevChild
          Reconciler.unmountComponent(instance: prevChild)
        }

        // Instantiate the new child.
        let nextChild = Reconciler.instantiateComponent(element: nextElement, root: root)
        nextChildrenInstances[childKey] = nextChild

        // React does this here so that refs resolve in the correct order.
        mountImages.append(Reconciler.mountComponent(instance: nextChild))
      }
    }

    // Last but not least, remove the old children which no longer have any presense.
    for (childKey, prevChild) in prevChildren {
      if nextChildren[childKey] == nil {
        removedChildren[childKey] = prevChild
        Reconciler.unmountComponent(instance: prevChild)
      }
    }
    return nextChildrenInstances
  }

  static func unmountChildren(renderedChildren: [String: RecoilInstance]?) {
    guard let renderedChildren = renderedChildren else { return }
    for (_, child) in renderedChildren {
      Reconciler.unmountComponent(instance: child)
    }
  }
}
