package com.airbnb.android.recoilandroidapp

import android.graphics.Color
import com.airbnb.android.recoil.*
import com.facebook.yoga.YogaFlexDirection
import com.facebook.yoga.YogaJustify

data class AppProps(
  val foo: String
)

data class AppState(
  val count: Int
)

class App(props: AppProps): Component<AppProps, AppState>(props) {
  override fun getInitialState(): AppState = AppState(123)
  override fun render(): Element? = h(::View, ViewProps(
      style = styles.container,
      children = h(arrayOf(
        h(::View, ViewProps(
            style = styles.child
        )),
        h(::View, ViewProps(
            style = styles.child
        )),
        h(::View, ViewProps(
            style = styles.child
        ))
      ))
  ))
}

private object styles {
  val container = Style(
      backgroundColor = Color.RED,
      flexDirection = YogaFlexDirection.ROW,
      justifyContent = YogaJustify.SPACE_BETWEEN
  )
  val child = Style(
      backgroundColor = Color.GREEN,
      width = 80.pt,
      height = 80.pt
  )
}
