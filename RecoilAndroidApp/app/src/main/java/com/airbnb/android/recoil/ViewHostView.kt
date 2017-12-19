package com.airbnb.android.recoil

import android.content.Context
import android.view.ViewGroup
import android.view.View
import com.facebook.yoga.android.YogaLayout.ViewMeasureFunction
import android.view.View.MeasureSpec
import com.facebook.yoga.*
import com.facebook.yoga.YogaNode
import com.facebook.yoga.YogaConstants


interface RecoilViewGroup {
  var yogaNode: YogaNode
  fun getYogaNodeForView(view: View): YogaNode?
}


class ViewHostView(context: Context): ViewGroup(context), RecoilViewGroup {
  private var yogaNodes: MutableMap<View, YogaNode> = mutableMapOf()
  override var yogaNode: YogaNode = YogaNode()
  override fun getYogaNodeForView(view: View): YogaNode? = yogaNodes.get(view)

  init {
    yogaNode.data = this
    yogaNode.setMeasureFunction(ViewMeasureFunction())
  }

  override fun onLayout(changed: Boolean, l: Int, t: Int, r: Int, b: Int) {
    // Either we are a root of a tree, or this function is called by our parent's onLayout, in which
    // case our r-l and b-t are the size of our node.
    if (parent !is RecoilViewGroup) {
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
          View.MeasureSpec.makeMeasureSpec(
              Math.round(node.layoutWidth),
              View.MeasureSpec.EXACTLY),
          View.MeasureSpec.makeMeasureSpec(
              Math.round(node.layoutHeight),
              View.MeasureSpec.EXACTLY))
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
      } else if (view is RecoilViewGroup) {
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


  override fun addView(child: View, index: Int) {
    // Internal nodes (which this is now) cannot have measure functions
    yogaNode.setMeasureFunction(null)

    super.addView(child, index)

    // It is possible that addView is being called as part of a transferal of children, in which
    // case we already know about the YogaNode and only need the Android View tree to be aware
    // that we now own this child.  If so, we don't need to do anything further
    if (yogaNodes.containsKey(child)) {
      return
    }

    val childNode = when (child) {
      is RecoilViewGroup -> child.yogaNode
      else -> {
        val childNode = yogaNodes[child] ?: YogaNode()
        childNode.data = child
        childNode.setMeasureFunction(ViewMeasureFunction())
        childNode
      }
    }

    yogaNodes[child] = childNode
    yogaNode.addChildAt(childNode, yogaNode.childCount)
  }

  override fun removeViewAt(index: Int) {
    yogaNodes.remove(getChildAt(index))
    super.removeViewAt(index)
  }

  override fun getChildAt(index: Int): View {
    return super.getChildAt(index)
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
    if (view == null || view is RecoilViewGroup) {
      return YogaMeasureOutput.make(0, 0)
    }

    val widthMeasureSpec = MeasureSpec.makeMeasureSpec(
        width.toInt(),
        viewMeasureSpecFromYogaMeasureMode(widthMode))
    val heightMeasureSpec = MeasureSpec.makeMeasureSpec(
        height.toInt(),
        viewMeasureSpecFromYogaMeasureMode(heightMode))

    view.measure(widthMeasureSpec, heightMeasureSpec)

    return YogaMeasureOutput.make(view.measuredWidth, view.measuredHeight)
  }

  private fun viewMeasureSpecFromYogaMeasureMode(mode: YogaMeasureMode): Int {
    return if (mode == YogaMeasureMode.AT_MOST) {
      MeasureSpec.AT_MOST
    } else if (mode == YogaMeasureMode.EXACTLY) {
      MeasureSpec.EXACTLY
    } else {
      MeasureSpec.UNSPECIFIED
    }
  }
}
