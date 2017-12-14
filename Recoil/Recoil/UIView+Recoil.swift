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
  var recoilRoot: RecoilInstance? {
    get {
      return objc_getAssociatedObject( self, &kRecoilRoot ) as? RecoilInstance
    }
    set {
      objc_setAssociatedObject( self, &kRecoilRoot, newValue, .OBJC_ASSOCIATION_RETAIN)
    }
  }

  func removeAllSubviews() {
    for view in subviews {
      view.removeFromSuperview()
    }
  }
}
