//
//  FiberScheduler.swift
//  RecoilFiber
//
//  Created by Leland Richardson on 2/11/18.
//  Copyright © 2018 Leland Richardson. All rights reserved.
//

import Foundation

class ReactCurrentOwner {
  static var current: Fiber? = nil
}

//typealias Ref = (UIView?) -> ()

//typealias TI = UITextView
//typealias T

// Represents the expiration time that incoming updates should use. (If this
// is NoWork, use the default strategy: async updates in async mode, sync
// updates in sync mode.)
private var expirationContext: ExpirationTime = NoWork
private var isWorking: Bool = false
private var startTime = 0 // TODO(lmr)
private var lastUniqueAsyncExpiration = 0
private var nextUnitOfWork: Fiber?
private var nextRoot: OpaqueRoot?
private var nextRenderExpirationTime: ExpirationTime = NoWork
private var nextEffect: Fiber?
//private var capturedErrors: [Fiber: CapturedError]?
//private var failedbounders: Set
private var commitPhaseBoundaries = Set<Fiber>()
//private var firstUncaughtError
//private var didFatal = false
private var isCommitting = false
private var isUnmounting = false
private var interruptedBy: Fiber?

// TODO: Everything below this is written as if it has been lifted to the
// renderers. I'll do this in a follow-up.

// Linked-list of roots

private var firstScheduledRoot: OpaqueRoot?
private var lastScheduledRoot: OpaqueRoot?
private var callbackExpirationTime: ExpirationTime = NoWork
private var callbackID: Int = -1
private var isRendering = false
private var nextFlushedRoot: OpaqueRoot?
private var nextFlushedExpirationTime: ExpirationTime = NoWork
private var lowestPendingInteractiveExpirationTime: ExpirationTime = NoWork
private var deadlineDidExpire = false
private var hasUnhandledError = false
private var unhandledError: Any?
private var deadline: Deadline?

private var isBatchingUpdates = false
private var isUnbatchingUpdates = false
private var isBatchingInteractiveUpdates = false

private var completedBatches: [Batch]?

private var timeHeuristicForUnitOfWork = 1

private var NESTED_UPDATE_LIMIT = 1000
private var nestedUpdateCount = 0

private let UNIT_SIZE: UInt64 = 10 // TODO(lmr): what is this exactly? should we increase it since we are using nanoseconds?
private let MAGIC_NUMBER_OFFSET: UInt64 = 2

class Scheduler {

  // MARK: Timing

  private static let frameScheduler = FrameScheduler()
  private static var startTime = now()
  private static var mostRecentCurrentTime: ExpirationTime = nanoToExpirationTime(0)

  static func now() -> UInt64 {
    return mach_absolute_time()
  }

  static func expirationTimeToNano(_ expirationTime: ExpirationTime) -> UInt64 {
    return (expirationTime - MAGIC_NUMBER_OFFSET) * UNIT_SIZE
  }

  static func nanoToExpirationTime(_ nano: UInt64) -> ExpirationTime {
    // Always add an offset so that we don't clash with the magic number for NoWork.
    return ((nano / UNIT_SIZE) | 0) + MAGIC_NUMBER_OFFSET
  }

  static func recalculateCurrentTime() -> ExpirationTime {
    // Subtract initial time so it fits inside 32bits
    let elapsed = now() - startTime
    var timeBaseInfo = mach_timebase_info_data_t()
    mach_timebase_info(&timeBaseInfo)
    let elapsedNano = elapsed * UInt64(timeBaseInfo.numer) / UInt64(timeBaseInfo.denom);

    mostRecentCurrentTime = nanoToExpirationTime(elapsedNano)
    return mostRecentCurrentTime
  }

  static func computeExpiration(fiber: Fiber) -> ExpirationTime {
    var expirationTime: ExpirationTime = NoWork
    if (expirationContext == NoWork) {
      expirationTime = expirationContext
    } else if (isWorking) {
      // TODO(lmr):

    }
    return expirationTime
  }

  static func scheduleCallbackWithExpiration(_ expirationTime: ExpirationTime) {
    if (callbackExpirationTime != NoWork) {
      // A callback is already scheduled. Check its expiration time (timeout).
      if (expirationTime > callbackExpirationTime) {
        // Existing callback has sufficient timeout. Exit.
        return
      } else {
        // Existing callback has insufficient timeout. Cancel and schedule a
        // new one.
        // cIC
        frameScheduler.cancelDeferredCallback(callbackID)
      }
      // The request callback timer is already running. Don't start a new one.
    } else {
//      startRequestCallbackTimer()
    }

    // Compute a timeout for the given expiration time.
    let currentNano = now() - startTime
    let expirationNano = expirationTimeToNano(expirationTime)
    let timeout = expirationNano - currentNano

    callbackExpirationTime = expirationTime
    callbackID = frameScheduler.scheduleDeferredCallback(performAsyncWork, timeout)
  }

  static func resetExpirationTime(
    _ workInProgress: Fiber,
    _ renderTime: ExpirationTime
  ) {
    if (renderTime != Never && workInProgress.expirationTime == Never) {
      // The children of this component are hidden. Don't bubble their
      // expiration times.
      return
    }

    // Check for pending updates.
    var newExpirationTime = UpdateQueue.getUpdateExpirationTime(workInProgress)

    // TODO: Calls need to visit stateNode

    // Bubble up the earliest expiration time.
    var nextChild = workInProgress.child
    while let child = nextChild {
      if (
        child.expirationTime != NoWork &&
          (newExpirationTime == NoWork ||
            newExpirationTime > child.expirationTime)
      ) {
        newExpirationTime = child.expirationTime
      }
      nextChild = child.sibling
    }
    workInProgress.expirationTime = newExpirationTime
  }

  static func shouldYield() -> Bool {
    guard let deadline = deadline else { return false }
    if (deadline.timeRemaining() > timeHeuristicForUnitOfWork) {
      // Disregard deadline.didTimeout. Only expired work should be flushed
      // during a timeout. This path is only hit for non-expired work.
      return false
    }
    deadlineDidExpire = true
    return true
  }

  static func checkRootNeedsClearing(
    _ root: OpaqueRoot,
    _ fiber: Fiber,
    _ expirationTime: ExpirationTime
  ) {
    if (!isWorking && root === nextRoot && expirationTime < nextRenderExpirationTime) {
      // Restart the root from the top.
      if (nextUnitOfWork != nil) {
        // This is an interruption. (Used for performance tracking.)
        interruptedBy = fiber
      }
      nextRoot = nil
      nextUnitOfWork = nil
      nextRenderExpirationTime = NoWork
    }
  }

