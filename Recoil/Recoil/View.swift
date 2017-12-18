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

public class ViewProps: ChildrenProps {
  var style: Style?
  var children: Element?
  var onPress: (() -> ())?


  /*
   accessibilityLabel
   hitSlop
   onAccessibilityTap
   onLayout
   onMagicTap
   accessible
   pointerEvents
   style
   testID
   accessibilityComponentType
   accessibilityLiveRegion
   importantForAccessibility
   accessibilityTraits
   accessibilityViewIsModal
 */

  public init() {}
  public func style(_ value: Style?) -> Self {
    style = value
    return self
  }
  public func children(_ value: Element?) -> Self {
    children = value
    return self
  }
  public func onPress(_ value: (() -> ())?) -> Self {
    onPress = value
    return self
  }
}

final public class View: HostComponent<ViewProps, ViewHostView> {
  override public func mountComponent() -> ViewHostView {
    let view = ViewHostView()
    let layout = view.yoga
    layout.isEnabled = true
    applyProps(view: view, props: props)
    return view
  }

  override public func updateComponent(view: ViewHostView, prevProps: ViewProps) {
    applyProps(view: view, props: props)
  }

  private func applyProps(view: ViewHostView, props: ViewProps) {
    if let style = props.style {
      style.applyTo(view: view)

      if let borderRadius = style.borderRadius, borderRadius != view.borderRadius { view.borderRadius = borderRadius }
      if let borderTopLeftRadius = style.borderTopLeftRadius, borderTopLeftRadius != view.borderTopLeftRadius { view.borderTopLeftRadius = borderTopLeftRadius }
      if let borderTopRightRadius = style.borderTopRightRadius, borderTopRightRadius != view.borderTopRightRadius { view.borderTopRightRadius = borderTopRightRadius }
      if let borderBottomLeftRadius = style.borderBottomLeftRadius, borderBottomLeftRadius != view.borderBottomLeftRadius { view.borderBottomLeftRadius = borderBottomLeftRadius }
      if let borderBottomRightRadius = style.borderBottomRightRadius, borderBottomRightRadius != view.borderBottomRightRadius { view.borderBottomRightRadius = borderBottomRightRadius }
      if let borderColor = style.borderColor?.toUIColor(), borderColor != view.borderColor { view.borderColor = borderColor }
      if let borderTopColor = style.borderTopColor?.toUIColor(), borderTopColor != view.borderTopColor { view.borderTopColor = borderTopColor }
      if let borderLeftColor = style.borderLeftColor?.toUIColor(), borderLeftColor != view.borderLeftColor { view.borderLeftColor = borderLeftColor }
      if let borderBottomColor = style.borderBottomColor?.toUIColor(), borderBottomColor != view.borderBottomColor { view.borderBottomColor = borderBottomColor }
      if let borderRightColor = style.borderRightColor?.toUIColor(), borderRightColor != view.borderRightColor { view.borderRightColor = borderRightColor }
      if let borderLeftWidth = style.borderLeftWidth, borderLeftWidth != view.borderLeftWidth { view.borderLeftWidth = borderLeftWidth }
      if let borderTopWidth = style.borderTopWidth, borderTopWidth != view.borderTopWidth { view.borderTopWidth = borderTopWidth }
      if let borderRightWidth = style.borderRightWidth, borderRightWidth != view.borderRightWidth { view.borderRightWidth = borderRightWidth }
      if let borderBottomWidth = style.borderBottomWidth, borderBottomWidth != view.borderBottomWidth { view.borderBottomWidth = borderBottomWidth }
      if let borderWidth = style.borderWidth, borderWidth != view.borderWidth { view.borderWidth = borderWidth }
      if view.borderStyle != style.borderStyle { view.borderStyle = style.borderStyle }
    }
    if let onPress = props.onPress {
      view.onPress = onPress
    }
  }

  override public func renderChildren() -> Element? {
    return props.children
  }

}
