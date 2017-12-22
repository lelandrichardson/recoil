package com.airbnb.android.recoil

import android.content.Context

data class TextProps(
    val style: Style? = null,
    val onPress: (() -> Unit)? = null,
    override var children: Element? = null
): ChildrenProps

class Text(override var props: TextProps): HostComponent<TextProps, TextHostView>(props) {
  override fun mountComponent(context: Context): TextHostView {
    val view = TextHostView(context)
    applyProps(view, props)
    return view
  }

  override fun updateComponent(view: TextHostView, prevProps: TextProps) {
    applyProps(view, props)
  }

  private fun applyProps(view: TextHostView, props: TextProps) {
    if (props.style != null) {
      props.style.applyTo(view.yogaNode)
      if (props.style.backgroundColor != null) {
        view.setBackgroundColor(props.style.backgroundColor)
      }
    }
  }

  override fun renderChildren(): Element? = props.children

  override fun childrenDidUpdate(view: TextHostView, prevProps: TextProps) {
    view.updateTextIfNeeded()
  }

  override fun childrenDidMount(view: TextHostView) {
    view.updateTextIfNeeded()
  }
}
