package com.airbnb.android.recoil

import kotlin.reflect.KClass

abstract class XComponent<Props>(
  var props: Props
) {
  fun componentWillReceiveProps(nextProps: Props) {

  }
  abstract fun render(): XElement
}

class XElement(
  var type: KClass<*>,
  var props: Any
)

inline fun <reified T: XComponent<P>, P> h(unused: (P) -> T, props: P): XElement = XElement(T::class, props as Any)

data class AppProps(
    val foo: String
)

class App(props: AppProps): XComponent<AppProps>(props) {
  override fun render(): XElement = h(::App, AppProps("abc"))
}


fun make(el: XElement): XComponent<*> {
  val ctor = el.type.constructors.first()
  val instance = ctor.call(el.props)

  if (instance is XComponent<*>) {
    return instance
  } else {
    throw IllegalArgumentException("")
  }
}
