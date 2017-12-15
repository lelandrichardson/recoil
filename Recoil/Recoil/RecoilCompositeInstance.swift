//
//  RecoilCompositeInstance.swift
//  Recoil
//
//  Created by Leland Richardson on 12/14/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation

func getComponentElement(_ element: Element) -> ComponentElement {
  switch element {
  case .component(let hostElement):
    return hostElement
  default:
    fatalError()
  }
}

class RecoilCompositeInstance: RecoilInstance {
  var currentElement: Element {
    didSet {
      componentElement = getComponentElement(currentElement)
    }
  }
  var view: UIView?
  var root: RecoilRoot?
  var mountIndex: Int = -1
  var componentElement: ComponentElement
  var pendingState: Any?
  var component: ComponentProtocol?
  var renderedComponent: RecoilInstance?

  init(element: Element, root: RecoilRoot?) {
    currentElement = element
    componentElement = getComponentElement(element)
    self.root = root
  }

  func mountComponent() -> UIView? {
    // This is where the magic starts to happen. We call the render method to
    // get our actual rendered element. Note: since we (and React) don't support
    // Arrays or other types, we can safely assume we have an element.
    let component = componentElement.type.init(props: componentElement.props)
    self.component = component
    component.instance = self

    component.componentWillMount()

    guard let renderedElement = component.render() else {
      component.componentDidMount()
      self.renderedComponent = nil
      self.view = nil
      return nil
    }

    // Actually instantiate the rendered element.
    let renderedComponent = Reconciler.instantiateComponent(element: renderedElement, root: root)

    self.renderedComponent = renderedComponent

    // Generate views for the child & effectively recurse!
    // Since CompositeComponents instances don't have a view representation of
    // their own, this markup will actually be the views of the components they
    // render
    let view = Reconciler.mountComponent(instance: renderedComponent)
    self.view = view

    component.componentDidMount()

    // React doesn't store this reference, instead working through a shared
    // interface for storing host nodes, allowing this to work across platforms.
    // We'll take a shortcut.
    // this._renderedNode = markup;

    return view
  }

  func receiveComponent(element: Element) {
    return updateComponent(from: currentElement, to: element)
  }

  func updateComponent(from prevElement: Element, to nextElement: Element) {
    guard let component = component else {
      fatalError()
    }
    // Update instance data
    let prevComponentElement = componentElement
    let nextComponentElement = getComponentElement(nextElement)

    if prevComponentElement != nextComponentElement {
      component.componentWillReceiveProps(nextProps: nextComponentElement.props)
    }

    let prevState = component.getStateInternal()
    let nextState = pendingState ?? prevState

    // React would call shouldComponentUpdate here and short circuit.
    let shouldUpdate = component.shouldComponentUpdate(nextProps: nextComponentElement.props, nextState: nextState)

    if !shouldUpdate {
      return
    }

    // React would call componentWillUpdate here
    component.componentWillUpdate(nextProps: nextComponentElement.props, nextState: nextState)

    currentElement = nextElement

    component.setPropsInternal(props: componentElement.props)
    component.setStateInternal(state: nextState)
    pendingState = nil

    // React has a wrapper instance, which complicates the logic. We'll do
    // something simplified here.
    let prevRenderedElement = renderedComponent?.currentElement
    let nextRenderedElement = component.render()

    // We check if we're going to update the existing rendered element or if
    // we need to blow away the child tree and start over.
    if
      let renderedComponent = renderedComponent,
      let nextRenderedElement = nextRenderedElement,
      Reconciler.shouldUpdateComponent(prev: prevRenderedElement, next: nextRenderedElement) {

      Reconciler.receiveComponent(instance: renderedComponent, element: nextRenderedElement)

      component.componentDidUpdate(prevProps: prevComponentElement.props, prevState: prevState)

    } else {
      // Blow away and start over - it's similar to mounting.
      // We don't actually need this logic for our example but we'll write it.
      guard let renderedComponent = renderedComponent else {
        // TODO(lmr): i'm not quite sure what i should do here...
        fatalError()
      }

      let prevRenderedView = renderedComponent.view
      Reconciler.unmountComponent(instance: renderedComponent)
      guard let parentView = prevRenderedView?.superview else {
        fatalError()
      }
      prevRenderedView?.removeFromSuperview()

      if let nextRenderedElement = nextRenderedElement {
        let nextRenderedComponent = Reconciler.instantiateComponent(element: nextRenderedElement, root: root)
        let nextView = Reconciler.mountComponent(instance: nextRenderedComponent)

        component.componentDidMount()

        if let nextView = nextView {
          parentView.insertSubview(nextView, at: renderedComponent.mountIndex)
        }

        self.renderedComponent = nextRenderedComponent
        view = nextView
      }
    }
  }

  func performUpdateIfNecessary() {
    // React handles batching so could potentially have to handle a case of a
    // state update or a new element being rendered. We just need to handle
    // state updates.
    updateComponent(from: currentElement, to: currentElement);
  }

  func unmountComponent() {
    guard let renderedComponent = renderedComponent else {
      return
    }

    // unmount
    component?.componentWillUnmount()
    Reconciler.unmountComponent(instance: renderedComponent)

    // clean up references for ARC
    component?.instance = nil
    view = nil
  }
}
