//
//  RecoilRoot.swift
//  Recoil
//
//  Created by Leland Richardson on 12/15/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation

class RecoilRoot {
  var rootView: UIView?
  var rootInstance: RecoilInstance?
  var displayLink: CADisplayLink?

  private var isDirty = false

  init(rootView: UIView) {
    self.rootView = rootView
    let displayLink = CADisplayLink(target: self, selector: #selector(frame(displaylink:)))
    self.displayLink = displayLink

    displayLink.add(to: .current, forMode: .defaultRunLoopMode)
  }

  @objc
  func frame(displaylink: CADisplayLink) {
    guard isDirty else { return }
    guard let rootView = rootView else { return }
    rootView.yoga.applyLayout(preservingOrigin: true)
  }

  func enqueueLayout() {
    isDirty = true
  }

  deinit {
    self.displayLink?.invalidate()
  }
}
