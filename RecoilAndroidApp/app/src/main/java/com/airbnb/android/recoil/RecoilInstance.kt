package com.airbnb.android.recoil

import android.view.ViewGroup


interface RecoilInstance {
  var currentElement: Element
  var root: RecoilRoot?
  var view: ViewGroup?
  var mountIndex: Int
  fun mountComponent(): ViewGroup?
  fun receiveComponent(element: Element)
  fun updateComponent(prevElement: Element, nextElement: Element)
  fun performUpdateIfNecessary()
  fun unmountComponent()
}
