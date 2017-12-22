//
//  StyleSheet.swift
//  Recoil
//
//  Created by Leland Richardson on 12/12/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation
import YogaKit

let zeroScaleThreshold = CGFloat(Float.ulpOfOne)

func radians(_ val: CGFloat, _ unit: RotationUnit) -> CGFloat {
  switch unit {
  case .deg:
    return val * CGFloat.pi / 180
  case .rad:
    return val
  }
}

public enum BorderStyle {
  case unset
  case solid
  case dotted
  case dashed
}

public enum RotationUnit {
  case deg
  case rad
}

public enum Transform {
  case perspective(CGFloat)
  case scale(CGFloat)
  case scaleX(CGFloat)
  case scaleY(CGFloat)
  case translate(CGFloat, CGFloat, CGFloat)
  case translateX(CGFloat)
  case translateY(CGFloat)
  case rotateX(CGFloat, RotationUnit)
  case rotateY(CGFloat, RotationUnit)
  case rotateZ(CGFloat, RotationUnit)
  case skewX(CGFloat, RotationUnit)
  case skewY(CGFloat, RotationUnit)
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
  var transform: [Transform]?
  var borderRadius: CGFloat?
  var borderTopLeftRadius: CGFloat?
  var borderTopRightRadius: CGFloat?
  var borderBottomLeftRadius: CGFloat?
  var borderBottomRightRadius: CGFloat?
  var borderColor: Color?
  var borderTopColor: Color?
  var borderLeftColor: Color?
  var borderBottomColor: Color?
  var borderRightColor: Color?
  var borderStyle: BorderStyle = .unset

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
    if let transformArray = self.transform {
      var t = CATransform3DConcat(CATransform3DIdentity, CATransform3DIdentity)
      for tconfig in transformArray {
        switch tconfig {
        case let .perspective(val):
          t.m34 = -1 / val
        case let .rotateX(x, unit):
          t = CATransform3DRotate(t, radians(x, unit), 1, 0, 0)
        case let .rotateY(y, unit):
          t = CATransform3DRotate(t, radians(y, unit), 0, 1, 0)
        case let .rotateZ(z, unit):
          t = CATransform3DRotate(t, radians(z, unit), 0, 0, 1)
        case let .scale(scale):
          let scaleValue = (abs(scale) > zeroScaleThreshold) ? scale : zeroScaleThreshold
          t = CATransform3DScale(t, scaleValue, scaleValue, 1)
        case let .scaleX(scaleX):
          let x = (abs(scaleX) > zeroScaleThreshold) ? scaleX : zeroScaleThreshold
          t = CATransform3DScale(t, x, 1, 1)
        case let .scaleY(scaleY):
          let y = (abs(scaleY) > zeroScaleThreshold) ? scaleY : zeroScaleThreshold
          t = CATransform3DScale(t, 1, y, 1)
        case let .translate(x, y, z):
          t = CATransform3DTranslate(t, x, y, z)
        case let .translateX(x):
          t = CATransform3DTranslate(t, x, 0, 0)
        case let .translateY(y):
          t = CATransform3DTranslate(t, 0, y, 0)
        case let .skewX(skewX, unit):
          t.m21 = CGFloat(tanf(Float(radians(skewX, unit))))
        case let .skewY(skewY, unit):
          t.m12 = CGFloat(tanf(Float(radians(skewY, unit))))
        }
      }
      view.layer.transform = t
    }
  }

  func applyTo(layout: YGLayout) {
    var dirty = false

    if let direction = direction, direction != layout.direction { layout.direction = direction; dirty = true }
    if let flexDirection = flexDirection, flexDirection != layout.flexDirection { layout.flexDirection = flexDirection; dirty = true }
    if let justifyContent = justifyContent, justifyContent != layout.justifyContent { layout.justifyContent = justifyContent; dirty = true }
    if let alignContent = alignContent, alignContent != layout.alignContent { layout.alignContent = alignContent; dirty = true }
    if let alignItems = alignItems, alignItems != layout.alignItems { layout.alignItems = alignItems; dirty = true }
    if let alignSelf = alignSelf, alignSelf != layout.alignSelf { layout.alignSelf = alignSelf; dirty = true }
    if let position = position, position != layout.position { layout.position = position; dirty = true }
    if let flexWrap = flexWrap, flexWrap != layout.flexWrap { layout.flexWrap = flexWrap; dirty = true }
    if let overflow = overflow, overflow != layout.overflow { layout.overflow = overflow; dirty = true }
    if let display = display, display != layout.display { layout.display = display; dirty = true }
    if let flexGrow = flexGrow, flexGrow != layout.flexGrow { layout.flexGrow = flexGrow; dirty = true }
    if let flexShrink = flexShrink, flexShrink != layout.flexShrink { layout.flexShrink = flexShrink; dirty = true }
    if let flexBasis = flexBasis, flexBasis != layout.flexBasis { layout.flexBasis = flexBasis; dirty = true }
    if let left = left, left != layout.left { layout.left = left; dirty = true }
    if let top = top, top != layout.top { layout.top = top; dirty = true }
    if let right = right, right != layout.right { layout.right = right; dirty = true }
    if let bottom = bottom, bottom != layout.bottom { layout.bottom = bottom; dirty = true }
    if let start = start, start != layout.start { layout.start = start; dirty = true }
    if let end = end, end != layout.end { layout.end = end; dirty = true }
    if let marginLeft = marginLeft, marginLeft != layout.marginLeft { layout.marginLeft = marginLeft; dirty = true }
    if let marginTop = marginTop, marginTop != layout.marginTop { layout.marginTop = marginTop; dirty = true }
    if let marginRight = marginRight, marginRight != layout.marginRight { layout.marginRight = marginRight; dirty = true }
    if let marginBottom = marginBottom, marginBottom != layout.marginBottom { layout.marginBottom = marginBottom; dirty = true }
    if let marginStart = marginStart, marginStart != layout.marginStart { layout.marginStart = marginStart; dirty = true }
    if let marginEnd = marginEnd, marginEnd != layout.marginEnd { layout.marginEnd = marginEnd; dirty = true }
    if let marginHorizontal = marginHorizontal, marginHorizontal != layout.marginHorizontal { layout.marginHorizontal = marginHorizontal; dirty = true }
    if let marginVertical = marginVertical, marginVertical != layout.marginVertical { layout.marginVertical = marginVertical; dirty = true }
    if let margin = margin, margin != layout.margin { layout.margin = margin; dirty = true }
    if let paddingLeft = paddingLeft, paddingLeft != layout.paddingLeft { layout.paddingLeft = paddingLeft; dirty = true }
    if let paddingTop = paddingTop, paddingTop != layout.paddingTop { layout.paddingTop = paddingTop; dirty = true }
    if let paddingRight = paddingRight, paddingRight != layout.paddingRight { layout.paddingRight = paddingRight; dirty = true }
    if let paddingBottom = paddingBottom, paddingBottom != layout.paddingBottom { layout.paddingBottom = paddingBottom; dirty = true }
    if let paddingStart = paddingStart, paddingStart != layout.paddingStart { layout.paddingStart = paddingStart; dirty = true }
    if let paddingEnd = paddingEnd, paddingEnd != layout.paddingEnd { layout.paddingEnd = paddingEnd; dirty = true }
    if let paddingHorizontal = paddingHorizontal, paddingHorizontal != layout.paddingHorizontal { layout.paddingHorizontal = paddingHorizontal; dirty = true }
    if let paddingVertical = paddingVertical, paddingVertical != layout.paddingVertical { layout.paddingVertical = paddingVertical; dirty = true }
    if let padding = padding, padding != layout.padding { layout.padding = padding; dirty = true }
    if let borderLeftWidth = borderLeftWidth, borderLeftWidth != layout.borderLeftWidth { layout.borderLeftWidth = borderLeftWidth; dirty = true }
    if let borderTopWidth = borderTopWidth, borderTopWidth != layout.borderTopWidth { layout.borderTopWidth = borderTopWidth; dirty = true }
    if let borderRightWidth = borderRightWidth, borderRightWidth != layout.borderRightWidth { layout.borderRightWidth = borderRightWidth; dirty = true }
    if let borderBottomWidth = borderBottomWidth, borderBottomWidth != layout.borderBottomWidth { layout.borderBottomWidth = borderBottomWidth; dirty = true }
    if let borderStartWidth = borderStartWidth, borderStartWidth != layout.borderStartWidth { layout.borderStartWidth = borderStartWidth; dirty = true }
    if let borderEndWidth = borderEndWidth, borderEndWidth != layout.borderEndWidth { layout.borderEndWidth = borderEndWidth; dirty = true }
    if let borderWidth = borderWidth, borderWidth != layout.borderWidth { layout.borderWidth = borderWidth; dirty = true }
    if let width = width, width != layout.width { layout.width = width; dirty = true }
    if let height = height, height != layout.height { layout.height = height; dirty = true }
    if let minWidth = minWidth, minWidth != layout.minWidth { layout.minWidth = minWidth; dirty = true }
    if let minHeight = minHeight, minHeight != layout.minHeight { layout.minHeight = minHeight; dirty = true }
    if let maxWidth = maxWidth, maxWidth != layout.maxWidth { layout.maxWidth = maxWidth; dirty = true }
    if let maxHeight = maxHeight, maxHeight != layout.maxHeight { layout.maxHeight = maxHeight; dirty = true }

    if dirty {
      layout.markDirty()
    }
  }

  public static func + (left: Style, right: Style) -> Style {
    return merge(merge(Style(), left), right)
  }

  static func merge(_ result: Style, _ toMerge: Style) -> Style {

    // Text-specific props
    if let color = toMerge.color { result.color = color }

    // Non-Yoga props
    if let backgroundColor = toMerge.backgroundColor { result.backgroundColor = backgroundColor }
    if let opacity = toMerge.opacity { result.opacity = opacity }
    if let transform = toMerge.transform { result.transform = transform }
    if let borderRadius = toMerge.borderRadius { result.borderRadius = borderRadius }
    if let borderTopLeftRadius = toMerge.borderTopLeftRadius { result.borderTopLeftRadius = borderTopLeftRadius }
    if let borderTopRightRadius = toMerge.borderTopRightRadius { result.borderTopRightRadius = borderTopRightRadius }
    if let borderBottomLeftRadius = toMerge.borderBottomLeftRadius { result.borderBottomLeftRadius = borderBottomLeftRadius }
    if let borderBottomRightRadius = toMerge.borderBottomRightRadius { result.borderBottomRightRadius = borderBottomRightRadius }
    if let borderColor = toMerge.borderColor { result.borderColor = borderColor }
    if let borderTopColor = toMerge.borderTopColor { result.borderTopColor = borderTopColor }
    if let borderLeftColor = toMerge.borderLeftColor { result.borderLeftColor = borderLeftColor }
    if let borderBottomColor = toMerge.borderBottomColor { result.borderBottomColor = borderBottomColor }
    if let borderRightColor = toMerge.borderRightColor { result.borderRightColor = borderRightColor }
    if toMerge.borderStyle != .unset { result.borderStyle = toMerge.borderStyle }


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

  public func opacity(_ value: CGFloat?) -> Self {
    opacity = value
    return self
  }

  public func transform(_ value: [Transform]?) -> Self {
    transform = value
    return self
  }

  public func borderRadius(_ value: CGFloat?) -> Self {
    borderRadius = value
    return self
  }

  public func borderTopLeftRadius(_ value: CGFloat?) -> Self {
    borderTopLeftRadius = value
    return self
  }

  public func borderTopRightRadius(_ value: CGFloat?) -> Self {
    borderTopRightRadius = value
    return self
  }

  public func borderBottomLeftRadius(_ value: CGFloat?) -> Self {
    borderBottomLeftRadius = value
    return self
  }

  public func borderBottomRightRadius(_ value: CGFloat?) -> Self {
    borderBottomRightRadius = value
    return self
  }

  public func borderColor(_ value: Color?) -> Self {
    borderColor = value
    return self
  }

  public func borderTopColor(_ value: Color?) -> Self {
    borderTopColor = value
    return self
  }

  public func borderLeftColor(_ value: Color?) -> Self {
    borderLeftColor = value
    return self
  }

  public func borderBottomColor(_ value: Color?) -> Self {
    borderBottomColor = value
    return self
  }

  public func borderRightColor(_ value: Color?) -> Self {
    borderRightColor = value
    return self
  }

  public func borderStyle(_ value: BorderStyle) -> Self {
    borderStyle = value
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
