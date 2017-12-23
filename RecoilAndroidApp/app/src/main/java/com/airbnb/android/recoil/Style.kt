package com.airbnb.android.recoil

import android.content.res.Resources
import android.view.View
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

typealias Color = Int

sealed class Transform {
  abstract fun transform(m: Matrix): Matrix

  class Perspective(val value: Double): Transform() {
    override fun transform(m: Matrix): Matrix {
      MatrixMathHelper.applyPerspective(m, value)
      return m
    }
  }

  class Scale(val value: Double): Transform() {
    override fun transform(m: Matrix): Matrix {
      MatrixMathHelper.applyScaleX(m, value)
      MatrixMathHelper.applyScaleY(m, value)
      return m
    }
  }
  class ScaleX(val value: Double): Transform() {
    override fun transform(m: Matrix): Matrix {
      MatrixMathHelper.applyScaleX(m, value)
      return m
    }
  }
  class ScaleY(val value: Double): Transform() {
    override fun transform(m: Matrix): Matrix {
      MatrixMathHelper.applyScaleY(m, value)
      return m
    }
  }
  class Translate(val x: Double, val y: Double, val z: Double): Transform() {
    override fun transform(m: Matrix): Matrix {
      MatrixMathHelper.applyTranslate2D(m, x, y)
      return m
    }
  }
  class TranslateX(val value: Double): Transform() {
    override fun transform(m: Matrix): Matrix {
      MatrixMathHelper.applyTranslate2D(m, value, 0.0)
      return m
    }
  }
  class TranslateY(val value: Double): Transform() {
    override fun transform(m: Matrix): Matrix {
      MatrixMathHelper.applyTranslate2D(m, 0.0, value)
      return m
    }
  }
  class RotateX(val value: Double, val unit: RotationUnit): Transform() {
    override fun transform(m: Matrix): Matrix {
      val radians = toRadians(value, unit)
      MatrixMathHelper.applyRotateX(m, radians)
      return m
    }
  }
  class RotateY(val value: Double, val unit: RotationUnit): Transform() {
    override fun transform(m: Matrix): Matrix {
      val radians = toRadians(value, unit)
      MatrixMathHelper.applyRotateY(m, radians)
      return m
    }
  }
  class RotateZ(val value: Double, val unit: RotationUnit): Transform()  {
    override fun transform(m: Matrix): Matrix {
      val radians = toRadians(value, unit)
      MatrixMathHelper.applyRotateZ(m, radians)
      return m
    }
  }
  class SkewX(val value: Double, val unit: RotationUnit): Transform() {
    override fun transform(m: Matrix): Matrix {
      val radians = toRadians(value, unit)
      MatrixMathHelper.applySkewX(m, radians)
      return m
    }
  }
  class SkewY(val value: Double, val unit: RotationUnit): Transform() {
    override fun transform(m: Matrix): Matrix {
      val radians = toRadians(value, unit)
      MatrixMathHelper.applySkewY(m, radians)
      return m
    }
  }

