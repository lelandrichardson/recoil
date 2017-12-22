package com.airbnb.android.recoilandroidapp

import android.graphics.Color
import com.airbnb.android.recoil.*
import com.facebook.yoga.YogaFlexDirection
import com.facebook.yoga.YogaJustify

data class FooProps(
    val foo: String
)

class Foo(props: AppProps): Component<AppProps, Unit>(props) {
  override fun getInitialState() {  }

  override fun render(): Element? {
    return (
      h(::View, ViewProps(style = styles.child)) {
        h("String")
      }
    )
  }

  private companion object styles {
    val child = Style(
        width = 80.pt,
        height = 80.pt
    )
  }
}



