package com.airbnb.android.recoil

import android.content.Context

data class ImageSource(val uri: String)

data class ImageProps(
    val style: Style? = null,
    val onPress: (() -> Unit)? = null,
    val source: ImageSource? = null,
    override var children: Element? = null
): ChildrenProps

class Image(override var props: ImageProps): HostComponent<ImageProps, ImageHostView>(props) {
  override fun mountComponent(context: Context): ImageHostView {
    val view = ImageHostView(context)
    applyProps(view, props)
    return view
  }

  override fun updateComponent(view: ImageHostView, prevProps: ImageProps) {
    applyProps(view, props)
  }

  private fun applyProps(view: ImageHostView, props: ImageProps) {
    if (props.style != null) {
      props.style.applyTo(view.yogaNode)
      props.style.applyTo(view)
    }
    view.onPress = props.onPress
    view.source = props.source
  }

  override fun renderChildren(): Element? = props.children
}
