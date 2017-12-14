//
//  Recoil.swift
//  Recoil
//
//  Created by Leland Richardson on 12/12/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation

/*
 BIG TODOS:

 - element keys
 - refs
 - proper handling of text children...
 - proper handling of composed Text - View -> Text components
 - functional components
 - component state
 - full lifecycle methods
 - potentially throw all this work away and reimplement to mimic Fiber's architecture!

 */


public class Recoil {
  public static func render(_ element: Element, _ rootView: UIView) {

    if let instance = rootView.recoilRoot {
      // update
      updateInstance(element, rootView, instance)
    } else {
      // mount
      mountInstance(element, rootView)
    }
  }

  public static func unmount(_ rootView: UIView) {
    guard let instance = rootView.recoilRoot else {
      fatalError()
    }
    unmountInstance(instance, rootView)
  }



  // MARK: private

  private static func updateInstance(_ element: Element, _ rootView: UIView, _ instance: RecoilInstance) {
    if (Reconciler.shouldUpdateComponent(prev: instance.currentElement, next: element)) {
      // TODO(lmr): do the update
    } else {
      // Unmount and then mount the new one
      unmountInstance(instance, rootView)
      mountInstance(element, rootView)
    }
  }

  private static func mountInstance(_ element: Element, _ rootView: UIView) {

    let instance = Reconciler.instantiateComponent(element)

    let view = Reconciler.mountComponent(instance: instance)

     rootView.removeAllSubviews()

    if let view = view {
      rootView.addSubview(view)
    }

    // let yoga do its thing
    rootView.yoga.isEnabled = true

    // run layout
    rootView.yoga.applyLayout(preservingOrigin: false)
  }

  private static func unmountInstance(_ instance: RecoilInstance, _ rootView: UIView) {
    Reconciler.unmountComponent(instance: instance)
    rootView.removeAllSubviews()
    rootView.recoilRoot = nil
  }
}
