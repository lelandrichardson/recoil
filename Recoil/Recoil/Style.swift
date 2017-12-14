//
//  StyleSheet.swift
//  Recoil
//
//  Created by Leland Richardson on 12/12/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation
import YogaKit

public enum Color {
  case rgb(CGFloat, CGFloat, CGFloat)
  case raw(String)
  case uiColor(UIColor)
  case black
  case white
  case clear

  func toUIColor() -> UIColor {
    switch self {
    case .rgb(let r, let g, let b):
      return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    case .uiColor(let color):
      return color
    case .raw:
      // TODO
      fatalError("Color.raw(String) is not implemented yet")
    case .black:
      return UIColor.black
    case .white:
      return UIColor.white
    case .clear:
      return UIColor.clear
    }
  }
}

final public class Style {

  // Text-specific properties
  var color: Color?
  var fontSize: CGFloat = 17
  var fontWeight: String?
  var lineHeight: CGFloat?
  var fontFamily: String?
  var letterSpacing: CGFloat?
  var textDecorationStyle: String? // enum
  var textAlign: String? // enum
  var textDecorationLine: String? // enum

  // Non-Yoga properties
  var backgroundColor: Color?
  var opacity: CGFloat?

  // Yoga Properties
  var direction: YGDirection?
  var flexDirection: YGFlexDirection?
  var justifyContent: YGJustify?
  var alignContent: YGAlign?
  var alignItems: YGAlign?
  var alignSelf: YGAlign?
  var position: YGPositionType?
  var flexWrap: YGWrap?
  var overflow: YGOverflow?
  var display: YGDisplay?

  var flexGrow: CGFloat?
  var flexShrink: CGFloat?
  var flexBasis: YGValue?

  var left: YGValue?
  var top: YGValue?
  var right: YGValue?
  var bottom: YGValue?
  var start: YGValue?
  var end: YGValue?

  var marginLeft: YGValue?
  var marginTop: YGValue?
  var marginRight: YGValue?
  var marginBottom: YGValue?
  var marginStart: YGValue?
  var marginEnd: YGValue?
  var marginHorizontal: YGValue?
  var marginVertical: YGValue?
  var margin: YGValue?

  var paddingLeft: YGValue?
  var paddingTop: YGValue?
  var paddingRight: YGValue?
  var paddingBottom: YGValue?
  var paddingStart: YGValue?
  var paddingEnd: YGValue?
  var paddingHorizontal: YGValue?
  var paddingVertical: YGValue?
  var padding: YGValue?

  var borderLeftWidth: CGFloat?
  var borderTopWidth: CGFloat?
  var borderRightWidth: CGFloat?
  var borderBottomWidth: CGFloat?
  var borderStartWidth: CGFloat?
  var borderEndWidth: CGFloat?
  var borderWidth: CGFloat?

  var width: YGValue?
  var height: YGValue?
  var minWidth: YGValue?
  var minHeight: YGValue?
  var maxWidth: YGValue?
  var maxHeight: YGValue?

  // Yoga specific properties, not compatible with flexbox specification
  var aspectRatio: CGFloat?

  public init() {

  }

  func applyTo(label: UILabel) {
    applyTo(view: label)
    if let color = color {
      label.textColor = color.toUIColor()
    }
    var attributes: [UIFontDescriptor.AttributeName: Any] = [:]
    if let fontFamily = fontFamily {
      attributes[.family] = fontFamily
    }
//    attributes[.textStyle] = ""
    let descriptor = UIFontDescriptor(fontAttributes: attributes)
    let font = UIFont(descriptor: descriptor, size: fontSize)
    label.font = font
//    label.textAlignment
//    label.shadowColor
//    label.shadowOffset
  }

  func applyTo(view: UIView) {
    applyTo(layout: view.yoga)
    if let backgroundColor = backgroundColor {
      view.backgroundColor = backgroundColor.toUIColor()
    }
    if let opacity = opacity {
      view.alpha = opacity
    }
  }

