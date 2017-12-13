//
//  Recoil.swift
//  Recoil
//
//  Created by Leland Richardson on 12/12/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation


func mount(into view: UIView, element: Element) {
  switch element {
  case .string(let value):
    mount(into: view, string: value)
  case .component(let componentElement):
    mount(into: view, component: componentElement)
  case .host(let hostElement):
    mount(into: view, hostElement: hostElement)
  case .array(let elements):
    for element in elements {
      if let element = element {
        mount(into: view, element: element)
      }
    }
  default:
    fatalError("unknown element enum encountered")
  }
}

func mount(into container: UIView, string: String) {
  let label = UILabel()
  label.text = string
  container.addSubview(label)
}

func mount(into container: UIView, component: ComponentElement) {
  let instance = component.type.init(props: component.props)
  if let renderedElement = instance.render() {
    mount(into: container, element: renderedElement)
  }
}

func mount(into container: UIView, hostElement: HostElement) {
  let instance = hostElement.type.init(props: hostElement.props)
  let view = instance.mountComponent(into: container)
  if let children = instance.renderChildren() {
    mount(into: view, element: children)
  }
}

public class Recoil {
  public static func render(_ element: Element, _ rootView: UIView) {
    mount(into: rootView, element: element)
    rootView.yoga.isEnabled = true
    rootView.yoga.applyLayout(preservingOrigin: false)
  }
//
//    static func getView(instance: Component<Any>) -> UIView? {
//        return nil
//    }
}
