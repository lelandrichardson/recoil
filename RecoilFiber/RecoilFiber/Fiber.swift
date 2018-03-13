//
//  Fiber.swift
//  RecoilFiber
//
//  Created by Leland Richardson on 2/10/18.
//  Copyright © 2018 Leland Richardson. All rights reserved.
//

import Foundation

typealias ExpirationTime = UInt64

let NoWork: ExpirationTime = 0
let Sync: ExpirationTime = 1
let Never: ExpirationTime = 0b111111111111111111111111111111 // max 31 bit int

// TODO(lmr): should type and props, instance, etc be rolled into this enum???
enum TypeOfWork {
//  case IndeterminateComponent
//  case FunctionalComponent
  case ClassComponent
  case HostRoot
//  case HostPortal
  case HostComponent
  case HostText
//  case CallComponent
//  case CallHandlerPhase
//  case ReturnComponent
//  case Fragment
//  case Mode
//  case ContextProvider
//  case ContextConsumer
}

//enum TypeOfMode: Int {
//  case NoContext = 0b00
//  case AsyncMode = 0b01
//  case StrictMode = 0b10
//}

typealias TypeOfMode = Int

let NoContext = 0b00
let AsyncMode = 0b01
let StrictMode = 0b10


typealias SideEffect = Int

// Don't change these two values:
let SideEffectNoEffect: SideEffect = 0b00000000;
let SideEffectPerformedWork: SideEffect = 0b00000001;

// You can change the rest (and add more).
let SideEffectPlacement: SideEffect = 0b00000010;
let SideEffectUpdate: SideEffect = 0b00000100;
let SideEffectPlacementAndUpdate: SideEffect = 0b00000110;
let SideEffectDeletion: SideEffect = 0b00001000;
let SideEffectContentReset: SideEffect = 0b00010000;
let SideEffectCallback: SideEffect = 0b00100000;
let SideEffectErr: SideEffect = 0b01000000;
let SideEffectRef: SideEffect = 0b10000000;


enum PriorityLevel: Int {
  case NoWork = 0 // No work is pending.
  case SynchronousPriority = 1 // For controlled text inputs. Synchronous side-effects.
  case TaskPriority = 2 // Completes at the end of the current tick.
  case AnimationPriority = 3 // Needs to complete before the next frame.
  case HighPriority = 4 // Interaction that needs to complete pretty soon to feel responsive.
  case LowPriority = 5 // Data fetching, or result from updating stores.
  case OffscreenPriority = 6 // Won't be visible but do the work in case it becomes visible.
}

//enum Fiber {
//
//}


class RecoilFragment {

}

//enum

private var fiberHashId = 0;

class Fiber: Hashable, Equatable {
  static func == (lhs: Fiber, rhs: Fiber) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }

  init(tag: TypeOfWork, pendingProps: Any?, key: String?, mode: TypeOfMode) {
    self.hashValue = fiberHashId
    fiberHashId = fiberHashId &+ 1
    self.tag = tag
    self.pendingProps = pendingProps
    self.mode = mode
    self.key = key
  }

  convenience init(element: RecoilElement, mode: TypeOfMode, expirationTime: ExpirationTime, key: String?) {
    self.init(tag: .ClassComponent, pendingProps: element, key: key, mode: mode)
    self.expirationTime = expirationTime

    // TODO: more here


  }

