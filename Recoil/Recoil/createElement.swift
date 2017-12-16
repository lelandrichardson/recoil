//
//  createElement.swift
//  Recoil
//
//  Created by Leland Richardson on 12/12/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation

public func h<P, S>(_ type: Component<P, S>.Type, _ props: P) -> Element {
  return .component(ComponentElement(type: type, props: props, key: nil))
}

public func h<P, S>(_ type: Component<P, S>.Type, key: Key, _ props: P) -> Element {
  return .component(ComponentElement(type: type, props: props, key: key))
}

public func h<P>(_ type: StatelessComponent<P>.Type, _ props: P) -> Element {
  return .component(ComponentElement(type: type, props: props, key: nil))
}

public func h<P>(_ type: StatelessComponent<P>.Type, key: Key, _ props: P) -> Element {
  return .component(ComponentElement(type: type, props: props, key: key))
}

public func h<P, V>(_ type: HostComponent<P, V>.Type, _ props: P) -> Element {
  return .host(HostElement(type: type, props: props, key: nil))
}

public func h<P, V>(_ type: HostComponent<P, V>.Type, key: Key, _ props: P) -> Element {
  return .host(HostElement(type: type, props: props, key: key))
}

//public typealias SFC<P> = (P) -> Element?
//
//public func h<P>(_ type: SFC<P>, _ props: P) -> Element {
//  return .string("")
//}

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

