//
//  Element.swift
//  Recoil
//
//  Created by Leland Richardson on 12/12/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation


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
}

public struct HostElement {
  let type: HostComponentProtocol.Type
  let props: Any
}
