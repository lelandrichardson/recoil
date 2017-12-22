package com.airbnb.android.recoil

interface RecoilInstance {
  var currentElement: Element
  var root: RecoilRoot?
  var view: RecoilView?
  var mountIndex: Int
  fun mountComponent(): RecoilView?
  fun receiveComponent(element: Element)
  fun updateComponent(prevElement: Element, nextElement: Element)
  fun performUpdateIfNecessary()
  fun unmountComponent()
}
