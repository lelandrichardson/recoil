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
  func setProps(props: Any)
  func componentWillMount()
  func render() -> Element?
  func componentDidMount()
  func componentWillUpdate(nextProps: Any)
  func componentDidUpdate(prevProps: Any)
  func componentWillReceiveProps(nextProps: Any)
  func shouldComponentUpdate(nextProps: Any) -> Bool
  func componentWillUnmount()
}

open class Component<Props>: ComponentProtocol {
  var props: Props

  // MARK: hacky proxy methods used to work around swift generics issues :(

  public required init(props: Any) {
    if let props = props as? Props {
      self.props = props
    } else {
      fatalError()
    }
  }

  func setProps(props: Any) {
    if let props = props as? Props {
      self.props = props
    } else {
      fatalError()
    }
  }

  func componentWillReceiveProps(nextProps: Any) {
    if let nextProps = nextProps as? Props {
      self.componentWillReceiveProps(nextProps: nextProps)
    }
  }

  func componentWillUpdate(nextProps: Any) {
    if let nextProps = nextProps as? Props {
      self.componentWillUpdate(nextProps: nextProps)
    }
  }

  func componentDidUpdate(prevProps: Any) {
    if let prevProps = prevProps as? Props {
      self.componentDidUpdate(prevProps: prevProps)
    }
  }

  func shouldComponentUpdate(nextProps: Any) -> Bool {
    if let nextProps = nextProps as? Props {
      return self.shouldComponentUpdate(nextProps: nextProps)
    } else {
      return true
    }
  }


  // MARK: public overridable lifecycle methods
  open func componentWillMount() {

  }

  open func componentDidMount() {

  }

  open func shouldComponentUpdate(nextProps: Props) -> Bool {
    return true;
  }

  open func componentWillReceiveProps(nextProps: Props) {

  }

  open func componentWillUpdate(nextProps: Props) {

  }

  open func componentWillUnmount() {

  }

  open func render() -> Element? {
    fatalError("Render needs to be overridden")
  }
}