  static func commitRoot(_ finishedWork: Fiber) -> ExpirationTime {
    // We keep track of this so that captureError can collect any boundaries
    // that capture an error during the commit phase. The reason these aren't
    // local to this function is because errors that occur during cWU are
    // captured elsewhere, to prevent the unmount from being interrupted.
    isWorking = true
    isCommitting = true
//    startCommitTimer()

    let root = finishedWork.stateNode as! OpaqueRoot
    precondition(
      root.current !== finishedWork,
      "Cannot commit the same tree as before."
    )
    root.isReadyForCommit = false

    // Reset this to null before calling lifecycles
    ReactCurrentOwner.current = nil // TODO(lmr):

    var firstEffect: Fiber?
    if (finishedWork.effectTag > SideEffectPerformedWork) {
      // A fiber's effect list consists only of its children, not itself. So if
      // the root has an effect, we need to add it to the end of the list. The
      // resulting list is the set that would belong to the root's parent, if
      // it had one; that is, all the effects in the tree including the root.
      if let lastEffect = finishedWork.lastEffect {
        lastEffect.nextEffect = finishedWork
        firstEffect = finishedWork.firstEffect
      } else {
        firstEffect = finishedWork
      }
    } else {
      // There is no effect on the root.
      firstEffect = finishedWork.firstEffect
    }

    prepareForCommit(root.containerInfo)

    // Commit all the side-effects within a tree. We'll do this in two passes.
    // The first pass performs all the host insertions, updates, deletions and
    // ref unmounts.
    nextEffect = firstEffect
//    startCommitHostEffectsTimer()
    while (nextEffect != nil) {
//      let didError = false
//      let error
//      try {
      commitAllHostEffects()
//      } catch (e) {
//      didError = true
//      error = e
//      }
//      if (didError) {
//        precondition(
//          nextEffect !== null,
//          "Should have next effect.",
//        )
//        captureError(nextEffect, error)
//        // Clean-up
//        if (nextEffect !== nil) {
//          nextEffect = nextEffect.nextEffect
//        }
//      }
    }
//    stopCommitHostEffectsTimer()

    resetAfterCommit(root.containerInfo)

    // The work-in-progress tree is now the current tree. This must come after
    // the first pass of the commit phase, so that the previous tree is still
    // current during componentWillUnmount, but before the second pass, so that
    // the finished work is current during componentDidMount/Update.
    root.current = finishedWork

    // In the second pass we'll perform all life-cycles and ref callbacks.
    // Life-cycles happen as a separate pass so that all placements, updates,
    // and deletions in the entire tree have already been invoked.
    // This pass also triggers any renderer-specific initial effects.
    nextEffect = firstEffect
//    startCommitLifeCyclesTimer()
    while (nextEffect != nil) {
//      let didError = false
//      let error
//
//      try {
      commitAllLifeCycles()
//      } catch (e) {
//      didError = true;
//      error = e;
//      }

//      if (didError) {
//        precondition(
//          nextEffect != nil,
//          "Should have next effect."
//        )
//        captureError(nextEffect, error)
//        if (nextEffect !== null) {
//          nextEffect = nextEffect.nextEffect
//        }
//      }
    }

    isCommitting = false
    isWorking = false
//    stopCommitLifeCyclesTimer()
//    stopCommitTimer()
//    if (typeof onCommitRoot === 'function') {
//      onCommitRoot(finishedWork.stateNode)
//    }

    // If we caught any errors during this commit, schedule their boundaries
    // to update.
//    if (commitPhaseBoundaries) {
//      commitPhaseBoundaries.forEach(scheduleErrorRecovery)
//      commitPhaseBoundaries = nil
//    }

//    if (firstUncaughtError != nil) {
//      const error = firstUncaughtError
//      firstUncaughtError = nil
//      onUncaughtError(error)
//    }

    let remainingTime = root.current.expirationTime

//    if (remainingTime == NoWork) {
//      capturedErrors = nil
//      failedBoundaries = nil
//    }

    return remainingTime
  }

  static func commitAllHostEffects() {
    while let next = nextEffect {
//      recordEffect()

      let effectTag = next.effectTag
      if (effectTag & SideEffectContentReset != 0) {
        commitResetTextContent(next)
      }

//      if (effectTag & SideEffectRef != 0) {
//        if let current = next.alternate {
//          commitDetachRef(current)
//        }
//      }

      // The following switch statement is only concerned about placement,
      // updates, and deletions. To avoid needing to add a case for every
      // possible bitmap value, we remove the secondary effects from the
      // effect tag and switch on that value.
      let primaryEffectTag =
        effectTag & ~(SideEffectCallback | SideEffectErr | SideEffectContentReset | SideEffectRef | SideEffectPerformedWork)

      switch (primaryEffectTag) {
      case SideEffectPlacement:
        commitPlacement(next)
        // Clear the "placement" from effect tag so that we know that this is inserted, before
        // any life-cycles like componentDidMount gets called.
        // TODO: findDOMNode doesn't rely on this any more but isMounted
        // does and isMounted is deprecated anyway so we should be able
        // to kill this.
        next.effectTag &= ~SideEffectPlacement
        break
      case SideEffectPlacementAndUpdate:
        // Placement
        commitPlacement(next)
        // Clear the "placement" from effect tag so that we know that this is inserted, before
        // any life-cycles like componentDidMount gets called.
        next.effectTag &= ~SideEffectPlacement

        // Update
        let current = next.alternate
        commitWork(current, next)
        break
      case SideEffectUpdate:
        let current = next.alternate
        commitWork(current, next)
        break
      case SideEffectDeletion:
        isUnmounting = true
        commitDeletion(next)
        isUnmounting = false
        break
      default:
        break
      }
      nextEffect = next.nextEffect
    }
  }

  static func workLoop(_ isAsync: Bool) {
//    if (capturedErrors != nil) {
//      // If there are unhandled errors, switch to the slow work loop.
//      // TODO: How to avoid this check in the fast path? Maybe the renderer
//      // could keep track of which roots have unhandled errors and call a
//      // forked version of renderRoot.
//      slowWorkLoopThatChecksForFailedWork(isAsync)
//      return
//    }
    if (!isAsync) {
      // Flush all expired work.
      while let next = nextUnitOfWork {
        nextUnitOfWork = performUnitOfWork(next)
      }
    } else {
      // Flush asynchronous work until the deadline runs out of time.
      while let next = nextUnitOfWork, !shouldYield() {
        nextUnitOfWork = performUnitOfWork(next)
      }
    }
  }

  static func performUnitOfWork(_ workInProgress: Fiber) -> Fiber? {
    // The current, flushed, state of this fiber is the alternate.
    // Ideally nothing should rely on this, but relying on it here
    // means that we don't need an additional field on the work in
    // progress.
    let current = workInProgress.alternate

    // See if beginning this work spawns more work.
//    startWorkTimer(workInProgress)
    var next = beginWork(current, workInProgress, nextRenderExpirationTime)

    if (next == nil) {
      // If this doesn't spawn new work, complete the current work.
      next = completeUnitOfWork(workInProgress)
    }

    ReactCurrentOwner.current = nil

    return next
  }

  static func completeUnitOfWork(_ workInProgress: Fiber) -> Fiber? {
    var workInProgress = workInProgress
    while (true) {
      // The current, flushed, state of this fiber is the alternate.
      // Ideally nothing should rely on this, but relying on it here
      // means that we don't need an additional field on the work in
      // progress.
      let current = workInProgress.alternate
      let next = completeWork(
        current,
        workInProgress,
        nextRenderExpirationTime
      )
      let returnFiber = workInProgress.Return
      let siblingFiber = workInProgress.sibling

      resetExpirationTime(workInProgress, nextRenderExpirationTime)

      if let next = next {
//        stopWorkTimer(workInProgress)
        // If completing this work spawned new work, do that next. We'll come
        // back here again.
        return next
      }

      if let returnFiber = returnFiber {
        // Append all the effects of the subtree and this fiber onto the effect
        // list of the parent. The completion order of the children affects the
        // side-effect order.
        if (returnFiber.firstEffect == nil) {
          returnFiber.firstEffect = workInProgress.firstEffect
        }
        if let wipLastEffect = workInProgress.lastEffect {
          if let rfLastEffect = returnFiber.lastEffect {
            rfLastEffect.nextEffect = workInProgress.firstEffect
          }
          returnFiber.lastEffect = wipLastEffect
        }

        // If this fiber had side-effects, we append it AFTER the children's
        // side-effects. We can perform certain side-effects earlier if
        // needed, by doing multiple passes over the effect list. We don't want
        // to schedule our own side-effect on our own list because if end up
        // reusing children we'll schedule this effect onto itself since we're
        // at the end.
        let effectTag = workInProgress.effectTag
        // Skip both NoWork and PerformedWork tags when creating the effect list.
        // PerformedWork effect is read by React DevTools but shouldn't be committed.
        if (effectTag > SideEffectPerformedWork) {
          if let rfLastEffect = returnFiber.lastEffect {
            rfLastEffect.nextEffect = workInProgress
          } else {
            returnFiber.firstEffect = workInProgress
          }
          returnFiber.lastEffect = workInProgress
        }
      }

//      stopWorkTimer(workInProgress)
      if let siblingFiber = siblingFiber {
        // If there is more work to do in this returnFiber, do that next.
        return siblingFiber
      } else if let returnFiber = returnFiber {
        // If there's no more work in this returnFiber. Complete the returnFiber.
        workInProgress = returnFiber
        continue
      } else {
        // We've reached the root.
        // TODO(lmr): this could be modeled as enum AST
        let root = workInProgress.stateNode as! OpaqueRoot
        root.isReadyForCommit = true
        return nil
      }
    }
    // TODO Remove the above while(true) loop
    return nil
  }