  func applyTo(layout: YGLayout) {
    if let direction = direction { layout.direction = direction }
    if let flexDirection = flexDirection { layout.flexDirection = flexDirection }
    if let justifyContent = justifyContent { layout.justifyContent = justifyContent }
    if let alignContent = alignContent { layout.alignContent = alignContent }
    if let alignItems = alignItems { layout.alignItems = alignItems }
    if let alignSelf = alignSelf { layout.alignSelf = alignSelf }
    if let position = position { layout.position = position }
    if let flexWrap = flexWrap { layout.flexWrap = flexWrap }
    if let overflow = overflow { layout.overflow = overflow }
    if let display = display { layout.display = display }
    if let flexGrow = flexGrow { layout.flexGrow = flexGrow }
    if let flexShrink = flexShrink { layout.flexShrink = flexShrink }
    if let flexBasis = flexBasis { layout.flexBasis = flexBasis }
    if let left = left { layout.left = left }
    if let top = top { layout.top = top }
    if let right = right { layout.right = right }
    if let bottom = bottom { layout.bottom = bottom }
    if let start = start { layout.start = start }
    if let end = end { layout.end = end }
    if let marginLeft = marginLeft { layout.marginLeft = marginLeft }
    if let marginTop = marginTop { layout.marginTop = marginTop }
    if let marginRight = marginRight { layout.marginRight = marginRight }
    if let marginBottom = marginBottom { layout.marginBottom = marginBottom }
    if let marginStart = marginStart { layout.marginStart = marginStart }
    if let marginEnd = marginEnd { layout.marginEnd = marginEnd }
    if let marginHorizontal = marginHorizontal { layout.marginHorizontal = marginHorizontal }
    if let marginVertical = marginVertical { layout.marginVertical = marginVertical }
    if let margin = margin { layout.margin = margin }
    if let paddingLeft = paddingLeft { layout.paddingLeft = paddingLeft }
    if let paddingTop = paddingTop { layout.paddingTop = paddingTop }
    if let paddingRight = paddingRight { layout.paddingRight = paddingRight }
    if let paddingBottom = paddingBottom { layout.paddingBottom = paddingBottom }
    if let paddingStart = paddingStart { layout.paddingStart = paddingStart }
    if let paddingEnd = paddingEnd { layout.paddingEnd = paddingEnd }
    if let paddingHorizontal = paddingHorizontal { layout.paddingHorizontal = paddingHorizontal }
    if let paddingVertical = paddingVertical { layout.paddingVertical = paddingVertical }
    if let padding = padding { layout.padding = padding }
    if let borderLeftWidth = borderLeftWidth { layout.borderLeftWidth = borderLeftWidth }
    if let borderTopWidth = borderTopWidth { layout.borderTopWidth = borderTopWidth }
    if let borderRightWidth = borderRightWidth { layout.borderRightWidth = borderRightWidth }
    if let borderBottomWidth = borderBottomWidth { layout.borderBottomWidth = borderBottomWidth }
    if let borderStartWidth = borderStartWidth { layout.borderStartWidth = borderStartWidth }
    if let borderEndWidth = borderEndWidth { layout.borderEndWidth = borderEndWidth }
    if let borderWidth = borderWidth { layout.borderWidth = borderWidth }
    if let width = width { layout.width = width }
    if let height = height { layout.height = height }
    if let minWidth = minWidth { layout.minWidth = minWidth }
    if let minHeight = minHeight { layout.minHeight = minHeight }
    if let maxWidth = maxWidth { layout.maxWidth = maxWidth }
    if let maxHeight = maxHeight { layout.maxHeight = maxHeight }
  }

  public static func + (left: Style, right: Style) -> Style {
    return merge(merge(Style(), left), right)
  }

