//
//  YGValue+Recoil.swift
//  Recoil
//
//  Created by Leland Richardson on 12/15/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation
import YogaKit


public func ==(lhs: YGValue, rhs: YGValue) -> Bool {
  return lhs.value == rhs.value && lhs.unit == rhs.unit
}

public func !=(lhs: YGValue, rhs: YGValue) -> Bool {
  return lhs.value != rhs.value || lhs.unit != rhs.unit
}