  static func renderRoot(_ root: OpaqueRoot, _ expirationTime: ExpirationTime, _ isAsync: Bool) -> Fiber? {
    precondition(!isWorking, "renderRoot was called recursively.")

    isWorking = true

    // We're about to mutate the work-in-progress tree. If the root was pending
    // commit, it no longer is: we'll need to complete it again.
    root.isReadyForCommit = false

    // Check if we're starting from a fresh stack, or if we're resuming from
    // previously yielded work.
    if (root !== nextRoot ||
        expirationTime != nextRenderExpirationTime ||
        nextUnitOfWork == nil
      ) {
      // Reset the stack and start working from the root.
//      resetContextStack()
      nextRoot = root
      nextRenderExpirationTime = expirationTime
      nextUnitOfWork = createWorkInProgress(
        current: root.current,
        pendingProps: nil,
        expirationTime: expirationTime
      )
    }

//    startWorkLoopTimer(nextUnitOfWork)

//    let didError = false;
//    let error = null
//    try {
    workLoop(isAsync)
//    } catch (e) {
//    didError = true;
//    error = e;
//    }

    // An error was thrown during the render phase.
//    while (didError) {
//      if (didFatal) {
//        // This was a fatal error. Don't attempt to recover from it.
//        firstUncaughtError = error;
//        break;
//      }
//
//      guard let failedWork = nextUnitOfWork else {
//        // An error was thrown but there's no current unit of work. This can
//        // happen during the commit phase if there's a bug in the renderer.
//        didFatal = true
//        continue
//      }
//
//      // "Capture" the error by finding the nearest boundary. If there is no
//      // error boundary, we use the root.
//      let boundary = captureError(failedWork, error)
//      precondition(
//        boundary !== null,
//        "Should have found an error boundary."
//      )
//
//      if (didFatal) {
//        // The error we just captured was a fatal error. This happens
//        // when the error propagates to the root more than once.
//        continue
//      }
//
//      didError = false
//      error = nil
//      try {
//      renderRootCatchBlock(root, failedWork, boundary, isAsync);
//      error = nil
//      } catch (e) {
//      didError = true
//      error = e;
//      continue
//      }
//      // We're finished working. Exit the error loop.
//      break
//    }

//    let uncaughtError = firstUncaughtError

    // We're done performing work. Time to clean up.
//    stopWorkLoopTimer(interruptedBy)
    interruptedBy = nil
    isWorking = false
//    didFatal = false
//    firstUncaughtError = nil

//    if (uncaughtError != nil) {
//      onUncaughtError(uncaughtError)
//    }

    return root.isReadyForCommit ? root.current.alternate : nil
  }

  static func commitAllLifeCycles() {
    while let next = nextEffect {
      let effectTag = next.effectTag

      if (effectTag & (SideEffectUpdate | SideEffectCallback) != 0) {
//        recordEffect()
        let current = next.alternate
        commitLifeCycles(current, next)
      }

//      if (effectTag & SideEffectRef != 0) {
////        recordEffect()
//        commitAttachRef(next)
//      }

//      if (effectTag & SideEffectErr != 0) {
//        recordEffect()
//        commitErrorHandling(next)
//      }

      let nextNext = next.nextEffect
      // Ensure that we clean these up so that we don't accidentally keep them.
      // I'm not actually sure this matters because we can't reset firstEffect
      // and lastEffect since they're on every node, not just the effectful
      // ones. So we have to clean everything as we reuse nodes anyway.
      next.nextEffect = nil
      // Ensure that we reset the effectTag here so that we can rely on effect
      // tags to reason about the current life-cycle.
      nextEffect = nextNext
    }
  }

  static func completeRoot(_ root: OpaqueRoot, _ finishedWork: Fiber, _ expirationTime: ExpirationTime) {
    // Check if there's a batch that matches this expiration time.
    if let firstBatch = root.firstBatch, firstBatch.expirationTime <= expirationTime {
      if var batches = completedBatches {
        batches.append(firstBatch)
      } else {
        completedBatches = [firstBatch]
      }

      if (firstBatch.Defer) {
        // This root is blocked from committing by a batch. Unschedule it until
        // we receive another update.
        root.finishedWork = finishedWork
        root.remainingExpirationTime = NoWork
        return
      }
    }

    // Commit the root.
    root.finishedWork = nil
    root.remainingExpirationTime = commitRoot(finishedWork)
  }

  static func performWorkOnRoot(_ root: OpaqueRoot, _ expirationTime: ExpirationTime, _ isAsync: Bool) {
    if (isRendering) {
      preconditionFailure("performWorkOnRoot was called recursively.")
    }

    isRendering = true

    // Check if this is async work or sync/expired work.
    if (!isAsync) {
      // Flush sync work.
      if let finishedWork = root.finishedWork {
        // This root is already complete. We can commit it.
        completeRoot(root, finishedWork, expirationTime)
      } else {
        root.finishedWork = nil
        if let finishedWork = renderRoot(root, expirationTime, false) {
          // We've completed the root. Commit it.
          completeRoot(root, finishedWork, expirationTime)
        }
      }
    } else {
      // Flush async work.
      if let finishedWork = root.finishedWork {
        // This root is already complete. We can commit it.
        completeRoot(root, finishedWork, expirationTime)
      } else {
        root.finishedWork = nil
        if let finishedWork = renderRoot(root, expirationTime, true) {
          // We've completed the root. Check the deadline one more time
          // before committing.
          if (!shouldYield()) {
            // Still time left. Commit the root.
            completeRoot(root, finishedWork, expirationTime)
          } else {
            // There's no time left. Mark this root as complete. We'll come
            // back and commit it later.
            root.finishedWork = finishedWork
          }
        }
      }
    }

    isRendering = false
  }

  static func requestWork(_ root: OpaqueRoot, _ expirationTime: ExpirationTime) {
    // Add the root to the schedule.
    // Check if this root is already part of the schedule.
    if root.nextScheduledRoot != nil {
      // This root is already scheduled, but its priority may have increased.
      let remainingExpirationTime = root.remainingExpirationTime
      if (remainingExpirationTime == NoWork ||
          expirationTime < remainingExpirationTime
        ) {
        // Update the priority.
        root.remainingExpirationTime = expirationTime
      }
    } else {
      // This root is not already scheduled. Add it.
      root.remainingExpirationTime = expirationTime
      if let lastRoot = lastScheduledRoot {
        lastRoot.nextScheduledRoot = root
        lastScheduledRoot = root
        root.nextScheduledRoot = firstScheduledRoot
      } else {
        firstScheduledRoot = root
        lastScheduledRoot = root
        root.nextScheduledRoot = root
      }
    }

    if (isRendering) {
      // Prevent reentrancy. Remaining work will be scheduled at the end of
      // the currently rendering batch.
      return
    }

    if (isBatchingUpdates) {
      if (isUnbatchingUpdates) {
        // Flush work at the end of the batch.
        // ...unless we're inside unbatchedUpdates, in which case we should
        // flush it now.
        nextFlushedRoot = root
        nextFlushedExpirationTime = Sync
        performWorkOnRoot(root, Sync, false)
      }
      return
    }

    // TODO: Get rid of Sync and use current time?
    if (expirationTime == Sync) {
      performSyncWork()
    } else {
      scheduleCallbackWithExpiration(expirationTime)
    }
  }

