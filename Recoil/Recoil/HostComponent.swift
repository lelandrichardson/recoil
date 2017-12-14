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
  func setPropsInternal(props: Any)
  func mountComponentInternal() -> UIView
  func updateComponentInternal(view: UIView, prevProps: Any)
  func renderChildren() -> Element?
}

open class HostComponent<Props, View: UIView>: HostComponentProtocol {
  var props: Props
  
  required public init(props: Any) {
    if let props = props as? Props {
      self.props = props
    } else {
      fatalError()
    }
  }

  func setPropsInternal(props: Any) {
    if let props = props as? Props {
      self.props = props
    }
  }

  func mountComponentInternal() -> UIView {
    return self.mountComponent()
  }

  func mountComponent() -> View {
    fatalError("mountComponent needs to be overridden")
  }

  func updateComponentInternal(view: UIView, prevProps: Any) {
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
