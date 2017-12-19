package com.airbnb.android.recoil

import android.content.Context
import com.facebook.yoga.android.VirtualYogaLayout

class TextLiteralHostView(context: Context): VirtualYogaLayout(context) {
  var text: String? = null
}

class TextLiteralComponent(override var props: String): HostComponent<String, TextLiteralHostView>(props) {

  override fun mountComponent(context: Context): TextLiteralHostView {
    val view = TextLiteralHostView(context)
    view.text = props
    return view
  }

  override fun updateComponent(view: TextLiteralHostView, prevProps: String) {
    view.text = props
  }

  override fun renderChildren(): Element? = null
}
