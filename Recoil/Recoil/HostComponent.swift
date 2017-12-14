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
  func generalMountComponent() -> UIView
  func updateComponent(view: UIView, prevProps: Any)
  func renderChildren() -> Element?
}

open class HostComponent<Props, View: UIView>: HostComponentProtocol {
  let props: Props
  
  required public init(props: Any) {
    if let props = props as? Props {
      self.props = props
    } else {
      fatalError()
    }
  }

  func generalMountComponent() -> UIView {
    return self.mountComponent()
  }

  func mountComponent() -> View {
    fatalError("mountComponent needs to be overridden")
  }

  func updateComponent(view: UIView, prevProps: Any) {
    if let prevProps = prevProps as? Props, let view = view as? View {
      self.updateComponent(view: view, prevProps: prevProps)
    }
  }
  open func updateComponent(view: View, prevProps: Props) {
    fatalError("updateComponent needs to be overridden")
  }
  
  open func renderChildren() -> Element? {
    return nil
  }
}