  static func merge(_ result: Style, _ toMerge: Style) -> Style {

    // Non-Yoga props
    if let backgroundColor = toMerge.backgroundColor { result.backgroundColor = backgroundColor }
    if let color = toMerge.color { result.color = color }

    // Yoga props
    if let direction = toMerge.direction { result.direction = direction }
    if let flexDirection = toMerge.flexDirection { result.flexDirection = flexDirection }
    if let justifyContent = toMerge.justifyContent { result.justifyContent = justifyContent }
    if let alignContent = toMerge.alignContent { result.alignContent = alignContent }
    if let alignItems = toMerge.alignItems { result.alignItems = alignItems }
    if let alignSelf = toMerge.alignSelf { result.alignSelf = alignSelf }
    if let position = toMerge.position { result.position = position }
    if let flexWrap = toMerge.flexWrap { result.flexWrap = flexWrap }
    if let overflow = toMerge.overflow { result.overflow = overflow }
    if let display = toMerge.display { result.display = display }
    if let flexGrow = toMerge.flexGrow { result.flexGrow = flexGrow }
    if let flexShrink = toMerge.flexShrink { result.flexShrink = flexShrink }
    if let flexBasis = toMerge.flexBasis { result.flexBasis = flexBasis }
    if let left = toMerge.left { result.left = left }
    if let top = toMerge.top { result.top = top }
    if let right = toMerge.right { result.right = right }
    if let bottom = toMerge.bottom { result.bottom = bottom }
    if let start = toMerge.start { result.start = start }
    if let end = toMerge.end { result.end = end }
    if let marginLeft = toMerge.marginLeft { result.marginLeft = marginLeft }
    if let marginTop = toMerge.marginTop { result.marginTop = marginTop }
    if let marginRight = toMerge.marginRight { result.marginRight = marginRight }
    if let marginBottom = toMerge.marginBottom { result.marginBottom = marginBottom }
    if let marginStart = toMerge.marginStart { result.marginStart = marginStart }
    if let marginEnd = toMerge.marginEnd { result.marginEnd = marginEnd }
    if let marginHorizontal = toMerge.marginHorizontal { result.marginHorizontal = marginHorizontal }
    if let marginVertical = toMerge.marginVertical { result.marginVertical = marginVertical }
    if let margin = toMerge.margin { result.margin = margin }
    if let paddingLeft = toMerge.paddingLeft { result.paddingLeft = paddingLeft }
    if let paddingTop = toMerge.paddingTop { result.paddingTop = paddingTop }
    if let paddingRight = toMerge.paddingRight { result.paddingRight = paddingRight }
    if let paddingBottom = toMerge.paddingBottom { result.paddingBottom = paddingBottom }
    if let paddingStart = toMerge.paddingStart { result.paddingStart = paddingStart }
    if let paddingEnd = toMerge.paddingEnd { result.paddingEnd = paddingEnd }
    if let paddingHorizontal = toMerge.paddingHorizontal { result.paddingHorizontal = paddingHorizontal }
    if let paddingVertical = toMerge.paddingVertical { result.paddingVertical = paddingVertical }
    if let padding = toMerge.padding { result.padding = padding }
    if let borderLeftWidth = toMerge.borderLeftWidth { result.borderLeftWidth = borderLeftWidth }
    if let borderTopWidth = toMerge.borderTopWidth { result.borderTopWidth = borderTopWidth }
    if let borderRightWidth = toMerge.borderRightWidth { result.borderRightWidth = borderRightWidth }
    if let borderBottomWidth = toMerge.borderBottomWidth { result.borderBottomWidth = borderBottomWidth }
    if let borderStartWidth = toMerge.borderStartWidth { result.borderStartWidth = borderStartWidth }
    if let borderEndWidth = toMerge.borderEndWidth { result.borderEndWidth = borderEndWidth }
    if let borderWidth = toMerge.borderWidth { result.borderWidth = borderWidth }
    if let width = toMerge.width { result.width = width }
    if let height = toMerge.height { result.height = height }
    if let minWidth = toMerge.minWidth { result.minWidth = minWidth }
    if let minHeight = toMerge.minHeight { result.minHeight = minHeight }
    if let maxWidth = toMerge.maxWidth { result.maxWidth = maxWidth }
    if let maxHeight = toMerge.maxHeight { result.maxHeight = maxHeight }

    return result
  }



  // Non-Yoga Setters
  public func backgroundColor(_ value: Color) -> Self {
    backgroundColor = value
    return self
  }

  public func color(_ value: Color) -> Self {
    color = value
    return self
  }




  // Yoga convenience setters
  public func flex(_ value: CGFloat) -> Self {
    // In React Native flex does not work the same way that it does in CSS. flex is a number
    // rather than a string, and it works according to the Yoga library at https://github.com/facebook/yoga
    //
    // When flex is a positive number, it makes the component flexible and it will be sized
    // proportional to its flex value. So a component with flex set to 2 will take twice
    // the space as a component with flex set to 1.
    //
    // When flex is 0, the component is sized according to width and height and it is inflexible.
    //
    // When flex is -1, the component is normally sized according width and height. However, if
    // there's not enough space, the component will shrink to its minWidth and minHeight.
    //
    // flexGrow, flexShrink, and flexBasis work the same as in CSS.
    if (value > 0) {
      return self
        .flexGrow(value)
        .flexShrink(1)
        .flexBasis(YGValueAuto)
    } else if (value == 0) {
      return self
        .flexGrow(0)
        .flexShrink(0)
        .flexBasis(YGValueAuto)
    } else if (value == -1) {
      return self
        .flexGrow(0)
        .flexShrink(1)
        .flexBasis(YGValueAuto)
    }
    return self
  }


  // Yoga default setters
  public func direction(_ value: YGDirection) -> Self {
    direction = value
    return self
  }

  public func flexDirection(_ value: YGFlexDirection) -> Self {
    flexDirection = value
    return self
  }

  public func justifyContent(_ value: YGJustify) -> Self {
    justifyContent = value
    return self
  }

