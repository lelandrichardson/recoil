package com.airbnb.android.recoil

interface ChildrenProps {
  var children: Element?
}

inline fun <reified T: BaseComponent<P>, P: Any> h(type: (P) -> T, props: P): Element = Element(T::class, props)
inline fun <reified T: BaseComponent<P>, P: Any> h(type: (P) -> T, key: Key, props: P): Element = Element(T::class, props, key)
inline fun <reified T: BaseComponent<P>, P: ChildrenProps> h(type: (P) -> T, props: P, vararg children: Element?): Element {
  props.children = Element(Tag.Array, children::class, children)
  return Element(T::class, props)
}
inline fun <reified T: BaseComponent<P>, P: ChildrenProps> h(type: (P) -> T, key: Key, props: P, vararg children: Element?): Element {
  props.children = Element(Tag.Array, children::class, children)
  return Element(T::class, props, key)
}
inline fun h(string: String) = Element(TextLiteralComponent::class, string)

inline fun <T> h(elements: Array<T>) = Element(Tag.Array, Array<Element?>::class, elements, null)
