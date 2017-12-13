//
//  Component.swift
//  Recoil
//
//  Created by Leland Richardson on 12/12/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation

protocol ComponentProtocol {
  init(props: Any)
  func componentWillReceiveProps(nextProps: Any)
  func render() -> Element?
}

open class Component<Props>: ComponentProtocol {
  let props: Props

  public required init(props: Any) {
    if let props = props as? Props {
      self.props = props
    } else {
      fatalError()
    }
  }

  func componentWillMount() {

  }

  func componentDidMount() {

  }

  func shouldComponentUpdate(nextProps: Props) -> Bool {
    return true;
  }

  func componentWillReceiveProps(nextProps: Any) {
    if let nextProps = nextProps as? Props {
      self.componentWillReceiveProps(nextProps: nextProps)
    }
  }
  func componentWillReceiveProps(nextProps: Props) {

  }

  func componentDidUpdate() {

  }

  func componentWillUnmount() {

  }

  open func render() -> Element? {
    fatalError("Render needs to be overridden")
  }
}
