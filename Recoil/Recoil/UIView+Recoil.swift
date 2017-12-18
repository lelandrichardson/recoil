//
//  UIView+Recoil.swift
//  Recoil
//
//  Created by Leland Richardson on 12/13/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation

var kRecoilRoot = "recoilRoot"

extension UIView {
  var recoilRoot: RecoilRoot? {
    get {
      return objc_getAssociatedObject( self, &kRecoilRoot ) as? RecoilRoot
    }
    set {
      objc_setAssociatedObject( self, &kRecoilRoot, newValue, .OBJC_ASSOCIATION_RETAIN)
    }
  }

  func isRecoilRoot() -> Bool {
    return recoilRoot != nil
  }

  func getRecoilRootFromAncestors() -> RecoilRoot? {
    var node: UIView? = self
    while (node != nil && node?.recoilRoot == nil) {
      node = node?.superview
    }
    return node?.recoilRoot
  }

  func removeAllSubviews() {
    for view in subviews {
      view.removeFromSuperview()
    }
  }

  // NOTE: @objc is needed to allow for overriding
  @objc
  func insertRecoilSubview(_ view: UIView, at index: Int) {
    self.insertSubview(view, at: index)
  }

  @objc
  func moveRecoilSubview(from fromIndex: Int, to toIndex: Int) {
    let view = self.subviews[fromIndex]
    self.insertSubview(view, at: toIndex)
  }

  @objc
  func removeRecoilSubview(from fromIndex: Int) {
    let view = self.subviews[fromIndex]
    view.removeFromSuperview()
  }
}