  static func findHighestPriorityRoot() {
    var highestPriorityWork = NoWork
    var highestPriorityRoot: OpaqueRoot? = nil

    if let lsr = lastScheduledRoot {
      var previousScheduledRoot = lsr
      var iroot = firstScheduledRoot
      while let root = iroot {
        let remainingExpirationTime = root.remainingExpirationTime
        if (remainingExpirationTime == NoWork) {
          // This root no longer has work. Remove it from the scheduler.

          // TODO: This check is redudant, but Flow is confused by the branch
          // below where we set lastScheduledRoot to null, even though we break
          // from the loop right after.
//          precondition(
//            previousScheduledRoot != nil && lastScheduledRoot != nil,
//            "Should have a previous and last root"
//          )
          if (root === root.nextScheduledRoot) {
            // This is the only root in the list.
            root.nextScheduledRoot = nil
            firstScheduledRoot = nil
            lastScheduledRoot = nil
            break
          } else if (root === firstScheduledRoot) {
            // This is the first root in the list.
            let next = root.nextScheduledRoot
            firstScheduledRoot = next
            lsr.nextScheduledRoot = next
            root.nextScheduledRoot = nil
          } else if (root === lastScheduledRoot) {
            // This is the last root in the list.
            lastScheduledRoot = previousScheduledRoot
            lsr.nextScheduledRoot = firstScheduledRoot
            root.nextScheduledRoot = nil
            break
          } else {
            previousScheduledRoot.nextScheduledRoot = root.nextScheduledRoot
            root.nextScheduledRoot = nil
          }
          iroot = previousScheduledRoot.nextScheduledRoot
        } else {
          if (
            highestPriorityWork == NoWork ||
              remainingExpirationTime < highestPriorityWork
            ) {
            // Update the priority, if it's higher
            highestPriorityWork = remainingExpirationTime
            highestPriorityRoot = root
          }
          if (root === lastScheduledRoot) {
            break
          }
          previousScheduledRoot = root
          iroot = root.nextScheduledRoot
        }
      }
    }

    // If the next root is the same as the previous root, this is a nested
    // update. To prevent an infinite loop, increment the nested update count.
    if let previousFlushedRoot = nextFlushedRoot, (
      previousFlushedRoot === highestPriorityRoot
    ) {
      nestedUpdateCount += 1
    } else {
      // Reset whenever we switch roots.
      nestedUpdateCount = 0
    }
    nextFlushedRoot = highestPriorityRoot
    nextFlushedExpirationTime = highestPriorityWork
  }

  static func performAsyncWork(_ deadline: Deadline) {
    performWork(NoWork, true, deadline)
  }

  static func performSyncWork() {
    performWork(Sync, false, nil)
  }

  static func performWork(_ minExpirationTime: ExpirationTime, _ isAsync: Bool, _ dl: Deadline?) {
    deadline = dl

    // Keep working on roots until there's no more work, or until the we reach
    // the deadline.
    findHighestPriorityRoot()

//    if (enableUserTimingAPI && deadline != nil) {
//      let didExpire = nextFlushedExpirationTime < recalculateCurrentTime()
//      stopRequestCallbackTimer(didExpire)
//    }

    if (isAsync) {
      while let nextFlushedRoot = nextFlushedRoot,
          (nextFlushedExpirationTime != NoWork &&
          (minExpirationTime == NoWork ||
            minExpirationTime >= nextFlushedExpirationTime) &&
          (!deadlineDidExpire ||
            recalculateCurrentTime() >= nextFlushedExpirationTime)
        ) {
          performWorkOnRoot(
            nextFlushedRoot,
            nextFlushedExpirationTime,
            !deadlineDidExpire
          )
          findHighestPriorityRoot()
      }
    } else {
      while let nextFlushedRoot = nextFlushedRoot, (
          nextFlushedExpirationTime != NoWork &&
          (minExpirationTime == NoWork ||
            minExpirationTime >= nextFlushedExpirationTime)
        ) {
          performWorkOnRoot(nextFlushedRoot, nextFlushedExpirationTime, false)
          findHighestPriorityRoot()
      }
    }

    // We're done flushing work. Either we ran out of time in this callback,
    // or there's no more work left with sufficient priority.

    // If we're inside a callback, set this to false since we just completed it.
    if (deadline != nil) {
      callbackExpirationTime = NoWork
      callbackID = -1
    }
    // If there's work left over, schedule a new callback.
    if (nextFlushedExpirationTime != NoWork) {
      scheduleCallbackWithExpiration(nextFlushedExpirationTime)
    }

    // Clean-up.
    deadline = nil
    deadlineDidExpire = false
    nestedUpdateCount = 0

    finishRendering()
  }

  static func finishRendering() {
    if let batches = completedBatches {
//      let batches = completedBatches
      completedBatches = nil
//      for (let i = 0; i < batches.length; i++) {
//        let batch = batches[i]
      for batch in batches {
//        try {
          batch.onComplete()
//        } catch (error) {
//          if (!hasUnhandledError) {
//            hasUnhandledError = true;
//            unhandledError = error;
//          }
//        }
      }
    }

//    if (hasUnhandledError) {
//      let error = unhandledError
//      unhandledError = nil
//      hasUnhandledError = false
//      throw error
//    }
  }

  static func scheduleWork(fiber: Fiber, expirationTime: ExpirationTime) {
//    recordScheduleUpdate()

    var node: Fiber = fiber
    while true {
      if (node.expirationTime == NoWork ||
          node.expirationTime > expirationTime
        ) {
        node.expirationTime = expirationTime
      }
      if let alternate = node.alternate {
        if (alternate.expirationTime == NoWork ||
            alternate.expirationTime > expirationTime
          ) {
          alternate.expirationTime = expirationTime
        }
      }
      guard let Return = node.Return else {
        if (node.tag == .HostRoot) {
          // TODO(lmr): should this be in the enum?
          let root = node.stateNode as! OpaqueRoot

          checkRootNeedsClearing(root, fiber, expirationTime)
          requestWork(root, expirationTime)
          checkRootNeedsClearing(root, fiber, expirationTime)
        }
        return
      }
      node = Return
    }
  }

  // MARK: Begin Work

  static func beginWork(
    _ current: Fiber?,
    _ workInProgress: Fiber,
    _ renderExpirationTime: ExpirationTime
    ) -> Fiber? {
    if (workInProgress.expirationTime == NoWork ||
      workInProgress.expirationTime > renderExpirationTime
    ) {
      return bailoutOnLowPriority(current, workInProgress)
    }

    switch (workInProgress.tag) {
//    case .IndeterminateComponent:
//      return mountIndeterminateComponent(
//        current,
//        workInProgress,
//        renderExpirationTime
//      )
//    case .FunctionalComponent:
//      return updateFunctionalComponent(current, workInProgress)
    case .ClassComponent:
      return updateClassComponent(
        current,
        workInProgress,
        renderExpirationTime
      )
    case .HostRoot:
      return updateHostRoot(current, workInProgress, renderExpirationTime)
    case .HostComponent:
      return updateHostComponent(
        current,
        workInProgress,
        renderExpirationTime
      )
    case .HostText:
      return updateHostText(current, workInProgress);
//    case .CallHandlerPhase:
//      // This is a restart. Reset the tag to the initial phase.
//      workInProgress.tag = .CallComponent
//    // Intentionally fall through since this is now the same.
//    case .CallComponent:
//      return updateCallComponent(
//        current,
//        workInProgress,
//        renderExpirationTime
//      )
//    case .ReturnComponent:
//      // A return component is just a placeholder, we can just run through the
//      // next one immediately.
//      return nil
//    case .HostPortal:
//      return updatePortalComponent(
//        current,
//        workInProgress,
//        renderExpirationTime
//      )
//    case .Fragment:
//      return updateFragment(current, workInProgress)
//    case .Mode:
//      return updateMode(current, workInProgress)
//    case .ContextProvider:
//      return updateContextProvider(
//        current,
//        workInProgress,
//        renderExpirationTime
//      )
//    case .ContextConsumer:
//      return updateContextConsumer(
//        current,
//        workInProgress,
//        renderExpirationTime
//      )
//    default:
//      preconditionFailure("Unknown unit of work tag")
    }
  }

