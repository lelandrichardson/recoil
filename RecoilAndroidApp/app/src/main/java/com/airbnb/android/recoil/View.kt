package com.airbnb.android.recoil

import android.content.Context

data class ViewProps(
  val style: Style? = null,
  val onPress: (() -> Unit)? = null,
  override var children: Element? = null
): ChildrenProps

class View(override var props: ViewProps): HostComponent<ViewProps, ViewHostView>(props) {
  override fun mountComponent(context: Context): ViewHostView {
    val view = ViewHostView(context)
    applyProps(view, props)
    return view
  }

  override fun updateComponent(view: ViewHostView, prevProps: ViewProps) {
    applyProps(view, props)
  }

  private fun applyProps(view: ViewHostView, props: ViewProps) {
    if (props.style != null) {
      props.style.applyTo(view.yogaNode)
      props.style.applyTo(view)
    }
    view.onPress = props.onPress
  }

  override fun renderChildren(): Element? = props.children
}
