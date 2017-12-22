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

//  override fun componentDidMount() {
//    setState { (count) -> AppState(count = count + 1 ) }
//  }
//
//  override fun componentDidUpdate(prevProps: AppProps, prevState: AppState) {
//    setState { (count) -> AppState(count = count + 1 ) }
//  }

  override fun render(): Element? {
    val children = mutableListOf<Element>(
        h(::View, "0", ViewProps(
            style = styles.child + styles.red
        )),
        h(::View, "3", ViewProps(
            style = styles.child + styles.red + Style( width = if (state.count % 10 == 0) 60.pt else 80.pt)
        ))
    )
    val toInsert = h(::View, "2", ViewProps(
        style = styles.yellow,
        onPress = { setState { (count) -> AppState(count = count + 1) }}
    )) {
      h(::Text, TextProps(style = Style(color = Color.WHITE))) {
        h(listOf(
            h("Count: "),
            h(::Text, TextProps(style = Style(color = Color.WHITE))) {
              h("${state.count}")
            },
            h(", Click me!")
        ))
      }
    }

    children.add(
        index = if (state.count % 5 == 0) 0 else 1,
        element = toInsert
    )

    return (
      h(::View, ViewProps(style = Style(flex = -1f))) {
        h(::View, ViewProps(style = styles.container + styles.green)) {
          h(children)
        }
      }
    )
  }

  private companion object styles {
    val container = Style(
        flex = -1f,
        flexDirection = YogaFlexDirection.ROW,
        justifyContent = YogaJustify.SPACE_BETWEEN,
        padding = 20.pt,
        maxHeight= 200.pt
    )
    val child = Style(
        width = 80.pt,
        height = 80.pt
    )
    val green = Style(backgroundColor = Color.GREEN)
    val red = Style(backgroundColor = Color.RED)
    val blue = Style(backgroundColor = Color.BLUE)
    val yellow = Style(backgroundColor = Color.YELLOW)
  }
}

