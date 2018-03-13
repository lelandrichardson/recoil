//
//  UpdateQueue.swift
//  RecoilFiber
//
//  Created by Leland Richardson on 2/11/18.
//  Copyright © 2018 Leland Richardson. All rights reserved.
//

import Foundation

class Update {
  init(partialState: @escaping (Any, Any) -> Any) {
    self.partialState = partialState
  }
  var expirationTime: ExpirationTime = NoWork
  var partialState: (Any, Any) -> Any
  var callback: (() -> ())?
  var isReplace: Bool = false
  var isForced: Bool = false
  var next: Update?
}

class UpdateQueue {
  init(baseState: Any?) {
    self.baseState = baseState
  }

  var baseState: Any?
  var expirationTime: ExpirationTime = NoWork
  var first: Update?
  var last: Update?
  var callbackList: [Update]?
  var hasForceUpdate: Bool = false
  var isInitialized: Bool = false



  static func insertUpdateIntoQueue(queue: UpdateQueue, update: Update) {
    if let last = queue.last {
      last.next = update
      queue.last = update
    } else {
      queue.first = update
      queue.last = update
    }
    if (queue.expirationTime == NoWork || queue.expirationTime > update.expirationTime) {
      queue.expirationTime = update.expirationTime
    }
  }

  func commitCallbacks() {
    guard let callbackList = self.callbackList else {
      return
    }
    // Set the list to null to make sure they don't get called more than once.
    self.callbackList = nil
    for update in callbackList {
      // This update might be processed again. Clear the callback so it's only
      // called once.
      let callback = update.callback
      update.callback = nil
      if let callback = callback {
        callback()
      }
    }
  }

  static func insertUpdateIntoFiber(fiber: Fiber, update: Update) {
    // TODO:

    // We'll have at least one and at most two distinct update queues.
    var queue1: UpdateQueue
    if (fiber.updateQueue == nil) {
      // TODO: We don't know what the base state will be until we begin work.
      // It depends on which fiber is the next current. Initialize with an empty
      // base state, then set to the memoizedState when rendering. Not super
      // happy with this approach.
      fiber.updateQueue = UpdateQueue(baseState: nil)
    }
    queue1 = fiber.updateQueue!

  //  var alternate = fiber.alternate
    var queue2: UpdateQueue?

    if let alternate = fiber.alternate {
      queue2 = alternate.updateQueue
      if (queue2 == nil) {
        queue2 = UpdateQueue(baseState: nil)
        alternate.updateQueue = queue2
      }
    }

    if let q2 = queue2, q2 === queue1 {
      queue2 = nil
    }

    // If there's only one queue, add the update to that queue and exit.
    guard let q2 = queue2 else {
      insertUpdateIntoQueue(queue: queue1, update: update)
      return
    }

    // If either queue is empty, we need to add to both queues.
    if (queue1.last == nil || q2.last == nil) {
      insertUpdateIntoQueue(queue: queue1, update: update)
      insertUpdateIntoQueue(queue: q2, update: update)
      return
    }

    // If both lists are not empty, the last update is the same for both lists
    // because of structural sharing. So, we should only append to one of
    // the lists.
    insertUpdateIntoQueue(queue: queue1, update: update)

    // But we still need to update the `last` pointer of queue2.
    q2.last = update
  }

  static func getUpdateExpirationTime(_ fiber: Fiber) -> ExpirationTime {
    if (fiber.tag != .ClassComponent && fiber.tag != .HostRoot) {
      return NoWork
    }
    guard let updateQueue = fiber.updateQueue else {
      return NoWork
    }
    return updateQueue.expirationTime
  }
}

















