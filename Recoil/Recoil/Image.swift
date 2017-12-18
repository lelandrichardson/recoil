//
//  Image.swift
//  Recoil
//
//  Created by Leland Richardson on 12/15/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation
import UIKit
import YogaKit

public struct ImageSource {
  let url: String
}

public class ImageProps: ChildrenProps {
  var style: Style?
  var source: ImageSource?
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
  public func source(_ value: ImageSource?) -> Self {
    source = value
    return self
  }
  public func source(_ url: String?) -> Self {
    if let url = url {
      source = ImageSource(url: url)
    } else {
      source = nil
    }
    return self
  }
}

final public class Image: HostComponent<ImageProps, ImageHostView> {
  override public func mountComponent() -> ImageHostView {
    let view = ImageHostView()
    let layout = view.yoga
    layout.isEnabled = true
    applyProps(view: view, props: props)
    return view
  }

  override public func updateComponent(view: ImageHostView, prevProps: ImageProps) {
    applyProps(view: view, props: props)
  }

  private func applyProps(view: ImageHostView, props: ImageProps) {
    if let style = props.style {
      style.applyTo(view: view)
    }
    view.source = props.source
  }

  override public func renderChildren() -> Element? {
    return props.children
  }
}
