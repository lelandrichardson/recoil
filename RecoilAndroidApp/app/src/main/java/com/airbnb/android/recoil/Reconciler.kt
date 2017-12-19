package com.airbnb.android.recoil

import android.view.ViewGroup

object Reconciler {
  fun instantiateComponent(element: Element, root: RecoilRoot?): RecoilInstance {
    return when (element.tag) {
      Tag.Host -> RecoilHostInstance(element, root)
      Tag.Composite -> RecoilCompositeInstance(element, root)
      // TODO(lmr): Tag.Function
      else -> throw IllegalArgumentException("Unexpected element tag")
    }
  }

  fun mountComponent(instance: RecoilInstance): ViewGroup? {
    val view = instance.mountComponent()

    // React does more work here to ensure that refs work. We don't need to yet.
    return view
  }

  fun receiveComponent(instance: RecoilInstance, element: Element) {
    // Shortcut! We won't do anythign if the next element is the same as the
    // current one. This is unlikely in normal JSX usage, but it an optimization
    // that can be unlocked with Babel's inline-element transform.

    val prevElement = instance.currentElement;
    if (prevElement == element) {
      return
    }

    // Defer to the instance.
    instance.receiveComponent(element)
  }

  fun performUpdateIfNecessary(instance: RecoilInstance) {
    instance.performUpdateIfNecessary()
  }

  fun shouldUpdateComponent(prev: Element?, next: Element?): Boolean {
    // if either are nil, return false
    if (prev == null || next == null) {
      return false
    }

    // TODO: deal with key!
    // TODO: deal with strings/literals???

    if (prev.tag != next.tag) {
      return false
    }

    // TODO: come back to this and write a more complete version
    return when (prev.tag) {
      Tag.Host, Tag.Composite -> prev.type == next.type
      else -> false
    }
  }

  fun unmountComponent(instance: RecoilInstance) {
    // Again, React will do more work here to detach refs. We won't.
    // We'll also continue deferring to the instance to do the real work.
    instance.unmountComponent()
  }
}
