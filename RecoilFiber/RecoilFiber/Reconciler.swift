//
//  Reconciler.swift
//  RecoilFiber
//
//  Created by Leland Richardson on 2/11/18.
//  Copyright © 2018 Leland Richardson. All rights reserved.
//

import Foundation



class Reconciler {

  static func getContextForSubtree(parentComponent: RecoilComponent?) -> Any? {
    return [AnyHashable:AnyObject]()
    // TODO(lmr): finish
  }

  static func createContainer(container: UIView, isAsync: Bool, hydrate: Bool) -> OpaqueRoot {
    return OpaqueRoot(containerInfo: container, isAsync: isAsync, hydrate: hydrate)
  }

  @discardableResult
  static func updateContainer(element: RecoilElement?, container: OpaqueRoot, parentComponent: RecoilComponent?, callback: @escaping () -> ()) -> ExpirationTime {

    let current = container.current
    let expirationTime = Scheduler.computeExpiration(fiber: current)
    return updateContainer(
      expirationTime: expirationTime,
      element: element,
      container: container,
      parentComponent: parentComponent,
      callback: callback
    )
  }

  @discardableResult
  static func updateContainer(expirationTime: ExpirationTime, element: RecoilElement?, container: OpaqueRoot, parentComponent: RecoilComponent?, callback: @escaping () -> ()) -> ExpirationTime {

    let current = container.current
    let context = getContextForSubtree(parentComponent: parentComponent)
    if (container.context == nil) {
      container.context = context
    } else {
      container.pendingContext = context
    }

    return scheduleRootUpdate(
      current: current,
      element: element,
      expirationTime: expirationTime,
      callback: callback
    )
  }

  @discardableResult
  static func unbatchedUpdates<T>(callback: @escaping () -> T) -> T {
    return callback()
  }

  static func getPublicRootInstance(root: OpaqueRoot) -> RecoilComponent? {
    return nil
  }

  static func scheduleRootUpdate(current: Fiber, element: RecoilElement?, expirationTime: ExpirationTime, callback: @escaping () -> ()) -> ExpirationTime {
    let update = Update(partialState: { (a, b) in element })
    update.expirationTime = expirationTime
    UpdateQueue.insertUpdateIntoFiber(fiber: current, update: update)
    Scheduler.scheduleWork(fiber: current, expirationTime: expirationTime)
    return expirationTime
  }
}



















