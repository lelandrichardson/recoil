package com.airbnb.android.recoil

import android.view.ViewGroup


object Recoil {

  fun render(element: Element, rootView: ViewGroup) {
    val instance = rootView.recoilRoot?.rootInstance
    if (instance != null) {
      updateInstance(element, rootView, instance)
    } else {
      mountInstance(element, rootView)
    }
  }

  fun unmount(rootView: ViewGroup) {
    val instance = rootView.recoilRoot?.rootInstance
    if (instance != null) {
      unmountInstance(instance, rootView)
    } else {
      throw IllegalArgumentException("Must pass in a view with a recoil root")
    }
  }

  private fun mountInstance(element: Element, rootView: ViewGroup) {
    val root = RecoilRoot(rootView)

    rootView.recoilRoot = root

    val instance = Reconciler.instantiateComponent(element, root)

    root.rootInstance = instance

    val view = Reconciler.mountComponent(instance)

    rootView.removeAllViews()

    if (view != null) {
      rootView.addView(view)
    }

    // let yoga do its thing
//    rootView.yoga.isEnabled = true

    // run layout sync
//    rootView.yoga.applyLayout(preservingOrigin: false)
  }

  private fun updateInstance(element: Element, rootView: ViewGroup, instance: RecoilInstance) {

  }

  private fun unmountInstance(instance: RecoilInstance, rootView: ViewGroup) {

  }

}