  static func bailoutOnLowPriority(_ current: Fiber?, _ workInProgress: Fiber) -> Fiber? {
//    cancelWorkTimer(workInProgress)

    // TODO: Handle HostComponent tags here as well and call pushHostContext()?
    // See PR 8590 discussion for context
    switch (workInProgress.tag) {
    case .HostRoot:
      pushHostRootContext(workInProgress)
      break
    case .ClassComponent:
      pushLegacyContextProvider(workInProgress)
      break
//    case .HostPortal:
//      pushHostContainer(
//        workInProgress,
//        workInProgress.stateNode.containerInfo
//      )
//      break
//    case .ContextProvider:
//      pushProvider(workInProgress)
//      break
    default:
      // do nothing...
      break
    }
    // TODO: What if this is currently in progress?
    // How can that happen? How is this not being cloned?
    return nil
  }

  static func updateClassComponent(
    _ current: Fiber?,
    _ workInProgress: Fiber,
    _ renderExpirationTime: ExpirationTime
    ) -> Fiber {
    // Push context providers early to prevent context stack mismatches.
    // During mounting we don't know the child context yet as the instance doesn't exist.
    // We will invalidate the child context in finishClassComponent() right after rendering.
    let hasContext = pushLegacyContextProvider(workInProgress)

    var shouldUpdate = false
    if let current = current {
      shouldUpdate = updateClassInstance(
        current,
        workInProgress,
        renderExpirationTime
      )
    } else {
      if (workInProgress.stateNode == nil) {
        // In the initial pass we might need to construct the instance.
        constructClassInstance(workInProgress, workInProgress.pendingProps)
        mountClassInstance(workInProgress, renderExpirationTime)

        shouldUpdate = true
      } else {
        preconditionFailure("Resuming work not yet implemented.")
        // In a resume, we'll already have an instance we can reuse.
        // shouldUpdate = resumeMountClassInstance(workInProgress, renderExpirationTime);
      }
    }
    return finishClassComponent(
      current,
      workInProgress,
      shouldUpdate,
      hasContext
    )
  }

  static func finishClassComponent(
    _ current: Fiber?,
    _ workInProgress: Fiber,
    _ shouldUpdate: Bool,
    _ hasContext: Bool
  ) -> Fiber? {
    // Refs should update even if shouldComponentUpdate returns false
//    markRef(current, workInProgress)

    if (!shouldUpdate) {
      // Context providers should defer to sCU for rendering
//      if (hasContext) {
//        invalidateContextProvider(workInProgress, false)
//      }

      return bailoutOnAlreadyFinishedWork(current, workInProgress)
    }

    let instance = workInProgress.stateNode

    // Rerender
    ReactCurrentOwner.current = workInProgress
    let nextChildren = instance.render()

    // React DevTools reads this flag.
    workInProgress.effectTag |= SideEffectPerformedWork
    reconcileChildren(current, workInProgress, nextChildren);
    // Memoize props and state using the values we just used to render.
    // TODO: Restructure so we never read values from the instance.
    memoizeState(workInProgress, instance.state);
    memoizeProps(workInProgress, instance.props);

    // The context might have changed so we need to recalculate it.
//    if (hasContext) {
//      invalidateContextProvider(workInProgress, true);
//    }

    return workInProgress.child
  }

  static func reconcileChildrenAtExpirationTime(
    _ current: Fiber?,
    _ workInProgress: Fiber,
    _ nextChildren: Any?,
    _ renderExpirationTime: ExpirationTime
  ) {
    if let current = current {
      // If the current child is the same as the work in progress, it means that
      // we haven't yet started any work on these children. Therefore, we use
      // the clone algorithm to create a copy of all the current children.

      // If we had any progressed work already, that is invalid at this point so
      // let's throw it out.
      workInProgress.child = reconcileChildFibers(
        workInProgress,
        current.child,
        nextChildren,
        renderExpirationTime
      )
    } else {
      // If this is a fresh new component that hasn't been rendered yet, we
      // won't update its child set by applying minimal side-effects. Instead,
      // we will add them all to the child before it gets rendered. That means
      // we can optimize this reconciliation pass by not tracking side-effects.
      workInProgress.child = mountChildFibers(
        workInProgress,
        nil,
        nextChildren,
        renderExpirationTime
      )
    }
  }

  // MARK: Child Fiber

  static func useFiber(
    _ fiber: Fiber,
    _ pendingProps: Any?,
    _ expirationTime: ExpirationTime
  ) -> Fiber {
    // We currently set sibling to null and index to 0 here because it is easy
    // to forget to do before returning it. E.g. for the single child case.
    let clone = createWorkInProgress(fiber, pendingProps, expirationTime)
    clone.index = 0
    clone.sibling = nil
    return clone
  }

  static func reconcileSingleElement(
    returnFiber: Fiber,
    currentFirstChild: Fiber?,
    element: ReactElement,
    expirationTime: ExpirationTime
  ) -> Fiber {
    let key = element.key
    var nextChild = currentFirstChild
    while let child = nextChild {
      // TODO: If key === null and child.key === null, then this only applies to
      // the first item in the list.
      if (child.key === key) {
        if (child.type === element.type) {
          deleteRemainingChildren(returnFiber, child.sibling);
          let existing = useFiber(
            child,
            element.props,
            expirationTime
          )
//          existing.ref = coerceRef(returnFiber, child, element)
          existing.Return = returnFiber
          return existing
        } else {
          deleteRemainingChildren(returnFiber, child)
          break
        }
      } else {
        deleteChild(returnFiber, child)
      }
      nextChild = child.sibling
    }

    let created = Fiber(
      element: element,
      mode: returnFiber.mode,
      expirationTime: expirationTime,
      key: nil
    )
//    created.ref = coerceRef(returnFiber, currentFirstChild, element)
    created.Return = returnFiber
    return created
  }

  static func reconcileChildFibers(
    returnFiber: Fiber,
    currentFirstChild: Fiber?,
    newChild: Any?,
    expirationTime: ExpirationTime
    ) -> Fiber? {
    // This function is not recursive.
    // If the top level item is an array, we treat it as a set of children,
    // not as a fragment. Nested arrays on the other hand will be treated as
    // fragment nodes. Recursion happens at the normal flow.

    // Handle top level unkeyed fragments as if they were arrays.
    // This leads to an ambiguity between <>{[...]}</> and <>...</>.
    // We treat the ambiguous cases above the same.
//    if (
//      typeof newChild === 'object' &&
//        newChild !== null &&
//        newChild.type === REACT_FRAGMENT_TYPE &&
//        newChild.key === null
//      ) {
//      newChild = newChild.props.children;
//    }

    // Handle object types
    const isObject = typeof newChild === 'object' && newChild !== null;

    if (isObject) {
      switch (newChild.$$typeof) {
      case REACT_ELEMENT_TYPE:
        return placeSingleChild(
          reconcileSingleElement(
            returnFiber,
            currentFirstChild,
            newChild,
            expirationTime,
            ),
        );
      case REACT_PORTAL_TYPE:
        return placeSingleChild(
          reconcileSinglePortal(
            returnFiber,
            currentFirstChild,
            newChild,
            expirationTime,
            ),
        );
      }
    }

    if (typeof newChild === 'string' || typeof newChild === 'number') {
      return placeSingleChild(
        reconcileSingleTextNode(
          returnFiber,
          currentFirstChild,
          '' + newChild,
          expirationTime,
          ),
      );
    }

    if (isArray(newChild)) {
      return reconcileChildrenArray(
        returnFiber,
        currentFirstChild,
        newChild,
        expirationTime,
      );
    }

    if (getIteratorFn(newChild)) {
      return reconcileChildrenIterator(
        returnFiber,
        currentFirstChild,
        newChild,
        expirationTime,
      );
    }

    if (isObject) {
      throwOnInvalidObjectType(returnFiber, newChild);
    }

    if (__DEV__) {
      if (typeof newChild === 'function') {
        warnOnFunctionType();
      }
    }
    if (typeof newChild === 'undefined') {
      // If the new child is undefined, and the return fiber is a composite
      // component, throw an error. If Fiber return types are disabled,
      // we already threw above.
      switch (returnFiber.tag) {
      case ClassComponent: {
        if (__DEV__) {
          const instance = returnFiber.stateNode;
          if (instance.render._isMockFunction) {
            // We allow auto-mocks to proceed as if they're returning null.
            break;
          }
        }
        }
        // Intentionally fall through to the next case, which handles both
        // functions and classes
      // eslint-disable-next-lined no-fallthrough
      case FunctionalComponent: {
        const Component = returnFiber.type;
        invariant(
          false,
          '%s(...): Nothing was returned from render. This usually means a ' +
            'return statement is missing. Or, to render nothing, ' +
          'return null.',
          Component.displayName || Component.name || 'Component',
          );
        }
      }
    }

    // Remaining cases are all treated as empty.
    return deleteRemainingChildren(returnFiber, currentFirstChild);
  }


