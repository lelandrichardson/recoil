package com.airbnb.android.recoil

import com.facebook.yoga.*


enum class BorderStyle {
  unset,
  solid,
  dotted,
  dashed
}

enum class RotationUnit {
  deg,
  rad
}

data class Transform(
  var value: Float
)

typealias Color = Int

//enum class Transform {
//  case scaleX(Float)
//  case scaleY(Float)
//  case translateX(Float)
//  case translateY(Float)
//  case rotate(Float, RotationUnit)
//  case skewX(Float)
//  case skewY(Float)
//}


data class Style(
    val color: Color? = null,
    val fontSize: Float = 17f,
    val fontWeight: String? = null,
    val lineHeight: Float? = null,
    val fontFamily: String? = null,
    val letterSpacing: Float? = null,
    val textDecorationStyle: String? = null,
    val textAlign: String? = null,
    val textDecorationLine: String? = null,
    val backgroundColor: Color? = null,
    val opacity: Float? = null,
    val transform: List<Transform>? = null,
    val borderRadius: Float? = null,
    val borderTopLeftRadius: Float? = null,
    val borderTopRightRadius: Float? = null,
    val borderBottomLeftRadius: Float? = null,
    val borderBottomRightRadius: Float? = null,
    val borderColor: Color? = null,
    val borderTopColor: Color? = null,
    val borderLeftColor: Color? = null,
    val borderBottomColor: Color? = null,
    val borderRightColor: Color? = null,
    val borderStyle: BorderStyle = BorderStyle.unset,
    val flex: Float? = null,
    val flexDirection: YogaFlexDirection? = null,
    val justifyContent: YogaJustify? = null,
    val alignContent: YogaAlign? = null,
    val alignItems: YogaAlign? = null,
    val alignSelf: YogaAlign? = null,
    val position: YogaPositionType? = null,
    val flexWrap: YogaWrap? = null,
    val overflow: YogaOverflow? = null,
    val display: YogaDisplay? = null,
    val flexGrow: Float? = null,
    val flexShrink: Float? = null,
    val flexBasis: YogaValue? = null,
    val left: YogaValue? = null,
    val top: YogaValue? = null,
    val right: YogaValue? = null,
    val bottom: YogaValue? = null,
    val marginLeft: YogaValue? = null,
    val marginTop: YogaValue? = null,
    val marginRight: YogaValue? = null,
    val marginBottom: YogaValue? = null,
    val marginHorizontal: YogaValue? = null,
    val marginVertical: YogaValue? = null,
    val margin: YogaValue? = null,
    val paddingLeft: YogaValue? = null,
    val paddingTop: YogaValue? = null,
    val paddingRight: YogaValue? = null,
    val paddingBottom: YogaValue? = null,
    val paddingHorizontal: YogaValue? = null,
    val paddingVertical: YogaValue? = null,
    val padding: YogaValue? = null,
    val borderLeftWidth: Float? = null,
    val borderTopWidth: Float? = null,
    val borderRightWidth: Float? = null,
    val borderBottomWidth: Float? = null,
    val borderWidth: Float? = null,
    val width: YogaValue? = null,
    val height: YogaValue? = null,
    val minWidth: YogaValue? = null,
    val minHeight: YogaValue? = null,
    val maxWidth: YogaValue? = null,
    val maxHeight: YogaValue? = null
) {
  fun applyTo(node: YogaNode) {
    val flag = DirtyFlag(false)

    // flex is special since if you set it, it sets multiple values. we want
    // to prevent from dirtying the node if we don't need to, so we do some custom
    // logic here to ensure we don't dirty when nothing has changed
    if (flex != null) {
      when {
        flex > 0 -> {
          if (
            node.flexGrow != flex ||
            node.flexShrink != 1f ||
            node.flexBasis.unit != YogaUnit.AUTO
          ) {
            flag.dirty = true
            node.setFlex(flex)
          }
        }
        flex == 0f -> {
          if (
            node.flexGrow != 0f ||
            node.flexShrink != 0f ||
            node.flexBasis.unit != YogaUnit.AUTO
          ) {
            flag.dirty = true
            node.setFlex(flex)
          }
        }
        flex == -1f -> {
          if (
            node.flexGrow != 0f ||
            node.flexShrink != 0f ||
            node.flexBasis.unit != YogaUnit.AUTO
          ) {
            flag.dirty = true
            node.setFlex(flex)
          }
        }
        else -> {
          // invalid value
          throw IllegalArgumentException("The only negative flex value can be -1")
        }
      }
    }

    if (width != null && node.width != width) {
      flag.dirty = true
      when (width.unit) {
        YogaUnit.PERCENT -> node.setWidthPercent(width.value)
        YogaUnit.POINT -> node.setWidth(width.value)
        YogaUnit.AUTO -> node.setWidthAuto()
        else -> Unit
      }
    }

    // YogaValue:
    if (width != null && node.width != width) {
      flag.dirty = true
      when (width.unit) {
        YogaUnit.PERCENT -> node.setWidthPercent(width.value)
        YogaUnit.POINT -> node.setWidth(width.value)
        YogaUnit.AUTO -> node.setWidthAuto()
        else -> Unit
      }
    }
    if (height != null && node.height != height) {
      flag.dirty = true
      when (height.unit) {
        YogaUnit.PERCENT -> node.setHeightPercent(height.value)
        YogaUnit.POINT -> node.setHeight(height.value)
        YogaUnit.AUTO -> node.setHeightAuto()
        else -> Unit
      }
    }
    if (minWidth != null && node.minWidth != minWidth) {
      flag.dirty = true
      when (minWidth.unit) {
        YogaUnit.PERCENT -> node.setMinWidthPercent(minWidth.value)
        YogaUnit.POINT -> node.setMinWidth(minWidth.value)
        else -> Unit
      }
    }
    if (minHeight != null && node.minHeight != minHeight) {
      flag.dirty = true
      when (minHeight.unit) {
        YogaUnit.PERCENT -> node.setMinHeightPercent(minHeight.value)
        YogaUnit.POINT -> node.setMinHeight(minHeight.value)
        else -> Unit
      }
    }
    if (maxWidth != null && node.maxWidth != maxWidth) {
      flag.dirty = true
      when (maxWidth.unit) {
        YogaUnit.PERCENT -> node.setMaxWidthPercent(maxWidth.value)
        YogaUnit.POINT -> node.setMaxWidth(maxWidth.value)
        else -> Unit
      }
    }
    if (maxHeight != null && node.maxHeight != maxHeight) {
      flag.dirty = true
      when (maxHeight.unit) {
        YogaUnit.PERCENT -> node.setMaxHeightPercent(maxHeight.value)
        YogaUnit.POINT -> node.setMaxHeight(maxHeight.value)
        else -> Unit
      }
    }
    if (flexBasis != null && node.flexBasis != flexBasis) {
      flag.dirty = true
      when (flexBasis.unit) {
        YogaUnit.PERCENT -> node.setFlexBasisPercent(flexBasis.value)
        YogaUnit.POINT -> node.setFlexBasis(flexBasis.value)
        YogaUnit.AUTO -> node.setFlexBasisAuto()
        else -> Unit
      }
    }

    setPosition(node, YogaEdge.TOP, top, flag)
    setPosition(node, YogaEdge.LEFT, left, flag)
    setPosition(node, YogaEdge.BOTTOM, bottom, flag)
    setPosition(node, YogaEdge.RIGHT, right, flag)

    setMargin(node, YogaEdge.ALL, margin, flag)
    setMargin(node, YogaEdge.HORIZONTAL, marginHorizontal, flag)
    setMargin(node, YogaEdge.VERTICAL, marginVertical, flag)
    setMargin(node, YogaEdge.TOP, marginTop, flag)
    setMargin(node, YogaEdge.LEFT, marginLeft, flag)
    setMargin(node, YogaEdge.BOTTOM, marginBottom, flag)
    setMargin(node, YogaEdge.RIGHT, marginRight, flag)

    setPadding(node, YogaEdge.ALL, padding, flag)
    setPadding(node, YogaEdge.HORIZONTAL, paddingHorizontal, flag)
    setPadding(node, YogaEdge.VERTICAL, paddingVertical, flag)
    setPadding(node, YogaEdge.TOP, paddingTop, flag)
    setPadding(node, YogaEdge.LEFT, paddingLeft, flag)
    setPadding(node, YogaEdge.BOTTOM, paddingBottom, flag)
    setPadding(node, YogaEdge.RIGHT, paddingRight, flag)

    setBorder(node, YogaEdge.ALL, borderWidth, flag)
    setBorder(node, YogaEdge.TOP, borderTopWidth, flag)
    setBorder(node, YogaEdge.LEFT, borderLeftWidth, flag)
    setBorder(node, YogaEdge.BOTTOM, borderBottomWidth, flag)
    setBorder(node, YogaEdge.RIGHT, borderRightWidth, flag)

    if (flexDirection != null && node.flexDirection != flexDirection) {
      flag.dirty = true
      node.flexDirection = flexDirection
    }

    if (justifyContent != null && node.justifyContent != justifyContent) {
      flag.dirty = true
      node.justifyContent = justifyContent
    }

    if (alignContent != null && node.alignContent != alignContent) {
      flag.dirty = true
      node.alignContent = alignContent
    }

    if (alignItems != null && node.alignItems != alignItems) {
      flag.dirty = true
      node.alignItems = alignItems
    }

    if (alignSelf != null && node.alignSelf != alignSelf) {
      flag.dirty = true
      node.alignSelf = alignSelf
    }

    if (alignSelf != null && node.alignSelf != alignSelf) {
      flag.dirty = true
      node.alignSelf = alignSelf
    }

    if (position != null && node.positionType != position) {
      flag.dirty = true
      node.positionType = position
    }
    if (flexWrap != null) {
      flag.dirty = true
      node.setWrap(flexWrap)
    }
    if (overflow != null && node.overflow != overflow) {
      flag.dirty = true
      node.overflow = overflow
    }
    if (display != null && node.display != display) {
      flag.dirty = true
      node.display = display
    }
    if (flexGrow != null && node.flexGrow != flexGrow) {
      flag.dirty = true
      node.flexGrow = flexGrow
    }
    if (flexShrink != null && node.flexShrink != flexShrink) {
      flag.dirty = true
      node.flexShrink = flexShrink
    }
    if (flexBasis != null && node.flexBasis != flexBasis) {
      flag.dirty = true
      when (flexBasis.unit) {
        YogaUnit.PERCENT -> node.setFlexBasisPercent(flexBasis.value)
        YogaUnit.POINT -> node.setFlexBasis(flexBasis.value)
        YogaUnit.AUTO -> node.setFlexBasisAuto()
        else -> Unit
      }
    }

    if (flag.dirty) {
      node.dirty()
    }
  }

  private fun setPosition(node: YogaNode, edge: YogaEdge, value: YogaValue?, flag: DirtyFlag) {
    if (value != null && node.getPosition(edge) != value) {
      flag.dirty = true
      when (value.unit) {
        YogaUnit.PERCENT -> node.setPositionPercent(edge, value.value)
        YogaUnit.POINT -> node.setPosition(edge, value.value)
        else -> Unit
      }
    }
  }

  private fun setPadding(node: YogaNode, edge: YogaEdge, value: YogaValue?, flag: DirtyFlag) {
    if (value != null && node.getPadding(edge) != value) {
      flag.dirty = true
      when (value.unit) {
        YogaUnit.PERCENT -> node.setPaddingPercent(edge, value.value)
        YogaUnit.POINT -> node.setPadding(edge, value.value)
        else -> Unit
      }
    }
  }

  private fun setBorder(node: YogaNode, edge: YogaEdge, value: Float?, flag: DirtyFlag) {
    if (value != null && node.getBorder(edge) != value) {
      flag.dirty = true
      node.setBorder(edge, value)
    }
  }

  private fun setMargin(node: YogaNode, edge: YogaEdge, value: YogaValue?, flag: DirtyFlag) {
    if (value != null && node.getMargin(edge) != value) {
      flag.dirty = true
      when (value.unit) {
        YogaUnit.PERCENT -> node.setMarginPercent(edge, value.value)
        YogaUnit.POINT -> node.setMargin(edge, value.value)
        YogaUnit.AUTO -> node.setMarginAuto(edge)
        else -> Unit
      }
    }
  }

  // NOTE: in normal UI code, concatting styles together will be a pretty normal thing,
  // and in this implementation it takes a few CPU cycles. We should consider a way to
  // store an array and flatten these only when needed...
  operator fun plus(rhs: Style): Style {
    return merge(this, rhs)
  }

  fun merge(a: Style, b: Style): Style {
    return Style(
      // Text-specific props
      color = b.color ?: a.color,

      // Non-Yoga props
      backgroundColor = b.backgroundColor ?: a.backgroundColor,
      opacity = b.opacity ?: a.opacity,
      transform = b.transform ?: a.transform,
      borderRadius = b.borderRadius ?: a.borderRadius,
      borderTopLeftRadius = b.borderTopLeftRadius ?: a.borderTopLeftRadius,
      borderTopRightRadius = b.borderTopRightRadius ?: a.borderTopRightRadius,
      borderBottomLeftRadius = b.borderBottomLeftRadius ?: a.borderBottomLeftRadius,
      borderBottomRightRadius = b.borderBottomRightRadius ?: a.borderBottomRightRadius,
      borderColor = b.borderColor ?: a.borderColor,
      borderTopColor = b.borderTopColor ?: a.borderTopColor,
      borderLeftColor = b.borderLeftColor ?: a.borderLeftColor,
      borderBottomColor = b.borderBottomColor ?: a.borderBottomColor,
      borderRightColor = b.borderRightColor ?: a.borderRightColor,
      borderStyle = if (b.borderStyle != BorderStyle.unset) b.borderStyle else a.borderStyle,

      // Yoga props
      flexDirection = b.flexDirection ?: a.flexDirection,
      justifyContent = b.justifyContent ?: a.justifyContent,
      alignContent = b.alignContent ?: a.alignContent,
      alignItems = b.alignItems ?: a.alignItems,
      alignSelf = b.alignSelf ?: a.alignSelf,
      position = b.position ?: a.position,
      flexWrap = b.flexWrap ?: a.flexWrap,
      overflow = b.overflow ?: a.overflow,
      display = b.display ?: a.display,
      flexGrow = b.flexGrow ?: a.flexGrow,
      flexShrink = b.flexShrink ?: a.flexShrink,
      flexBasis = b.flexBasis ?: a.flexBasis,
      left = b.left ?: a.left,
      top = b.top ?: a.top,
      right = b.right ?: a.right,
      bottom = b.bottom ?: a.bottom,
      marginLeft = b.marginLeft ?: a.marginLeft,
      marginTop = b.marginTop ?: a.marginTop,
      marginRight = b.marginRight ?: a.marginRight,
      marginBottom = b.marginBottom ?: a.marginBottom,
      marginHorizontal = b.marginHorizontal ?: a.marginHorizontal,
      marginVertical = b.marginVertical ?: a.marginVertical,
      margin = b.margin ?: a.margin,
      paddingLeft = b.paddingLeft ?: a.paddingLeft,
      paddingTop = b.paddingTop ?: a.paddingTop,
      paddingRight = b.paddingRight ?: a.paddingRight,
      paddingBottom = b.paddingBottom ?: a.paddingBottom,
      paddingHorizontal = b.paddingHorizontal ?: a.paddingHorizontal,
      paddingVertical = b.paddingVertical ?: a.paddingVertical,
      padding = b.padding ?: a.padding,
      borderLeftWidth = b.borderLeftWidth ?: a.borderLeftWidth,
      borderTopWidth = b.borderTopWidth ?: a.borderTopWidth,
      borderRightWidth = b.borderRightWidth ?: a.borderRightWidth,
      borderBottomWidth = b.borderBottomWidth ?: a.borderBottomWidth,
      borderWidth = b.borderWidth ?: a.borderWidth,
      width = b.width ?: a.width,
      height = b.height ?: a.height,
      minWidth = b.minWidth ?: a.minWidth,
      minHeight = b.minHeight ?: a.minHeight,
      maxWidth = b.maxWidth ?: a.maxWidth,
      maxHeight = b.maxHeight ?: a.maxHeight
    )
  }
}

private data class DirtyFlag(var dirty: Boolean)

val Int.pct: YogaValue get() = YogaValue(this.toFloat(), YogaUnit.PERCENT)
val Int.pt: YogaValue get() = YogaValue(this.toFloat(), YogaUnit.POINT)
val Float.pct: YogaValue get() = YogaValue(this, YogaUnit.PERCENT)
val Float.pt: YogaValue get() = YogaValue(this, YogaUnit.POINT)
val Double.pct: YogaValue get() = YogaValue(this.toFloat(), YogaUnit.PERCENT)
val Double.pt: YogaValue get() = YogaValue(this.toFloat(), YogaUnit.POINT)
