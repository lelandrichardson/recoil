//
//  Recoil.swift
//  RecoilFiber
//
//  Created by Leland Richardson on 2/11/18.
//  Copyright © 2018 Leland Richardson. All rights reserved.
//

import Foundation

class RecoilElement {

}


class RecoilComponent {

}

class OpaqueRoot {
  init(containerInfo: UIView, isAsync: Bool, hydrate: Bool) {
    self.current = createHostRootFiber(isAsync: isAsync)
    self.containerInfo = containerInfo
    self.hydrate = hydrate

    // TODO(lmr): Is this a memory leak?
    self.current.stateNode = self
  }
  var containerInfo: UIView
  var pendingChildren: Any?
  var current: Fiber
  var remainingExpirationTime: ExpirationTime = NoWork
  var isReadyForCommit: Bool = false
  var finishedWork: Fiber?
  var context: Any?
  var pendingContext: Any?
  var hydrate: Bool
  var firstBatch: Batch?
  var nextScheduledRoot: OpaqueRoot?
}

class Batch {
  var Defer: Bool = false
  var expirationTime: ExpirationTime = NoWork
  var onComplete: () -> ()?
  var next: Batch?
}

struct RootHolder {
  weak var value: OpaqueRoot?
}


var ContainerMap = [UIView: RootHolder]()

class Recoil {
  static func render(element: RecoilElement, container: UIView, callback: @escaping () -> ()) -> RecoilComponent? {
    let existingRoot = ContainerMap[container]

    if let root = existingRoot?.value {
      Reconciler.updateContainer(element: element, container: root, parentComponent: nil, callback: callback)
      return Reconciler.getPublicRootInstance(root: root)
    }

    let root = Reconciler.createContainer(container: container, isAsync: false, hydrate: false)
    ContainerMap[container] = RootHolder(value: root)

    return Reconciler.unbatchedUpdates {
      Reconciler.updateContainer(element: element, container: root, parentComponent: nil, callback: callback)
      return Reconciler.getPublicRootInstance(root: root)
    }
  }

  static func unmountComponentAtNode(container: UIView) -> Bool {
    let existingRoot = ContainerMap[container]

    if let root = existingRoot?.value {
      Reconciler.unbatchedUpdates {
        Reconciler.updateContainer(element: nil, container: root, parentComponent: nil) {
          ContainerMap.removeValue(forKey: container)
        }
      }
      return true
    } else {
      return false
    }
  }

  static func findHostNode(component: RecoilComponent) -> UIView? {
    // TODO(lmr):
    return nil
  }
}
