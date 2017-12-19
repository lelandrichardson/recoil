package com.airbnb.android.recoil

import android.content.Context
import android.view.ViewGroup


class RecoilRoot(var rootView: ViewGroup?) {
  var rootInstance: RecoilInstance? = null

  val context: Context get() = rootView?.context ?: throw IllegalStateException()

//  var displayLink: CADisplayLink?

  fun enqueueLayout() {

  }
}
