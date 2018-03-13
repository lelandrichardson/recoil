package com.airbnb.android.recoilandroidapp

import android.content.Context
import com.airbnb.android.recoil.*

data class ButtonProps(
  val title: String,
  val onPress: () -> String
)

class Button(props: ButtonProps): StatelessComponent<ButtonProps>(props) {
  override fun render(): Element? {
    return (
      h(::View, ViewProps(
        onPress = props.onPress
      )) {
        h(props.title)
      }
    )
  }
}


class Button(props: ButtonProps): StatelessComponent<ButtonProps>(props) {
  fun render2(): Int {
    val foo = ButtonProps(
        title = "what",
        onPress = { "abc" }
    )
    arrayListOf(1, 2, 3).map {  }
    return (
      <Foo
        title=(foo)
        onPress={ 123 }
      >
      </Foo>
    )

    return h(::Foo, FooProps(

    ))
  }
}



abstract class HostComponent<TProps, TView: View>(var props: TProps) {

  abstract fun mountComponent(context: Context): TView

  abstract fun updateComponent(view: TView, prevProps: TProps)

  abstract fun renderChildren(): Element?
}
