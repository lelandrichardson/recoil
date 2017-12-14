//
//  createElement.swift
//  Recoil
//
//  Created by Leland Richardson on 12/12/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation


public func h<P>(_ type: Component<P>.Type, _ props: P) -> Element {
  return .component(ComponentElement(type: type, props: props))
}

public func h<P, V>(_ type: HostComponent<P, V>.Type, _ props: P) -> Element {
  return .host(HostElement(type: type, props: props))
}

public func h(_ string: String) -> Element {
  return .string(string)
}

public func h(_ element: Element) -> Element {
  return element
}

public func h(_ array: [Element]) -> Element {
  return .array(array)
}

//public func h(_ array: Element...) -> Element {
//  return .array(array)
//}

