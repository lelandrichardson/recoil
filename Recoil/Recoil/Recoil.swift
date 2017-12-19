//
//  Recoil.swift
//  Recoil
//
//  Created by Leland Richardson on 12/12/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation

func isRunningInTestEnvironment() -> Bool {
  return true
}

/*
 BIG TODOS:

 - refs
 - proper handling of text children...
 - proper handling of composed Text - View -> Text components
 - vsync batching for setState
 - potentially throw all this work away and reimplement to mimic Fiber's architecture!
 - Animated API?
 - scrollview host component
 - touchable host component
 - textinput host component
 - better color handling
 - view transforms
 - better text font styling
 */

public class Recoil {
  public static func render(_ element: Element, _ rootView: UIView) {

    if let instance = rootView.recoilRoot?.rootInstance {
      // update
      updateInstance(element, rootView, instance)
    } else {
      // mount
      mountInstance(element, rootView)
    }
  }

  public static func unmount(_ rootView: UIView) {
    guard let instance = rootView.recoilRoot?.rootInstance else {
      fatalError()
    }
    unmountInstance(instance, rootView)
  }

  // MARK: private

  private static func updateInstance(_ element: Element, _ rootView: UIView, _ instance: RecoilInstance) {
    if (Reconciler.shouldUpdateComponent(prev: instance.currentElement, next: element)) {
      instance.updateComponent(from: instance.currentElement, to: element)
    } else {
      // Unmount and then mount the new one
      unmountInstance(instance, rootView)
      mountInstance(element, rootView)
    }
  }

  private static func mountInstance(_ element: Element, _ rootView: UIView) {

    let root = RecoilRoot(rootView: rootView)

    rootView.recoilRoot = root

    let instance = Reconciler.instantiateComponent(element: element, root: root)

    root.rootInstance = instance

    let view = Reconciler.mountComponent(instance: instance)

    rootView.removeAllSubviews()

    if let view = view {
      rootView.addSubview(view)
    }

    // let yoga do its thing
    rootView.yoga.isEnabled = true

    // run layout sync
    rootView.yoga.applyLayout(preservingOrigin: false)
  }

  private static func unmountInstance(_ instance: RecoilInstance, _ rootView: UIView) {
    Reconciler.unmountComponent(instance: instance)
    rootView.removeAllSubviews()
    if let root = rootView.recoilRoot {
      root.rootInstance = nil
      root.rootView = nil
      rootView.recoilRoot = nil
    }
  }
}
