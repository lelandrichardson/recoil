package com.airbnb.android.recoil

import android.content.Context
import android.view.View
import android.view.ViewGroup
import com.facebook.yoga.*

interface RecoilView {
  var yogaNode: YogaNode
  fun getHostView(): View
  fun getYogaNodeForView(view: View): YogaNode?
  fun getRecoilSubviewAt(index: Int): RecoilView?
  fun insertRecoilSubview(view: RecoilView, index: Int)
  fun moveRecoilSubview(fromIndex: Int, toIndex: Int)
  fun removeRecoilSubview(fromIndex: Int)
  fun getRecoilParent(): RecoilView?
}

open class BaseHostView(context: Context): ViewGroup(context), RecoilView {
  private var yogaNodes: MutableMap<View, YogaNode> = mutableMapOf()
  final override var yogaNode: YogaNode = YogaNode()
  override fun getHostView(): View = this
  override fun getYogaNodeForView(view: View): YogaNode? = yogaNodes[view]

  init {
    yogaNode.data = this
    yogaNode.setMeasureFunction(ViewMeasureFunction())
  }

  override fun onLayout(changed: Boolean, l: Int, t: Int, r: Int, b: Int) {
    // Either we are a root of a tree, or this function is called by our parent's onLayout, in which
    // case our r-l and b-t are the size of our node.
    if (parent !is RecoilView) {
      createLayout(
          MeasureSpec.makeMeasureSpec(r - l, MeasureSpec.EXACTLY),
          MeasureSpec.makeMeasureSpec(b - t, MeasureSpec.EXACTLY)
      )
    }

    applyLayoutRecursive(yogaNode, 0f, 0f)
  }

  private fun applyLayoutRecursive(node: YogaNode, xOffset: Float, yOffset: Float) {
    val view = node.data as? View

    if (view != null && view !== this) {
      if (view.visibility == View.GONE) {
        return
      }
      view.measure(
          MeasureSpec.makeMeasureSpec(
              Math.round(node.layoutWidth),
              MeasureSpec.EXACTLY),
          MeasureSpec.makeMeasureSpec(
              Math.round(node.layoutHeight),
              MeasureSpec.EXACTLY))
      view.layout(
          Math.round(xOffset + node.layoutX),
          Math.round(yOffset + node.layoutY),
          Math.round(xOffset + node.layoutX + node.layoutWidth),
          Math.round(yOffset + node.layoutY + node.layoutHeight))
    }

    val childrenCount = node.childCount
    for (i in 0 until childrenCount) {
      if (this == view) {
        applyLayoutRecursive(node.getChildAt(i), xOffset, yOffset)
      } else if (view is RecoilView) {
        continue
      } else {
        applyLayoutRecursive(
            node.getChildAt(i),
            xOffset + node.layoutX,
            yOffset + node.layoutY)
      }
    }
  }

  private fun createLayout(widthMeasureSpec: Int, heightMeasureSpec: Int) {
    val widthSize = MeasureSpec.getSize(widthMeasureSpec)
    val heightSize = MeasureSpec.getSize(heightMeasureSpec)
    val widthMode = MeasureSpec.getMode(widthMeasureSpec)
    val heightMode = MeasureSpec.getMode(heightMeasureSpec)

    if (heightMode == MeasureSpec.EXACTLY) {
      yogaNode.setHeight(heightSize.toFloat())
    }
    if (widthMode == MeasureSpec.EXACTLY) {
      yogaNode.setWidth(widthSize.toFloat())
    }
    if (heightMode == MeasureSpec.AT_MOST) {
      yogaNode.setMaxHeight(heightSize.toFloat())
    }
    if (widthMode == MeasureSpec.AT_MOST) {
      yogaNode.setMaxWidth(widthSize.toFloat())
    }
    yogaNode.calculateLayout(YogaConstants.UNDEFINED, YogaConstants.UNDEFINED)
  }

  override fun insertRecoilSubview(view: RecoilView, index: Int) {
    // Internal nodes (which this is now) cannot have measure functions
    yogaNode.setMeasureFunction(null)

    addView(view.getHostView(), index)

    // It is possible that addView is being called as part of a transferal of children, in which
    // case we already know about the YogaNode and only need the Android View tree to be aware
    // that we now own this child.  If so, we don't need to do anything further
//    if (yogaNodes.containsKey(view.getHostView())) {
//      return
//    }

    val childNode = view.yogaNode
    yogaNodes[view.getHostView()] = view.yogaNode
    yogaNode.addChildAt(childNode, index)
  }

  override fun getRecoilSubviewAt(index: Int): RecoilView? {
    // in the future we should probably store these as a separate array to
    // handle the case where the view isnt the recoilview itself...
    return getChildAt(index) as? RecoilView
  }

  override fun getRecoilParent(): RecoilView? {
    return parent as? RecoilView
  }

  override fun moveRecoilSubview(fromIndex: Int, toIndex: Int) {
    val child = getRecoilSubviewAt(fromIndex) ?: throw IllegalStateException()
    removeRecoilSubview(fromIndex)
    insertRecoilSubview(child, toIndex)
  }

  override fun removeRecoilSubview(fromIndex: Int) {
    val view = getChildAt(fromIndex)
    yogaNode.removeChildAt(fromIndex)
    yogaNodes.remove(view)
    removeViewAt(fromIndex)
  }
}

class ViewMeasureFunction: YogaMeasureFunction {
  /**
   * A function to measure leaves of the Yoga tree.  Yoga needs some way to know how large
   * elements want to be.  This function passes that question directly through to the relevant
   * `View`'s measure function.
   *
   * @param node The yoga node to measure
   * @param width The suggested width from the parent
   * @param widthMode The type of suggestion for the width
   * @param height The suggested height from the parent
   * @param heightMode The type of suggestion for the height
   * @return A measurement output (`YogaMeasureOutput`) for the node
   */
  override fun measure(
      node: YogaNodeAPI<out YogaNodeAPI<*>>,
      width: Float,
      widthMode: YogaMeasureMode,
      height: Float,
      heightMode: YogaMeasureMode): Long {
    val view = node.data as? View
    if (view == null || view !is RecoilView) {
      return YogaMeasureOutput.make(0, 0)
    }

    val widthMeasureSpec = View.MeasureSpec.makeMeasureSpec(
        width.toInt(),
        viewMeasureSpecFromYogaMeasureMode(widthMode))
    val heightMeasureSpec = View.MeasureSpec.makeMeasureSpec(
        height.toInt(),
        viewMeasureSpecFromYogaMeasureMode(heightMode))

    view.measure(widthMeasureSpec, heightMeasureSpec)

    return YogaMeasureOutput.make(view.measuredWidth, view.measuredHeight)
  }

  private fun viewMeasureSpecFromYogaMeasureMode(mode: YogaMeasureMode): Int {
    return if (mode == YogaMeasureMode.AT_MOST) {
      View.MeasureSpec.AT_MOST
    } else if (mode == YogaMeasureMode.EXACTLY) {
      View.MeasureSpec.EXACTLY
    } else {
      View.MeasureSpec.UNSPECIFIED
    }
  }
}
