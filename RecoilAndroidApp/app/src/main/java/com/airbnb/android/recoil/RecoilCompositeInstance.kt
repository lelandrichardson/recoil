package com.airbnb.android.recoil

import android.view.ViewGroup


class RecoilCompositeInstance(
  override var currentElement: Element,
  override var root: RecoilRoot?
): RecoilInstance {
  override var view: ViewGroup? = null
  override var mountIndex: Int = -1
  var pendingState: Any? = null
  var component: Component<*, *>? = null
  var renderedComponent: RecoilInstance? = null

  override fun mountComponent(): ViewGroup? {
    // This is where the magic starts to happen. We call the render method to
    // get our actual rendered element. Note: since we (and React) don't support
    // Arrays or other types, we can safely assume we have an element.
    val component = currentElement.makeInstance()
    this.component = component
    component.instance = this

    component.componentWillMount()

    val renderedElement = component.render()
    if (renderedElement == null) {
      component.componentDidMount()
      this.renderedComponent = null
      this.view = null
      return null
    }

    // Actually instantiate the rendered element.
    val renderedComponent = Reconciler.instantiateComponent(renderedElement, root)

    this.renderedComponent = renderedComponent

    // Generate views for the child & effectively recurse!
    // Since CompositeComponents instances don't have a view representation of
    // their own, this markup will actually be the views of the components they
    // render
    val view = Reconciler.mountComponent(renderedComponent)
    this.view = view

    component.componentDidMount()

    // React doesn't store this reference, instead working through a shared
    // interface for storing host nodes, allowing this to work across platforms.
    // We'll take a shortcut.
    // this._renderedNode = markup;

    return view
  }

  override fun receiveComponent(element: Element) {
    return updateComponent(currentElement, element)
  }

  override fun updateComponent(prevElement: Element, nextElement: Element) {
    val component = this.component ?: throw IllegalStateException("")
    val renderedComponent = this.renderedComponent

    // Update instance data
    if (prevElement != nextElement) {
      component.componentWillReceivePropsInternal(nextElement.props)
    }

    val prevState = component.getStateInternal()
    val nextState = pendingState ?: prevState

    // React would call shouldComponentUpdate here and short circuit.
    val shouldUpdate = component.shouldComponentUpdateInternal(nextElement.props, nextState)

    if (!shouldUpdate) {
      return
    }

    // React would call componentWillUpdate here
    component.componentWillUpdateInternal(nextElement.props, nextState)

    currentElement = nextElement

    component.setPropsInternal(currentElement.props)
    component.setStateInternal(nextState)
    pendingState = null

    // React has a wrapper instance, which complicates the logic. We'll do
    // something simplified here.
    val prevRenderedElement = renderedComponent?.currentElement
    val nextRenderedElement = component.render()

    // We check if we're going to update the existing rendered element or if
    // we need to blow away the child tree and start over.
    if (
      renderedComponent != null &&
      nextRenderedElement != null &&
      Reconciler.shouldUpdateComponent(prevRenderedElement, nextRenderedElement)
    ) {
      Reconciler.receiveComponent(renderedComponent, nextRenderedElement)

      component.componentDidUpdateInternal(prevElement.props, prevState)

    } else {
      // Blow away and start over - it's similar to mounting.
      // We don't actually need this logic for our example but we'll write it.
      if (renderedComponent == null) {
        // TODO(lmr): i'm not quite sure what i should do here...
        throw IllegalStateException("")
      }

      val prevRenderedView = renderedComponent.view
      Reconciler.unmountComponent(renderedComponent)

      // TODO: androidify this
      val parentView = prevRenderedView?.parent as? ViewGroup ?: throw IllegalStateException("")
      prevRenderedView.removeView(prevRenderedView)

      if (nextRenderedElement != null) {
        val nextRenderedComponent = Reconciler.instantiateComponent(nextRenderedElement, root)
        val nextView = Reconciler.mountComponent(nextRenderedComponent)

        component.componentDidMount()

        if (nextView != null) {
          parentView.insertRecoilSubview(nextView, renderedComponent.mountIndex)
        }

        this.renderedComponent = nextRenderedComponent
        view = nextView
      }
    }
  }

  override fun performUpdateIfNecessary() {
    // React handles batching so could potentially have to handle a case of a
    // state update or a new element being rendered. We just need to handle
    // state updates.
    updateComponent(currentElement, currentElement)
  }

  override fun unmountComponent() {
    val renderedComponent = renderedComponent ?: return

    // unmount
    component?.componentWillUnmount()
    Reconciler.unmountComponent(renderedComponent)

    // clean up references for ARC
    component?.instance = null
    view = null
  }
}