  // MARK: Complete Work

  static func completeWork(
    _ current: Fiber?,
    _ workInProgress: Fiber,
    _ renderExpirationTime: ExpirationTime
  ) -> Fiber? {
    let newProps = workInProgress.pendingProps
    switch (workInProgress.tag) {
//    case .FunctionalComponent:
//      return nil
    case .ClassComponent:
      // We are leaving this subtree, so pop context if any.
//      popLegacyContextProvider(workInProgress)
      return nil
    case .HostRoot:
//      popHostContainer(workInProgress)
//      popTopLevelLegacyContextObject(workInProgress)
      if let fiberRoot = workInProgress.stateNode as? OpaqueRoot,
        let pendingContext = fiberRoot.pendingContext {
        fiberRoot.context = pendingContext
        fiberRoot.pendingContext = nil
      }

      if (current?.child == nil) {
        // If we hydrated, pop so that we can delete any remaining children
        // that weren't hydrated.
//        popHydrationState(workInProgress)
        // This resets the hacky state to fix isMounted before committing.
        // TODO: Delete this when we delete isMounted and findDOMNode.
        workInProgress.effectTag &= ~SideEffectPlacement
      }
//      updateHostContainer(workInProgress)
      return nil
    case .HostComponent:
//      popHostContext(workInProgress)
//      let rootContainerInstance = getRootHostContainer()
      let type = workInProgress.type
      if let current = current,
        let instance = workInProgress.stateNode as? UIView {
        // If we have an alternate, that means this is an update and we need to
        // schedule a side-effect to do the updates.
        let oldProps = current.memoizedProps
        // If we get updated because one of our children updated, we don't
        // have newProps so we'll have to reuse them.
        // TODO: Split the update API as separate for the props vs. children.
        // Even better would be if children weren't special cased at all tho.
//        let currentHostContext = getHostContext()
        let updatePayload = prepareUpdate(
          instance,
          type,
          oldProps,
          newProps
//          rootContainerInstance,
//          currentHostContext
        )

        updateHostComponent(
          current,
          workInProgress,
          updatePayload,
          type,
          oldProps,
          newProps
//          rootContainerInstance,
//          currentHostContext
        )

//        if let currentRef = current.ref,
//          let workInProgressRef = workInProgress.ref,
//          currentRef !== workInProgressRef {
//          markRef(workInProgress)
//        }
      } else {
        guard let newProps = newProps else {
          precondition(
            workInProgress.stateNode != nil,
            "We must have new props for new mounts"
          )
          // This can happen when we abort work.
          return nil
        }

//        let currentHostContext = getHostContext()
        // TODO: Move createInstance to beginWork and keep it on a context
        // "stack" as the parent. Then append children as we go in beginWork
        // or completeWork depending on we want to add then top->down or
        // bottom->up. Top->down is faster in IE11.
//        let wasHydrated = popHydrationState(workInProgress)
//        if (wasHydrated) {
//          // TODO: Move this and createInstance step into the beginPhase
//          // to consolidate.
//          if (
//            prepareToHydrateHostInstance(
//              workInProgress,
//              rootContainerInstance,
//              currentHostContext
//            )
//          ) {
//            // If changes to the hydrated node needs to be applied at the
//            // commit-phase we mark this as such.
//            markUpdate(workInProgress)
//          }
//        } else {
          let instance = createInstance(
            type,
            newProps,
//            rootContainerInstance,
//            currentHostContext,
            workInProgress
          )

          appendAllChildren(instance, workInProgress)

          // Certain renderers require commit-time effects for initial mount.
          // (eg DOM renderer supports auto-focus for certain elements).
          // Make sure such renderers get scheduled for later work.
          if (
            finalizeInitialChildren(
              instance,
              type,
              newProps
//              rootContainerInstance,
//              currentHostContext
            )
          ) {
            markUpdate(workInProgress)
          }
          workInProgress.stateNode = instance
//        }

//        if (workInProgress.ref != nil) {
//          // If there is a ref on a host node we need to schedule a callback
//          markRef(workInProgress)
//        }
      }
      return nil
    case .HostText:
      let newText = newProps
      if let current = current,
        let stateNode = workInProgress.stateNode {
        let oldText = current.memoizedProps
        // If we have an alternate, that means this is an update and we need
        // to schedule a side-effect to do the updates.
        updateHostText(current, workInProgress, oldText, newText)
      } else {
        guard let newText = newText as? String else {
          precondition(
            workInProgress.stateNode != nil,
            "We must have new props for new mounts"
          )
          // This can happen when we abort work.
          return nil
        }
//        let rootContainerInstance = getRootHostContainer()
//        let currentHostContext = getHostContext()
//        let wasHydrated = popHydrationState(workInProgress)
//        if (wasHydrated) {
//          if (prepareToHydrateHostTextInstance(workInProgress)) {
//            markUpdate(workInProgress)
//          }
//        } else {
          workInProgress.stateNode = createTextInstance(
            newText,
//            rootContainerInstance,
//            currentHostContext,
            workInProgress
          )
//        }
      }
      return nil
//    case .CallComponent:
//      return moveCallToHandlerPhase(
//        current,
//        workInProgress,
//        renderExpirationTime
//      )
//    case .CallHandlerPhase:
//      // Reset the tag to now be a first phase call.
//      workInProgress.tag = .CallComponent
//      return nil
//    case .ReturnComponent:
//      // Does nothing.
//      return nil
//    case .Fragment:
//      return nil
//    case .Mode:
//      return nil
//    case .HostPortal:
//      popHostContainer(workInProgress)
//      updateHostContainer(workInProgress)
//      return nil
//    case .ContextProvider:
//      // Pop provider fiber
//      popProvider(workInProgress)
//      return nil
//    case .ContextConsumer:
//      return nil
    // Error cases
//    case .IndeterminateComponent:
//      preconditionFailure("An indeterminate component should have become determinate before completing")
//    default:
//      preconditionFailure("Unknown unit of work tag")
    }
  }

  static func appendAllChildren(_ parent: UIView, _ workInProgress: Fiber) {
    // We only have the top Fiber that was created but we need recurse down its
    // children to find all the terminal nodes.
    var next = workInProgress.child
    while var node = next {
      if (node.tag == .HostComponent || node.tag == .HostText) {
        appendInitialChild(parent, node.stateNode as! UIView)
//      } else if (node.tag == .HostPortal) {
        // If we have a portal child, then we don't want to traverse
        // down its children. Instead, we'll get insertions from each child in
        // the portal directly.
      } else if let child = node.child {
        child.Return = node
        next = child
        continue
      }
      if (node === workInProgress) {
        return
      }
      while (node.sibling == nil) {
        guard let Return = node.Return else { return }
        if (Return === workInProgress) {
          return
        }
        node = Return
      }
      guard let sibling = node.sibling else { preconditionFailure() }
      sibling.Return = node.Return
      next = sibling
    }
  }

