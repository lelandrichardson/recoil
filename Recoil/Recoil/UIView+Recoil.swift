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
}
