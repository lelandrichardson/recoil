//
//  RecoilCompositeInstance.swift
//  Recoil
//
//  Created by Leland Richardson on 12/14/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation

func getFunctionalElement(_ element: Element) -> FunctionalElement {
  switch element {
  case .function(let functionalElement):
    return functionalElement
  default:
    fatalError()
  }
}

class RecoilFunctionalInstance: RecoilInstance {
  var currentElement: Element {
    didSet {
      functionalElement = getFunctionalElement(currentElement)
    }
  }
  var view: UIView?
  var root: RecoilRoot?
  var mountIndex: Int = -1
  var functionalElement: FunctionalElement
  var renderedComponent: RecoilInstance?

  init(element: Element, root: RecoilRoot?) {
    currentElement = element
    functionalElement = getFunctionalElement(element)
    self.root = root
  }

  func mountComponent() -> UIView? {
    guard let renderedElement = functionalElement.type(functionalElement.props) else {
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

    return view
  }

  func receiveComponent(element: Element) {
    return updateComponent(from: currentElement, to: element)
  }

  func updateComponent(from prevElement: Element, to nextElement: Element) {

    currentElement = nextElement

    // React has a wrapper instance, which complicates the logic. We'll do
    // something simplified here.
    let prevRenderedElement = renderedComponent?.currentElement
    let nextRenderedElement = functionalElement.type(functionalElement.props)

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
        let nextRenderedComponent = Reconciler.instantiateComponent(element: nextRenderedElement, root: root)
        let nextView = Reconciler.mountComponent(instance: nextRenderedComponent)

        if let nextView = nextView {
          parentView.insertRecoilSubview(nextView, at: renderedComponent.mountIndex)
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
    Reconciler.unmountComponent(instance: renderedComponent)

    // clean up references for ARC
    view = nil
  }
}

