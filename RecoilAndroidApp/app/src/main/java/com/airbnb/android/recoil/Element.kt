package com.airbnb.android.recoil

import kotlin.reflect.KClass
import kotlin.reflect.full.isSubclassOf

typealias Key = String

private fun tagFromClass(k: KClass<*>): Tag = when {
  k.isSubclassOf(Component::class) -> Tag.Composite
  k.isSubclassOf(HostComponent::class) -> Tag.Host
  else -> throw IllegalArgumentException("Invalid type found")
}

enum class Tag {
  Composite,
  Host,
  Array,
}

data class Element(
  val tag: Tag,
  val type: KClass<*>,
  val props: Any,
  val key: Key? = null
) {
  constructor(
    type: KClass<*>,
    props: Any,
    key: Key? = null
  ) : this(tagFromClass(type), type, props, key)

  internal fun makeInstance(): Component<*, *> {
    val ctor = type.constructors.first()
    val instance = ctor.call(props)

    return instance as? Component<*, *> ?: throw IllegalArgumentException("")
  }

  internal fun makeHostInstance(): HostComponent<*, *> {
    val ctor = type.constructors.first()
    val instance = ctor.call(props)

    return instance as? HostComponent<*, *> ?: throw IllegalArgumentException("")
  }
}
