//
//  Reconciler.swift
//  Recoil
//
//  Created by Leland Richardson on 12/13/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation


class Reconciler {
  static func instantiateComponent(element: Element, root: RecoilRoot?) -> RecoilInstance {
    switch element {
    case .host(_): return RecoilHostInstance(element: element, root: root)
    case .component(_): return RecoilCompositeInstance(element: element, root: root)
    default: fatalError()
    }
  }

  static func mountComponent(instance: RecoilInstance) -> UIView? {
    let view = instance.mountComponent()

    // React does more work here to ensure that refs work. We don't need to yet.
    return view
  }

  static func receiveComponent(instance: RecoilInstance, element: Element) {
    // Shortcut! We won't do anythign if the next element is the same as the
    // current one. This is unlikely in normal JSX usage, but it an optimization
    // that can be unlocked with Babel's inline-element transform.

//    let prevElement = instance.currentElement;
//    if (prevElement === element) {
//      return;
//    }

    // Defer to the instance.
    instance.receiveComponent(element: element)
  }

  static func performUpdateIfNecessary(instance: RecoilInstance) {
    instance.performUpdateIfNecessary()
  }

  static func shouldUpdateComponent(prev: Element?, next: Element?) -> Bool {
    // if either are nil, return false
    guard let prev = prev, let next = next else {
      return false
    }

    // TODO: deal with key!
    // TODO: deal with strings/literals???

    switch (prev, next) {
    case let (.host(a), .host(b)):
      return a.type == b.type
    case let (.component(a), .component(b)):
      return a.type == b.type
    default:
      return false
    }

  }

  static func unmountComponent(instance: RecoilInstance) {
    // Again, React will do more work here to detach refs. We won't.
    // We'll also continue deferring to the instance to do the real work.
    instance.unmountComponent()
  }
}