  public func alignContent(_ value: YGAlign) -> Self {
    alignContent = value
    return self
  }

  public func alignItems(_ value: YGAlign) -> Self {
    alignItems = value
    return self
  }

  public func alignSelf(_ value: YGAlign) -> Self {
    alignSelf = value
    return self
  }

  public func position(_ value: YGPositionType) -> Self {
    position = value
    return self
  }

  public func flexWrap(_ value: YGWrap) -> Self {
    flexWrap = value
    return self
  }

  public func overflow(_ value: YGOverflow) -> Self {
    overflow = value
    return self
  }

  public func display(_ value: YGDisplay) -> Self {
    display = value
    return self
  }

  public func flexGrow(_ value: CGFloat) -> Self {
    flexGrow = value
    return self
  }

  public func flexShrink(_ value: CGFloat) -> Self {
    flexShrink = value
    return self
  }

  public func flexBasis(_ value: YGValue) -> Self {
    flexBasis = value
    return self
  }

  public func left(_ value: YGValue) -> Self {
    left = value
    return self
  }

  public func top(_ value: YGValue) -> Self {
    top = value
    return self
  }

  public func right(_ value: YGValue) -> Self {
    right = value
    return self
  }

  public func bottom(_ value: YGValue) -> Self {
    bottom = value
    return self
  }

  public func start(_ value: YGValue) -> Self {
    start = value
    return self
  }

  public func end(_ value: YGValue) -> Self {
    end = value
    return self
  }

  public func marginLeft(_ value: YGValue) -> Self {
    marginLeft = value
    return self
  }

  public func marginTop(_ value: YGValue) -> Self {
    marginTop = value
    return self
  }

  public func marginRight(_ value: YGValue) -> Self {
    marginRight = value
    return self
  }

  public func marginBottom(_ value: YGValue) -> Self {
    marginBottom = value
    return self
  }

  public func marginStart(_ value: YGValue) -> Self {
    marginStart = value
    return self
  }

  public func marginEnd(_ value: YGValue) -> Self {
    marginEnd = value
    return self
  }

  public func marginHorizontal(_ value: YGValue) -> Self {
    marginHorizontal = value
    return self
  }

  public func marginVertical(_ value: YGValue) -> Self {
    marginVertical = value
    return self
  }

  public func margin(_ value: YGValue) -> Self {
    margin = value
    return self
  }

  public func paddingLeft(_ value: YGValue) -> Self {
    paddingLeft = value
    return self
  }

  public func paddingTop(_ value: YGValue) -> Self {
    paddingTop = value
    return self
  }

  public func paddingRight(_ value: YGValue) -> Self {
    paddingRight = value
    return self
  }

  public func paddingBottom(_ value: YGValue) -> Self {
    paddingBottom = value
    return self
  }

  public func paddingStart(_ value: YGValue) -> Self {
    paddingStart = value
    return self
  }

  public func paddingEnd(_ value: YGValue) -> Self {
    paddingEnd = value
    return self
  }

  public func paddingHorizontal(_ value: YGValue) -> Self {
    paddingHorizontal = value
    return self
  }

  public func paddingVertical(_ value: YGValue) -> Self {
    paddingVertical = value
    return self
  }

  public func padding(_ value: YGValue) -> Self {
    padding = value
    return self
  }

  public func borderLeftWidth(_ value: CGFloat) -> Self {
    borderLeftWidth = value
    return self
  }

  public func borderTopWidth(_ value: CGFloat) -> Self {
    borderTopWidth = value
    return self
  }

  public func borderRightWidth(_ value: CGFloat) -> Self {
    borderRightWidth = value
    return self
  }

  public func borderBottomWidth(_ value: CGFloat) -> Self {
    borderBottomWidth = value
    return self
  }

  public func borderStartWidth(_ value: CGFloat) -> Self {
    borderStartWidth = value
    return self
  }

  public func borderEndWidth(_ value: CGFloat) -> Self {
    borderEndWidth = value
    return self
  }

  public func borderWidth(_ value: CGFloat) -> Self {
    borderWidth = value
    return self
  }

  public func width(_ value: YGValue) -> Self {
    width = value
    return self
  }

  public func height(_ value: YGValue) -> Self {
    height = value
    return self
  }

  public func minWidth(_ value: YGValue) -> Self {
    minWidth = value
    return self
  }

  public func minHeight(_ value: YGValue) -> Self {
    minHeight = value
    return self
  }

  public func maxWidth(_ value: YGValue) -> Self {
    maxWidth = value
    return self
  }

  public func maxHeight(_ value: YGValue) -> Self {
    maxHeight = value
    return self
  }

}
