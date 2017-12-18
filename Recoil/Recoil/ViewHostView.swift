//
//  ViewHostView.swift
//  Recoil
//
//  Created by Leland Richardson on 12/13/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation

public class ViewHostView: UIView {
  private var tap: UITapGestureRecognizer? = nil
  var onPress: (() -> ())? = nil {
    didSet {
      // TODO: clean this up!
      if self.tap == nil {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleOnPress(_:)))
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(tap)
        self.tap = tap
      }
    }
  }

  @objc
  func handleOnPress(_ sender: UITapGestureRecognizer) {
    if let onPress = self.onPress {
      onPress()
    }
  }

  /*
   TODO:
   - border
   - border radii
   - transforms

   */

  // border
  var borderStyle: BorderStyle = .unset
  var borderColor: UIColor = UIColor.black
  var borderTopColor: UIColor?
  var borderLeftColor: UIColor?
  var borderBottomColor: UIColor?
  var borderRightColor: UIColor?
  var borderWidth: CGFloat = -1 {
    didSet {
      if borderWidth != oldValue {
        layer.setNeedsDisplay()
      }
    }
  }
  var borderTopWidth: CGFloat = -1 {
    didSet {
      if borderTopWidth != oldValue {
        layer.setNeedsDisplay()
      }
    }
  }
  var borderLeftWidth: CGFloat = -1 {
    didSet {
      if borderLeftWidth != oldValue {
        layer.setNeedsDisplay()
      }
    }
  }
  var borderBottomWidth: CGFloat = -1 {
    didSet {
      if borderBottomWidth != oldValue {
        layer.setNeedsDisplay()
      }
    }
  }
  var borderRightWidth: CGFloat = -1 {
    didSet {
      if borderRightWidth != oldValue {
        layer.setNeedsDisplay()
      }
    }
  }
  var borderRadius: CGFloat = -1 {
    didSet {
      if borderRadius != oldValue {
        layer.setNeedsDisplay()
      }
    }
  }
  var borderTopLeftRadius: CGFloat = -1 {
    didSet {
      if borderTopLeftRadius != oldValue {
        layer.setNeedsDisplay()
      }
    }
  }
  var borderTopRightRadius: CGFloat = -1 {
    didSet {
      if borderTopRightRadius != oldValue {
        layer.setNeedsDisplay()
      }
    }
  }
  var borderBottomLeftRadius: CGFloat = -1 {
    didSet {
      if borderBottomLeftRadius != oldValue {
        layer.setNeedsDisplay()
      }
    }
  }
  var borderBottomRightRadius: CGFloat = -1 {
    didSet {
      if borderBottomRightRadius != oldValue {
        layer.setNeedsDisplay()
      }
    }
  }


  func cornerRadii() -> CornerRadii {
    // Get corner radii
    let radius = max(0, borderRadius)
    let topLeftRadius = borderTopLeftRadius >= 0 ? borderTopLeftRadius : radius
    let topRightRadius = borderTopRightRadius >= 0 ? borderTopRightRadius : radius
    let bottomLeftRadius = borderBottomLeftRadius >= 0 ? borderBottomLeftRadius : radius
    let bottomRightRadius = borderBottomRightRadius >= 0 ? borderBottomRightRadius : radius

    // Get scale factors required to prevent radii from overlapping
    let size = self.bounds.size;
    let topScaleFactor = ZeroIfNaN(min(1, size.width / (topLeftRadius + topRightRadius)))
    let bottomScaleFactor = ZeroIfNaN(min(1, size.width / (bottomLeftRadius + bottomRightRadius)))
    let rightScaleFactor = ZeroIfNaN(min(1, size.height / (topRightRadius + bottomRightRadius)))
    let leftScaleFactor = ZeroIfNaN(min(1, size.height / (topLeftRadius + bottomLeftRadius)))

    // Return scaled radii
    return CornerRadii(
      topLeft: topLeftRadius * min(topScaleFactor, leftScaleFactor),
      topRight: topRightRadius * min(topScaleFactor, rightScaleFactor),
      bottomLeft: bottomLeftRadius * min(bottomScaleFactor, leftScaleFactor),
      bottomRight: bottomRightRadius * min(bottomScaleFactor, rightScaleFactor)
    )
  }

  func bordersAsInsets() -> UIEdgeInsets {
    let borderWidth = max(0, self.borderWidth)

    return UIEdgeInsets(
      top: borderTopWidth >= 0 ? borderTopWidth : borderWidth,
      left: borderLeftWidth >= 0 ? borderLeftWidth : borderWidth,
      bottom: borderBottomWidth >= 0 ? borderBottomWidth : borderWidth,
      right: borderRightWidth  >= 0 ? borderRightWidth : borderWidth
    )
  }

  func borderColors() -> BorderColors {
    return BorderColors(
      top: borderTopColor ?? borderColor,
      left: borderLeftColor ?? borderColor,
      bottom: borderBottomColor ?? borderColor,
      right: borderRightColor ?? borderColor
    )
  }


  override public func display(_ layer: CALayer) {
    if layer.bounds.size == CGSize.zero {
      return
    }

    // RCTUpdateShadowPathForView(self)

    let corners = self.cornerRadii()
    let borderInsets = self.bordersAsInsets()
    let borderColors = self.borderColors()

    let useIOSBorderRendering =
      !isRunningInTestEnvironment() &&
      corners.allEqual() &&
      borderInsets.allEqual() &&
      borderColors.allEqual() &&
      borderStyle == .solid &&

      // iOS draws borders in front of the content whereas CSS draws them behind
      // the content. For this reason, only use iOS border drawing when clipping
      // or when the border is hidden.

      (
        borderInsets.top == 0 ||
        borderColors.top.cgColor.alpha == 0 ||
        self.clipsToBounds
      )

    // iOS clips to the outside of the border, but CSS clips to the inside. To
    // solve this, we'll need to add a container view inside the main view to
    // correctly clip the subviews.

    if useIOSBorderRendering {
      layer.cornerRadius = corners.topLeft
      layer.borderColor = borderColors.left.cgColor
      layer.borderWidth = borderInsets.left
      layer.backgroundColor = backgroundColor?.cgColor
      layer.contents = nil
      layer.needsDisplayOnBoundsChange = false
      layer.mask = nil
      return
    }

    let borderImage = RecoilGetBorderImage(
      borderStyle: borderStyle,
      viewSize: layer.bounds.size,
      cornerRadii: corners,
      borderInsets: borderInsets,
      borderColors: borderColors,
      backgroundColor: backgroundColor?.cgColor ?? UIColor.white.cgColor,
      drawToEdge: self.clipsToBounds
    )

    layer.backgroundColor = nil

    guard var image = borderImage else {
      layer.contents = nil
      layer.needsDisplayOnBoundsChange = false
      return
    }

    var contentsCenter = CGRect(
      x: image.capInsets.left / image.size.width,
      y: image.capInsets.top / image.size.height,
      width: 1.0 / image.size.width,
      height: 1.0 / image.size.height
    )

    if (isRunningInTestEnvironment()) {
      let size = self.bounds.size
      UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
      image.draw(in: CGRect(origin: .zero, size: size ))
      image = UIGraphicsGetImageFromCurrentImageContext() ?? image
      UIGraphicsEndImageContext()
      contentsCenter = CGRect(x: 0, y: 0, width: 1, height: 1)
    }

    layer.contents = image.cgImage
    layer.contentsScale = image.scale
    layer.needsDisplayOnBoundsChange = true
    layer.magnificationFilter = kCAFilterNearest

    let isResizable = image.capInsets != .zero
    if isResizable {
      layer.contentsCenter = contentsCenter
    } else {
      layer.contentsCenter = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
    }

    self.updateClipping(for: layer)
  }

  func updateClipping(for layer: CALayer) {
    var mask: CALayer? = nil
    var cornerRadius: CGFloat = 0

    if self.clipsToBounds {
      let cornerRadii = self.cornerRadii()
      if cornerRadii.allEqual() {
        cornerRadius = cornerRadii.topLeft
      } else {
        let shapeLayer = CAShapeLayer()
        let path = RCTPathCreateWithRoundedRect(
          bounds: self.bounds,
          cornerInsets: getCornerInsets(cornerRadii: cornerRadii, edgeInsets: .zero),
          transform: nil
        )
        shapeLayer.path = path
        mask = shapeLayer
      }
    }

    layer.cornerRadius = cornerRadius
    layer.mask = mask
  }

}

