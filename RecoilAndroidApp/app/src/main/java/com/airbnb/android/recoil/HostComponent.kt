package com.airbnb.android.recoil

import android.content.Context
import android.view.ViewGroup

abstract class HostComponent<Props, ViewType: ViewGroup>(override var props: Props): BaseComponent<Props> {
  internal fun setPropsInternal(props: Any) {
    @Suppress("UNCHECKED_CAST")
    this.props = props as Props
  }

  fun mountComponentInternal(context: Context): ViewGroup {
    return mountComponent(context)
  }

  fun updateComponentInternal(view: ViewGroup, prevProps: Any) {
    @Suppress("UNCHECKED_CAST")
    updateComponent(view as ViewType, prevProps as Props)
  }

  fun childrenDidUpdateInternal(view: ViewGroup, prevProps: Any) {
    @Suppress("UNCHECKED_CAST")
    childrenDidUpdate(view as ViewType, prevProps as Props)
  }

  fun childrenDidMountInternal(view: ViewGroup) {
    @Suppress("UNCHECKED_CAST")
    childrenDidMount(view as ViewType)
  }


  abstract fun mountComponent(context: Context): ViewType
  abstract fun updateComponent(view: ViewType, prevProps: Props)

  open fun renderChildren(): Element? {
    return null
  }

  open fun childrenDidMount(view: ViewType) {

  }

  open fun childrenDidUpdate(view: ViewType, prevProps: Props) {

  }

}