  static func markUpdate(_ workInProgress: Fiber) {
    // Tag the fiber with an update effect. This turns a Placement into
    // an UpdateAndPlacement.
    workInProgress.effectTag |= SideEffectUpdate
  }


  // MARK: Commit Work


  static func commitLifeCycles(_ current: Fiber?, _ finishedWork: Fiber) {
    switch (finishedWork.tag) {
    case .ClassComponent:
      var instance = finishedWork.stateNode
      if (finishedWork.effectTag & SideEffectUpdate != 0) {
        if let current = current {
          let prevProps = current.memoizedProps
          let prevState = current.memoizedState
          //          startPhaseTimer(finishedWork, 'componentDidUpdate')
          instance.props = finishedWork.memoizedProps
          instance.state = finishedWork.memoizedState
          instance.componentDidUpdate(prevProps, prevState)
          //          stopPhaseTimer()
        } else {
          //          startPhaseTimer(finishedWork, 'componentDidMount')
          instance.props = finishedWork.memoizedProps
          instance.state = finishedWork.memoizedState
          instance.componentDidMount()
          //          stopPhaseTimer()
        }
      }
      if let updateQueue = finishedWork.updateQueue {
        updateQueue.commitCallbacks()
      }
      return
    case .HostRoot:
      if let updateQueue = finishedWork.updateQueue {
        var instance: UIView? = nil
        if let child = finishedWork.child {
          switch (child.tag) {
          case .HostComponent:
            instance = getPublicInstance(child.stateNode)
            break
          case .ClassComponent:
            instance = child.stateNode as? UIView
            break
          default:
            // do nothing
            break
          }
        }
        updateQueue.commitCallbacks()
      }
      return
    case .HostComponent:
      guard let instance = finishedWork.stateNode as? UIView else {
        preconditionFailure("couldnt get instance from HostComponent")
      }

      // Renderers may schedule work to be done after host components are mounted
      // (eg DOM renderer may schedule auto-focus for inputs and form controls).
      // These effects should only be committed when components are first mounted,
      // aka when there is no current/alternate.
      if (current == nil && finishedWork.effectTag & SideEffectUpdate != 0) {
        let type = finishedWork.type
        let props = finishedWork.memoizedProps
        commitMount(instance, type, props, finishedWork)
      }

      return
    case .HostText:
      // We have no life-cycles associated with text.
      return
//    case .HostPortal:
//      // We have no life-cycles associated with portals.
//      return
//    default:
//      preconditionFailure("This unit of work tag should not have side-effects")
    }
  }

  static func commitResetTextContent(_ current: Fiber) {
    if let view = current.stateNode as? UIView {
      resetTextContent(view)
    }
  }

  static func commitWork(_ current: Fiber?, _ finishedWork: Fiber) {
    switch (finishedWork.tag) {
    case .ClassComponent:
      return
    case .HostComponent:
      if let instance = finishedWork.stateNode as? UIView {
        // Commit the work prepared earlier.
        let newProps = finishedWork.memoizedProps
        // For hydration we reuse the update path but we treat the oldProps
        // as the newProps. The updatePayload will contain the real change in
        // this case.
        let oldProps = current != nil ? current?.memoizedProps : newProps
        let type = finishedWork.type
        // TODO: Type the updateQueue to be specific to host components.
        let updatePayload = finishedWork.updateQueue
        finishedWork.updateQueue = nil
        if let updatePayload = updatePayload {
          commitUpdate(
            instance,
            updatePayload,
            type,
            oldProps,
            newProps,
            finishedWork
          )
        }
      }
      return
    case .HostText:
      precondition(
        finishedWork.stateNode != nil,
        "This should have a text node initialized"
      )
      let textInstance = finishedWork.stateNode as! TextHolderView
      let newText = finishedWork.memoizedProps as! String
      // For hydration we reuse the update path but we treat the oldProps
      // as the newProps. The updatePayload will contain the real change in
      // this case.
      let oldText = current != nil ? (current?.memoizedProps as! String) : newText
      commitTextUpdate(textInstance, oldText, newText)
      return
    case .HostRoot:
      return
    }
  }


//  static func commitAttachRef(_ finishedWork: Fiber) {
//    if let ref = finishedWork.ref as? Ref {
//      let instance = finishedWork.stateNode
//      switch (finishedWork.tag) {
//      case .HostComponent:
//        ref(getPublicInstance(instance))
//        break;
//      default:
//        // TODO(lmr): component refs should expect instances, not views...
//        ref(instance as? UIView)
//      }
//    }
//  }

//  static func commitDetachRef(_ current: Fiber) {
//    if let currentRef = current.ref as? Ref {
//      currentRef(nil)
//    }
//  }

  static func commitDeletion(_ current: Fiber) {
    // Detach refs and call componentWillUnmount() on the whole subtree.
    commitNestedUnmounts(current)
    detachFiber(current)
  }

  static func commitPlacement(_ finishedWork: Fiber) {
    // Recursively insert all host nodes into the parent.
    let parentFiber = getHostParentFiber(finishedWork)
    var parent: UIView!
    var isContainer = false
    switch (parentFiber.tag) {
    case .HostComponent:
      parent = parentFiber.stateNode as! UIView
      isContainer = false
      break
    case .HostRoot:
      parent = (parentFiber.stateNode as! OpaqueRoot).containerInfo
      isContainer = true
      break
//    case .HostPortal:
//      parent = parentFiber.stateNode.containerInfo
//      isContainer = true
//      break
    default:
      preconditionFailure("Invalid host parent fiber")
    }
    if (parentFiber.effectTag & SideEffectContentReset != 0) {
      // Reset the text content of the parent before doing any insertions
      resetTextContent(parent)
      // Clear ContentReset from the effect tag
      parentFiber.effectTag &= ~SideEffectContentReset
    }

    let before = getHostSibling(finishedWork)
    // We only have the top Fiber that was inserted but we need recurse down its
    // children to find all the terminal nodes.
    var node: Fiber = finishedWork
    while (true) {
      if (node.tag == .HostComponent || node.tag == .HostText) {
        if let before = before {
          if (isContainer) {
            insertInContainerBefore(parent, node.stateNode as! UIView, before)
          } else {
            insertBefore(parent, node.stateNode as! UIView, before)
          }
        } else {
          if (isContainer) {
            appendChildToContainer(parent, node.stateNode as! UIView)
          } else {
            appendChild(parent, node.stateNode as! UIView)
          }
        }
//      } else if (node.tag == .HostPortal) {
        // If the insertion itself is a portal, then we don't want to traverse
        // down its children. Instead, we'll get insertions from each child in
        // the portal directly.
      } else if let child = node.child {
        child.Return = node
        node = child
        continue
      }
      if (node === finishedWork) {
        return
      }
      while (node.sibling == nil) {
        guard let Return = node.Return else { return }
        if (Return === finishedWork) {
          return
        }
        node = Return
      }
      guard let sibling = node.sibling else {
        preconditionFailure()
      }
      sibling.Return = node.Return
      node = sibling
    }
  }

  static func isHostParent(_ fiber: Fiber) -> Bool {
    return (
      fiber.tag == .HostComponent ||
      fiber.tag == .HostRoot /* ||
      fiber.tag == .HostPortal */
    )
  }

