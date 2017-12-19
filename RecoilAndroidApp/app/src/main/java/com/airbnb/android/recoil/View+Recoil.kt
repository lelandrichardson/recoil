package com.airbnb.android.recoil

import android.view.View
import android.view.ViewGroup


private val kRecoilRoot = "recoilRoot".hashCode()

var View.recoilRoot: RecoilRoot?
  get() {
    return getTag(kRecoilRoot) as? RecoilRoot
  }
  set(root) {
    setTag(kRecoilRoot, root)
  }

fun View.isRecoilRoot(): Boolean = recoilRoot != null

fun ViewGroup.insertRecoilSubview(view: View, index: Int) = addView(view, index)

fun ViewGroup.moveRecoilSubview(fromIndex: Int, toIndex: Int) {
  val child = getChildAt(fromIndex)
  removeViewAt(fromIndex)
  addView(child, toIndex)
}

fun ViewGroup.removeRecoilSubview(fromIndex: Int) = removeViewAt(fromIndex)
