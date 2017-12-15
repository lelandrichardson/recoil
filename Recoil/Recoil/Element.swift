//
//  Element.swift
//  Recoil
//
//  Created by Leland Richardson on 12/12/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation

public typealias Key = AnyHashable

public enum Element {
  case host(HostElement)
  case component(ComponentElement)
  case array(Array<Element?>)
  case string(String)
  case double(Double)
  case int(Int)
}

public struct ComponentElement {
  let type: ComponentProtocol.Type
  let props: Any
  let key: Key?
}

public struct HostElement {
  let type: HostComponentProtocol.Type
  let props: Any
  let key: Key?
}

public func ==(lhs: Element, rhs: Element) -> Bool {
  switch (lhs, rhs) {
  case let (.host(a), .host(b)):
    return a == b
  case let (.component(a), .component(b)):
    return a == b
  case let (.string(a), .string(b)):
    return a == b
  case let (.double(a), .double(b)):
    return a == b
  case let (.int(a), .int(b)):
    return a == b
  case (.array(_), .array(_)):
    return false
  default:
    return false
  }
}

public func ==(lhs: ComponentElement, rhs: ComponentElement) -> Bool {
  // TODO: How should we implement this? :(
  return false
}

public func ==(lhs: HostElement, rhs: HostElement) -> Bool {
  // TODO: How should we implement this? :(
  return false
}

public func !=(lhs: HostElement, rhs: HostElement) -> Bool {
  return !(lhs == rhs)
}

public func !=(lhs: ComponentElement, rhs: ComponentElement) -> Bool {
  return !(lhs == rhs)
}

public func !=(lhs: Element, rhs: Element) -> Bool {
  return !(lhs == rhs)
}
