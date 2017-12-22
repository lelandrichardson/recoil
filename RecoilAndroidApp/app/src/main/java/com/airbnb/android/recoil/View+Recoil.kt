package com.airbnb.android.recoil

import android.view.View


private val kRecoilRoot = "recoilRoot".hashCode()

var View.recoilRoot: RecoilRoot?
  get() {
    return getTag(kRecoilRoot) as? RecoilRoot
  }
  set(root) {
    setTag(kRecoilRoot, root)
  }

fun View.isRecoilRoot(): Boolean = recoilRoot != null
