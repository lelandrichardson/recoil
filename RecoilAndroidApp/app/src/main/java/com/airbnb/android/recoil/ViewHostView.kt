package com.airbnb.android.recoil

import android.content.Context
import android.view.View


class ViewHostView(context: Context): BaseHostView(context), View.OnClickListener {
  init {
    setOnClickListener(this)
  }
  override fun onClick(p0: View?) {
    val onPress = onPress
    if (onPress != null) {
      onPress()
    }
  }

  var onPress: (() -> Unit)? = null
}
