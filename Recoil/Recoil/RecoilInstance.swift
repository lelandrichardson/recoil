//
//  RecoilInstance.swift
//  Recoil
//
//  Created by Leland Richardson on 12/13/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation

protocol RecoilInstance: class {
  var currentElement: Element { get }
  var root: RecoilRoot? { get }
  var view: UIView? { get }
  var mountIndex: Int { get set }
  func mountComponent() -> UIView?
  func receiveComponent(element: Element)
  func updateComponent(from prevElement: Element, to nextElement: Element)
  func performUpdateIfNecessary()
  func unmountComponent()
//  func enqueueLayout()
}

extension RecoilInstance {
//  func enqueueLayout() {
//    if let root = self.view?.getRecoilRootFromAncestors() {
//      root.isDirty = true
//    }
//  }
}
