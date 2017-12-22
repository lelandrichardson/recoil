package com.airbnb.android.recoil

import android.content.Context
import android.view.View
import android.widget.TextView
import com.facebook.yoga.YogaNode
import com.facebook.yoga.android.YogaLayout

class TextHostView(context: Context): TextView(context), RecoilView {
  override var yogaNode: YogaNode = YogaNode()
  private var children = mutableListOf<RecoilView>()

  init {
    yogaNode.data = this
    yogaNode.setMeasureFunction(ViewMeasureFunction())
  }

  fun updateTextIfNeeded() {
    var result = ""
    for (view in children) {
      result += when (view) {
        is TextLiteralHostView -> view.text
        is TextHostView -> {
          view.updateTextIfNeeded()
          view.text
        }
        else -> throw IllegalStateException()
      }
    }
    if (result != text) {
      text = result
      yogaNode.dirty()
    }
  }

  override fun getHostView(): View = this

  override fun getYogaNodeForView(view: View): YogaNode? = null

  override fun getRecoilSubviewAt(index: Int): RecoilView? = children[index]

  override fun insertRecoilSubview(view: RecoilView, index: Int) {
    when (view) {
      is TextLiteralHostView -> children.add(index, view)
      is TextHostView -> children.add(index, view)
      else -> throw IllegalStateException()
    }
  }

  override fun moveRecoilSubview(fromIndex: Int, toIndex: Int) {
    val el = children.removeAt(fromIndex)
    insertRecoilSubview(el, toIndex)
  }

  override fun removeRecoilSubview(fromIndex: Int) {
    children.removeAt(fromIndex)
  }

  override fun getRecoilParent(): RecoilView? = parent as? RecoilView

}
