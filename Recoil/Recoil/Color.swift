//
//  Color.swift
//  Recoil
//
//  Created by Leland Richardson on 12/18/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation

public enum Color {
  // TODO: hsl, rgba, hex
  case rgb(CGFloat, CGFloat, CGFloat)
  case raw(String)
  case uiColor(UIColor)
  case black
  case white
  case clear

  func toUIColor() -> UIColor {
    switch self {
    case .rgb(let r, let g, let b):
      return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    case .uiColor(let color):
      return color
    case .raw:
      // TODO
      fatalError("Color.raw(String) is not implemented yet")
    case .black:
      return .black
    case .white:
      return .white
    case .clear:
      return .clear
    }
  }
}

public func ==(lhs: Color, rhs: Color) -> Bool {
  switch (lhs, rhs) {
  case let (.rgb(r1, g1, b1), .rgb(r2, g2, b2)):
    return r1 == r2 && g1 == g2 && b1 == b2
  case let (.raw(a), .raw(b)):
    return a == b
  case let (.uiColor(a), .uiColor(b)):
    return a == b
  case (.black, .black): return true
  case (.white, .white): return true
  case (.clear, .clear): return true
  default: return false
  }
}

public func !=(lhs: Color, rhs: Color) -> Bool {
  return !(lhs == rhs)
}
