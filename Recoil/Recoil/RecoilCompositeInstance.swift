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
  var mountIndex: Int = -1
  var componentElement: ComponentElement
  var component: ComponentProtocol?
  var renderedComponent: RecoilInstance?

  init(element: Element) {
    currentElement = element
    componentElement = getComponentElement(element)
  }

  func mountComponent() -> UIView? {
    // This is where the magic starts to happen. We call the render method to
    // get our actual rendered element. Note: since we (and React) don't support
    // Arrays or other types, we can safely assume we have an element.
    let component = componentElement.type.init(props: componentElement.props)
    self.component = component

    guard let renderedElement = component.render() else {
      self.renderedComponent = nil
      self.view = nil
      return nil
    }

    // TODO: lifecycle methods: compnentWillMount

    // Actually instantiate the rendered element.
    let renderedComponent = Reconciler.instantiateComponent(renderedElement)

    self.renderedComponent = renderedComponent

    // Generate views for the child & effectively recurse!
    // Since CompositeComponents instances don't have a view representation of
    // their own, this markup will actually be the views of the components they
    // render
    let view = Reconciler.mountComponent(instance: renderedComponent)
    self.view = view

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
    // NOTE(lmr): there might be a valid reason for this to be null, but im not sure...
//    guard let renderedComponent = renderedComponent else {
//      fatalError()
//    }
    // This is a props updates due to a re-render from the parent.
//    TODO(lmr):
//    if prevElement !== nextElement {
      // React would call componentWillReceiveProps here
//    }

    // Update instance data


    let nextComponentElement = getComponentElement(nextElement)

    // React would call shouldComponentUpdate here and short circuit.
    let shouldUpdate = component.shouldComponentUpdate(nextProps: nextComponentElement.props)

    if !shouldUpdate {
      return
    }

    // React would call componentWillUpdate here
    component.componentWillUpdate(nextProps: nextComponentElement.props)

    currentElement = nextElement

    component.setProps(props: componentElement.props)
    // TODO(lmr):
//    this.state = this._pendingState;
//    this._pendingState = null;

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
        let nextRenderedComponent = Reconciler.instantiateComponent(nextRenderedElement)
        let nextView = Reconciler.mountComponent(instance: nextRenderedComponent)

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

    component?.componentWillUnmount()

    Reconciler.unmountComponent(instance: renderedComponent)

    view = nil
  }
}
