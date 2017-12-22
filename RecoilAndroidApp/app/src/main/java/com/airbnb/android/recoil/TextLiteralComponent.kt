package com.airbnb.android.recoil

import android.content.Context
import android.view.View
import com.facebook.yoga.YogaNode

class TextLiteralHostView(context: Context): View(context), RecoilView {
  override var yogaNode: YogaNode = YogaNode()
  override fun getHostView(): View = this
  override fun getYogaNodeForView(view: View): YogaNode? = null
  override fun getRecoilSubviewAt(index: Int): RecoilView?  = null
  override fun insertRecoilSubview(view: RecoilView, index: Int) {}
  override fun moveRecoilSubview(fromIndex: Int, toIndex: Int) {}
  override fun removeRecoilSubview(fromIndex: Int) {}
  override fun getRecoilParent(): RecoilView? = parent as? RecoilView

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
