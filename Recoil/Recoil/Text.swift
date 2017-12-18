//
//  Text.swift
//  Recoil
//
//  Created by Leland Richardson on 12/13/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation
import UIKit
import YogaKit

public class TextProps: ChildrenProps {
  var style: Style?
  var numberOfLines: Int = 0
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

final public class Text: HostComponent<TextProps, TextHostView> {
  override public func mountComponent() -> TextHostView {
    let view = TextHostView()
    let layout = view.yoga
    layout.isEnabled = true
    applyProps(view: view, props: props)
    return view
  }

  override public func updateComponent(view: TextHostView, prevProps: TextProps) {
    applyProps(view: view, props: props)
  }

  private func applyProps(view: TextHostView, props: TextProps) {
    if let style = props.style {
      style.applyTo(label: view)
    }
    view.numberOfLines = props.numberOfLines
  }

  override public func renderChildren() -> Element? {
    return props.children
  }

  override public func childrenDidUpdate(view: TextHostView, prevProps: TextProps) {
    view.updateTextIfNeeded()
  }

  override public func childrenDidMount(view: TextHostView) {
    view.updateTextIfNeeded()
  }
}