//  convenience init(elements: RecoilFragment, mode: TypeOfMode, expirationTime: ExpirationTime, key: String?) {
//    self.init(tag: .Fragment, pendingProps: elements, key: key, mode: mode)
//    self.expirationTime = expirationTime
//  }

  convenience init(content: String, mode: TypeOfMode, expirationTime: ExpirationTime, key: String?) {
    self.init(tag: .HostText, pendingProps: content, key: key, mode: mode)
    self.expirationTime = expirationTime
  }
  var hashValue: Int
  // Unique identifier of this child.
  var key: String?
  var tag: TypeOfWork
  var type: Any? // TODO(lmr):

  // The local state associated with this fiber.
  var stateNode: Any?

  // Conceptual aliases
  // parent : Instance -> return The parent happens to be the same as the
  // return fiber since we've merged the fiber and instance.

  // Remaining fields belong to Fiber

  // The Fiber to return to after finishing processing this one.
  // This is effectively the parent, but there can be multiple parents (two)
  // so this is only the parent of the thing we're currently processing.
  // It is conceptually the same as the return address of a stack frame.
  var Return: Fiber?

  // Singly Linked List Tree Structure.
  var child: Fiber?
  var sibling: Fiber?
  var index: Int = 0

  // TODO(lmr): figure right way to model this
//  var ref: Any?


  // Input is the data coming into process this fiber. Arguments. Props.
  var pendingProps: Any?
  // TODO: I think that there is a way to merge pendingProps and memoizedProps.
  var memoizedProps: Any?

  // A queue of state updates and callbacks.
  var updateQueue: UpdateQueue?

  // The state used to create the output
  var memoizedState: Any?

  // Bitfield that describes properties about the fiber and its subtree. E.g.
  // the AsyncMode flag indicates whether the subtree should be async-by-
  // default. When a fiber is created, it inherits the mode of its
  // parent. Additional flags can be set at creation time, but after than the
  // value should remain unchanged throughout the fiber's lifetime, particularly
  // before its child fibers are created.
  var mode: TypeOfMode = NoContext

  // Effect
  var effectTag: SideEffect = SideEffectNoEffect

  // Singly linked list fast path to the next fiber with side-effects.
  var nextEffect: Fiber?

  // The first and last fiber with side-effect within this subtree. This allows
  // us to reuse a slice of the linked list when we reuse the work done within
  // this fiber.
  var firstEffect: Fiber?
  var lastEffect: Fiber?

  // Represents a time in the future by which this work should be completed.
  // This is also used to quickly determine if a subtree has no pending changes.
  var expirationTime: ExpirationTime = NoWork

  // This is a pooled version of a Fiber. Every fiber that gets updated will
  // eventually have a pair. There are cases when we can clean up pairs to save
  // memory if we need to.
  var alternate: Fiber?
}


func createWorkInProgress(_ current: Fiber, _ pendingProps: Any?, _ expirationTime: ExpirationTime) -> Fiber {
  // We use a double buffering pooling technique because we know that we'll only
  // ever need at most two versions of a tree. We pool the "other" unused node
  // that we're free to reuse. This is lazily created to avoid allocating extra
  // objects for things that are never updated. It also allow us to reclaim the
  // extra memory if needed.

  var workInProgress: Fiber!

  if let wip = current.alternate {
    workInProgress = wip
    workInProgress.pendingProps = pendingProps

    // We already have an alternate.
    // Reset the effect tag.
    workInProgress.effectTag = SideEffectNoEffect

    // The effect list is no longer valid.
    workInProgress.nextEffect = nil
    workInProgress.firstEffect = nil
    workInProgress.lastEffect = nil
  } else {
    workInProgress = Fiber(
      tag: current.tag,
      pendingProps: pendingProps,
      key: current.key,
      mode: current.mode
    )
    workInProgress.type = current.type
    workInProgress.stateNode = current.stateNode
    workInProgress.alternate = current
    current.alternate = workInProgress
  }

  workInProgress.expirationTime = expirationTime;

  workInProgress.child = current.child
  workInProgress.memoizedProps = current.memoizedProps
  workInProgress.memoizedState = current.memoizedState
  workInProgress.updateQueue = current.updateQueue

  // These will be overridden during the parent's reconciliation
  workInProgress.sibling = current.sibling
  workInProgress.index = current.index
//  workInProgress.ref = current.ref

  return workInProgress
}


func createHostRootFiber(isAsync: Bool) -> Fiber {
  return Fiber(tag: .HostRoot, pendingProps: nil, key: nil, mode: isAsync ? AsyncMode | StrictMode : NoContext)
}
