  internal fun toRadians(value: Double, unit: RotationUnit): Double = when (unit) {
    RotationUnit.deg -> value * Math.PI / 180
    RotationUnit.rad -> value
  }
}


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
  fun applyTo(view: View) {
    if (backgroundColor != null) {
      view.setBackgroundColor(backgroundColor)
    }
    if (transform != null) {
      var t = MatrixMathHelper.createIdentityMatrix()
      for (spec in transform) {
        t = spec.transform(t)
      }

      val sMatrixDecompositionContext = MatrixMathHelper.MatrixDecompositionContext()

      MatrixMathHelper.decomposeMatrix(t, sMatrixDecompositionContext)

      view.translationX = dpToPx * sMatrixDecompositionContext.translation[0].toFloat() // TODO: convert to px from dp
      view.translationY = dpToPx * sMatrixDecompositionContext.translation[1].toFloat()
      view.rotation = sMatrixDecompositionContext.rotationDegrees[2].toFloat()
      view.rotationX = sMatrixDecompositionContext.rotationDegrees[0].toFloat()
      view.rotationY = sMatrixDecompositionContext.rotationDegrees[1].toFloat()
      view.scaleX = sMatrixDecompositionContext.scale[0].toFloat()
      view.scaleY = sMatrixDecompositionContext.scale[1].toFloat()
    }
  }
  fun applyTo(node: YogaNode) {

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
            node.setFlex(flex)
          }
        }
        flex == 0f -> {
          if (
            node.flexGrow != 0f ||
            node.flexShrink != 0f ||
            node.flexBasis.unit != YogaUnit.AUTO
          ) {
            node.setFlex(flex)
          }
        }
        flex == -1f -> {
          if (
            node.flexGrow != 0f ||
            node.flexShrink != 0f ||
            node.flexBasis.unit != YogaUnit.AUTO
          ) {
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
      when (width.unit) {
        YogaUnit.PERCENT -> node.setWidthPercent(width.value)
        YogaUnit.POINT -> node.setWidth(width.value)
        YogaUnit.AUTO -> node.setWidthAuto()
        else -> Unit
      }
    }

    // YogaValue:
    if (width != null && node.width != width) {
      when (width.unit) {
        YogaUnit.PERCENT -> node.setWidthPercent(width.value)
        YogaUnit.POINT -> node.setWidth(width.value)
        YogaUnit.AUTO -> node.setWidthAuto()
        else -> Unit
      }
    }
    if (height != null && node.height != height) {
      when (height.unit) {
        YogaUnit.PERCENT -> node.setHeightPercent(height.value)
        YogaUnit.POINT -> node.setHeight(height.value)
        YogaUnit.AUTO -> node.setHeightAuto()
        else -> Unit
      }
    }
    if (minWidth != null && node.minWidth != minWidth) {
      when (minWidth.unit) {
        YogaUnit.PERCENT -> node.setMinWidthPercent(minWidth.value)
        YogaUnit.POINT -> node.setMinWidth(minWidth.value)
        else -> Unit
      }
    }
    if (minHeight != null && node.minHeight != minHeight) {
      when (minHeight.unit) {
        YogaUnit.PERCENT -> node.setMinHeightPercent(minHeight.value)
        YogaUnit.POINT -> node.setMinHeight(minHeight.value)
        else -> Unit
      }
    }
    if (maxWidth != null && node.maxWidth != maxWidth) {
      when (maxWidth.unit) {
        YogaUnit.PERCENT -> node.setMaxWidthPercent(maxWidth.value)
        YogaUnit.POINT -> node.setMaxWidth(maxWidth.value)
        else -> Unit
      }
    }
    if (maxHeight != null && node.maxHeight != maxHeight) {
      when (maxHeight.unit) {
        YogaUnit.PERCENT -> node.setMaxHeightPercent(maxHeight.value)
        YogaUnit.POINT -> node.setMaxHeight(maxHeight.value)
        else -> Unit
      }
    }
    if (flexBasis != null && node.flexBasis != flexBasis) {
      when (flexBasis.unit) {
        YogaUnit.PERCENT -> node.setFlexBasisPercent(flexBasis.value)
        YogaUnit.POINT -> node.setFlexBasis(flexBasis.value)
        YogaUnit.AUTO -> node.setFlexBasisAuto()
        else -> Unit
      }
    }

    setPosition(node, YogaEdge.TOP, top)
    setPosition(node, YogaEdge.LEFT, left)
    setPosition(node, YogaEdge.BOTTOM, bottom)
    setPosition(node, YogaEdge.RIGHT, right)

    setMargin(node, YogaEdge.ALL, margin)
    setMargin(node, YogaEdge.HORIZONTAL, marginHorizontal)
    setMargin(node, YogaEdge.VERTICAL, marginVertical)
    setMargin(node, YogaEdge.TOP, marginTop)
    setMargin(node, YogaEdge.LEFT, marginLeft)
    setMargin(node, YogaEdge.BOTTOM, marginBottom)
    setMargin(node, YogaEdge.RIGHT, marginRight)

    setPadding(node, YogaEdge.ALL, padding)
    setPadding(node, YogaEdge.HORIZONTAL, paddingHorizontal)
    setPadding(node, YogaEdge.VERTICAL, paddingVertical)
    setPadding(node, YogaEdge.TOP, paddingTop)
    setPadding(node, YogaEdge.LEFT, paddingLeft)
    setPadding(node, YogaEdge.BOTTOM, paddingBottom)
    setPadding(node, YogaEdge.RIGHT, paddingRight)

    setBorder(node, YogaEdge.ALL, borderWidth)
    setBorder(node, YogaEdge.TOP, borderTopWidth)
    setBorder(node, YogaEdge.LEFT, borderLeftWidth)
    setBorder(node, YogaEdge.BOTTOM, borderBottomWidth)
    setBorder(node, YogaEdge.RIGHT, borderRightWidth)

    if (flexDirection != null && node.flexDirection != flexDirection) {
      node.flexDirection = flexDirection
    }

    if (justifyContent != null && node.justifyContent != justifyContent) {
      node.justifyContent = justifyContent
    }

    if (alignContent != null && node.alignContent != alignContent) {
      node.alignContent = alignContent
    }

    if (alignItems != null && node.alignItems != alignItems) {
      node.alignItems = alignItems
    }

    if (alignSelf != null && node.alignSelf != alignSelf) {
      node.alignSelf = alignSelf
    }

    if (alignSelf != null && node.alignSelf != alignSelf) {
      node.alignSelf = alignSelf
    }

    if (position != null && node.positionType != position) {
      node.positionType = position
    }
    if (flexWrap != null) {
      node.setWrap(flexWrap)
    }
    if (overflow != null && node.overflow != overflow) {
      node.overflow = overflow
    }
    if (display != null && node.display != display) {
      node.display = display
    }
    if (flexGrow != null && node.flexGrow != flexGrow) {
      node.flexGrow = flexGrow
    }
    if (flexShrink != null && node.flexShrink != flexShrink) {
      node.flexShrink = flexShrink
    }
    if (flexBasis != null && node.flexBasis != flexBasis) {
      when (flexBasis.unit) {
        YogaUnit.PERCENT -> node.setFlexBasisPercent(flexBasis.value)
        YogaUnit.POINT -> node.setFlexBasis(flexBasis.value)
        YogaUnit.AUTO -> node.setFlexBasisAuto()
        else -> Unit
      }
    }
  }

  private fun setPosition(node: YogaNode, edge: YogaEdge, value: YogaValue?) {
    if (value != null && node.getPosition(edge) != value) {
      when (value.unit) {
        YogaUnit.PERCENT -> node.setPositionPercent(edge, value.value)
        YogaUnit.POINT -> node.setPosition(edge, value.value)
        else -> Unit
      }
    }
  }

  private fun setPadding(node: YogaNode, edge: YogaEdge, value: YogaValue?) {
    if (value != null && node.getPadding(edge) != value) {
      when (value.unit) {
        YogaUnit.PERCENT -> node.setPaddingPercent(edge, value.value)
        YogaUnit.POINT -> node.setPadding(edge, value.value)
        else -> Unit
      }
    }
  }

  private fun setBorder(node: YogaNode, edge: YogaEdge, value: Float?) {
    if (value != null && node.getBorder(edge) != value) {
      node.setBorder(edge, value)
    }
  }

  private fun setMargin(node: YogaNode, edge: YogaEdge, value: YogaValue?) {
    if (value != null && node.getMargin(edge) != value) {
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

  private fun merge(a: Style, b: Style): Style {
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

val metrics = Resources.getSystem().displayMetrics
val dpToPx = metrics.densityDpi / 160f

val Int.pct: YogaValue get() = YogaValue(this.toFloat(), YogaUnit.PERCENT)
val Int.pt: YogaValue get() = YogaValue(this.toFloat() * dpToPx, YogaUnit.POINT)
val Float.pct: YogaValue get() = YogaValue(this, YogaUnit.PERCENT)
val Float.pt: YogaValue get() = YogaValue(this * dpToPx, YogaUnit.POINT)
val Double.pct: YogaValue get() = YogaValue(this.toFloat(), YogaUnit.PERCENT)
val Double.pt: YogaValue get() = YogaValue(this.toFloat() * dpToPx, YogaUnit.POINT)