  static func getHostSibling(_ fiber: Fiber) -> UIView? {
    // We're going to search forward into the tree until we find a sibling host
    // node. Unfortunately, if multiple insertions are done in a row we have to
    // search past them. This leads to exponential search for the next sibling.
    // TODO: Find a more efficient way to do this.
    var node = fiber
    siblings: while (true) {
      // If we didn't find anything, let's try the next sibling.
      while (node.sibling == nil) {
        guard let Return = node.Return else { return nil }
        if isHostParent(Return) {
          // If we pop out of the root or hit the parent the fiber we are the
          // last sibling.
          return nil
        }
        node = Return
      }
      guard let sibling = node.sibling else { preconditionFailure() }
      sibling.Return = node.Return
      node = sibling
      while (node.tag != .HostComponent && node.tag != .HostText) {
        // If it is not host node and, we might have a host node inside it.
        // Try to search down until we find one.
        if (node.effectTag & SideEffectPlacement != 0) {
          // If we don't have a child, try the siblings instead.
          continue siblings
        }
        // If we don't have a child, try the siblings instead.
        // We also skip portals because they are not part of this host tree.
        if (node.child == nil /* || node.tag == .HostPortal */) {
          continue siblings
        } else {
          node.child!.Return = node
          node = node.child!
        }
      }
      // Check if this host node is stable or about to be placed.
      if (node.effectTag & SideEffectPlacement == 0) {
        // Found it!
        return node.stateNode as? UIView
      }
    }
  }

  static func getHostParentFiber(_ fiber: Fiber) -> Fiber {
    var nextParent: Fiber? = fiber.Return;
    while let parent = nextParent {
      if (isHostParent(parent)) {
        return parent
      }
      nextParent = parent.Return
    }
    preconditionFailure("Expected to find a host parent.")
  }

  static func commitNestedUnmounts(_ root: Fiber) {
    // While we're inside a removed host node we don't want to call
    // removeChild on the inner nodes because they're removed by the top
    // call anyway. We also want to call componentWillUnmount on all
    // composites before this host node is removed from the tree. Therefore
    // we do an inner loop while we're still inside the host node.
    var node: Fiber = root
    while (true) {
      commitUnmount(node)
      // Visit children because they may contain more composite or host nodes.
      // Skip portals because commitUnmount() currently visits them recursively.
      if let child = node.child {
        child.Return = node
        node = child
        continue
      }
      if (node === root) {
        return
      }
      while (node.sibling == nil) {
        guard let Return = node.Return else {
          return
        }
        if (Return === root) {
          return
        }
        node = Return
      }
      guard let sibling = node.sibling else {
        preconditionFailure()
      }
      sibling.Return = node.Return
      node = sibling
    }
  }

  static func detachFiber(_ current: Fiber) {
    // Cut off the return pointers to disconnect it from the tree. Ideally, we
    // should clear the child pointer of the parent alternate to let this
    // get GC:ed but we don't know which for sure which parent is the current
    // one so we'll settle for GC:ing the subtree of this child. This child
    // itself will be GC:ed when the parent updates the next time.
    current.Return = nil
    current.child = nil
    if let alternate = current.alternate {
      alternate.child = nil
      alternate.Return = nil
    }
  }

  static func commitUnmount(_ current: Fiber) {
    if (typeof onCommitUnmount === 'function') {
      onCommitUnmount(current);
    }

    switch (current.tag) {
    case .ClassComponent:
//      safelyDetachRef(current)
      let instance = current.stateNode;
      safelyCallComponentWillUnmount(current, instance)
      return
    case .HostComponent:
      safelyDetachRef(current)
      return
//    case .CallComponent:
//      commitNestedUnmounts(current.stateNode)
//      return
//    case .HostPortal:
//      // TODO: this is recursive.
//      // We are also not using this parent because
//      // the portal will get pushed immediately.
//      unmountHostComponents(current)
//      return
    case .HostRoot:
      return
    case .HostText:
      return
    }
  }


  // MARK: HostConfig methods

  private static let componentInstanceMap = NSMapTable<UIView, Fiber>(keyOptions: NSMapTableWeakMemory, valueOptions: NSMapTableWeakMemory)

  static func createInstance(
    _ type: Any?,
    _ props: Any?,
//    rootContainerInstance: DOMContainer,
//    hostContext,
    _ internalInstanceHandle: Fiber
  ) -> UIView {
    let instance = createElement(type, props)
    componentInstanceMap.setObject(internalInstanceHandle, forKey: instance)
    return instance
  }

  static func createTextInstance(
    _ text: String,
//    rootContainerInstance: DOMContainer,
//    hostContext,
    _ internalInstanceHandle: Fiber
  ) -> TextHolderView {
    let inst = createTextNode(text)
    componentInstanceMap.setObject(internalInstanceHandle, forKey: inst)
    return inst
  }

  static func finalizeInitialChildren(
    _ domElement: UIView,
    _ type: Any?,
    _ props: Props
  ) -> Bool {
    DOMComponent.setInitialProps(domElement, props)
    return false
  }

  static func prepareUpdate(
    _ instance: UIView,
    _ type: Any?,
    _ oldProps: Any?,
    _ newProps: Any?
//    _ rootContainerInstance: UIView,
//    _ hostContext: Any?
  ) -> Any? {
    return nil
  }

  static func prepareForCommit(_ containerInfo: Any?) {
    // noop, for now...
  }

  static func resetAfterCommit(_ containerInfo: Any?) {
    // noop...
  }

  static func getPublicInstance(_ instance: Any?) -> UIView? {
    // TODO(lmr):
    return instance as? UIView
  }

  // MARK: HostConfig.mutation methods

  static func commitUpdate(
    _ instance: UIView,
    _ preparedUpdateQueue: UpdateQueue, // TODO: not sure if we need/want this?
    _ type: Any?,
    _ oldProps: Any?,
    _ newProps: Any?,
    _ fiber: Fiber
  ) {
//    DOMComponent.updateProps(instance, preparedUpdateQueue, oldProps)
  }

  static func commitMount(
    _ instance: UIView,
    _ type: Any?,
    _ newProps: Any?,
    _ internalInstanceHandle: Fiber
  ) {
    // noop
  }

  static func commitTextUpdate(
    _ textInstance: TextHolderView,
    _ oldText: String,
    _ newText: String
  ) {
    textInstance.text = newText
  }

  static func resetTextContent(
    _ view: UIView
  ) {
    // TODO(lmr): not really sure if we need this...
    if let textView = view as? TextHolderView {
      textView.text = ""
    }
  }

  static func appendInitialChild(
    _ parentInstance: UIView,
    _ child: UIView
  ) {
    parentInstance.addSubview(child)
  }

  static func appendChild(
    _ parentInstance: UIView,
    _ child: UIView
  ) {
    parentInstance.addSubview(child)
  }

  static func appendChildToContainer(
    _ parentInstance: UIView,
    _ child: UIView
  ) {
    parentInstance.addSubview(child)
  }

  static func insertBefore(
    _ parentInstance: UIView,
    _ child: UIView,
    _ beforeChild: UIView
  ) {
    parentInstance.insertSubview(child, belowSubview: beforeChild)
  }

  static func insertInContainerBefore(
    _ container: UIView,
    _ child: UIView,
    _ beforeChild: UIView
  ) {
    container.insertSubview(child, belowSubview: beforeChild)
  }

  static func removeChild(
    _ parentInstance: UIView,
    _ child: UIView
  ) {
    precondition(parentInstance === child.superview)
    child.removeFromSuperview()
  }

  static func removeChildFromContainer(
    _ parentInstance: UIView,
    _ child: UIView
  ) {
    precondition(parentInstance === child.superview)
    child.removeFromSuperview()
  }

  // MARK: Class Component

  static func constructClassInstance(_ workInProgress: Fiber, _ props: Any?) {

  }

  static func mountClassInstance(
    _ workInProgress: Fiber,
    _ renderExpirationTime: ExpirationTime
  ) {

  }

  static func updateClassInstance(
    _ current: Fiber,
    _ workInProgress: Fiber,
    _ renderExpirationTime: ExpirationTime
  ) -> Bool {
    // TODO(lmr):
  }

}
