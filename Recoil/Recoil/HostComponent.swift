//
//  HostComponent.swift
//  Recoil
//
//  Created by Leland Richardson on 12/12/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation

protocol HostComponentProtocol {
  init(props: Any)
  func mountComponent(into container: UIView) -> UIView
  func updateComponent(view: UIView, prevProps: Any)
  func renderChildren() -> Element?
}

open class HostComponent<Props>: HostComponentProtocol {

  let props: Props
  
  required public init(props: Any) {
    if let props = props as? Props {
      self.props = props
    } else {
      fatalError()
    }
  }

  open func mountComponent(into container: UIView) -> UIView {
    fatalError("mountComponent needs to be overridden")
  }

  func updateComponent(view: UIView, prevProps: Any) {
    if let prevProps = prevProps as? Props {
      self.updateComponent(view: view, prevProps: prevProps)
    }
  }
  open func updateComponent(view: UIView, prevProps: Props) {
    fatalError("updateComponent needs to be overridden")
  }
  
  open func renderChildren() -> Element? {
    return nil
  }
}
