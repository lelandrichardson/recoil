//
//  Timers.swift
//  RecoilFiber
//
//  Created by Leland Richardson on 2/17/18.
//  Copyright © 2018 Leland Richardson. All rights reserved.
//

import Foundation

protocol Deadline {
  func timeRemaining() -> Int
}

typealias Callback = (_ deadline: Deadline) -> ()
typealias CallbackId = Int

class FrameScheduler {

  func scheduleDeferredCallback(_ callback: Callback, _ timeout: UInt64) -> CallbackId {
    return 1
  }

  func cancelDeferredCallback(_ callbackId: CallbackId) {

  }
}
