//
//  View.swift
//  Recoil
//
//  Created by Leland Richardson on 12/12/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation
import UIKit
import YogaKit

public class ViewProps {
  var style: Style?
  var children: Element?
  public init() {}
  public func style(_ value: Style?) -> Self {
    style = value
    return self
  }
  public func children(_ value: Element?) -> Self {
    children = value
    return self
  }
}

final public class View: HostComponent<ViewProps> {
  override public func mountComponent(into container: UIView) -> UIView {
    let view = UIView()
    let layout = view.yoga
    layout.isEnabled = true
    if let style = props.style {
      style.applyTo(view: view)
    }
    container.addSubview(view)
    return view
  }

  override public func updateComponent(view: UIView, prevProps: ViewProps) {

  }

  override public func renderChildren() -> Element? {
    return props.children
  }
}
