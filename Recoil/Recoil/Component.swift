//
//  Component.swift
//  Recoil
//
//  Created by Leland Richardson on 12/12/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation

protocol ComponentProtocol: class {
  init(props: Any)
  var instance: RecoilCompositeInstance? { get set }
  func setPropsInternal(props: Any)
  func setStateInternal(state: Any)
  func getStateInternal() -> Any
  func componentWillMount()
  func render() -> Element?
  func componentDidMount()
  func componentWillUpdate(nextProps: Any, nextState: Any)
  func componentDidUpdate(prevProps: Any, prevState: Any)
  func componentWillReceiveProps(nextProps: Any)
  func shouldComponentUpdate(nextProps: Any, nextState: Any) -> Bool
  func componentWillUnmount()
}

open class StatelessComponent<Props>: Component<Props, Void> {
  open override func getInitialState() -> Void {
    // do nothing... intentionally
  }
}

open class Component<Props, State>: ComponentProtocol {
  public var props: Props
  public var state: State! // This is gross, but otherwise state would be optional everywhere :/

  // this should probably be weak, but it seems to break when i try that. Instead, we will jut be good about nulling out
  // this reference in unmountComponent...
  var instance: RecoilCompositeInstance?


  // MARK: hacky proxy methods used to work around swift generics issues :(

  public required init(props: Any) {
    if let props = props as? Props {
      self.props = props
      self.state = getInitialState()
    } else {
      fatalError()
    }
  }

  func setPropsInternal(props: Any) {
    if let props = props as? Props {
      self.props = props
    } else {
      fatalError()
    }
  }

  func setStateInternal(state: Any){
    if let state = state as? State {
      self.state = state
    } else {
      fatalError()
    }
  }

  func getStateInternal() -> Any {
    return state
  }

  func componentWillReceiveProps(nextProps: Any) {
    if let nextProps = nextProps as? Props {
      self.componentWillReceiveProps(nextProps: nextProps)
    }
  }

  func componentWillUpdate(nextProps: Any, nextState: Any) {
    if let nextProps = nextProps as? Props, let nextState = nextState as? State {
      self.componentWillUpdate(nextProps: nextProps, nextState: nextState)
    }
  }

  func componentDidUpdate(prevProps: Any, prevState: Any) {
    if let prevProps = prevProps as? Props, let prevState = prevState as? State {
      self.componentDidUpdate(prevProps: prevProps, prevState: prevState)
    }
  }

  func shouldComponentUpdate(nextProps: Any, nextState: Any) -> Bool {
    if let nextProps = nextProps as? Props, let nextState = nextState as? State {
      return self.shouldComponentUpdate(nextProps: nextProps, nextState: nextState)
    } else {
      return true
    }
  }

  public func setState(_ updater: @escaping (State) -> State) {
    setState({ (prevState, _) in updater(prevState) })
  }

  public func setState(_ updater: @escaping (State, Props) -> State) {
    // This is where React would do queueing, storing a series
    // of partialStates. The Updater would apply those in a batch later.
    // This is complicated so we won't do it today. Instead we'll update state
    // and then tell the reconciler this component needs to be updated, synchronously.
    guard let instance = instance else {
      fatalError()
    }

    if let pendingState = instance.pendingState, let prevState = pendingState as? State {
      instance.pendingState = updater(prevState, props)
    } else {
      instance.pendingState = updater(state, props)
    }

    Reconciler.performUpdateIfNecessary(instance: instance)
  }

  open func getInitialState() -> State {
    fatalError("getInitialState() needs to be overridden")
  }

  // MARK: public overridable lifecycle methods
  open func componentWillMount() {

  }

  open func componentDidMount() {

  }

  open func shouldComponentUpdate(nextProps: Props, nextState: State) -> Bool {
    return true
  }

  open func componentWillReceiveProps(nextProps: Props) {

  }

  open func componentWillUpdate(nextProps: Props, nextState: State) {

  }

  open func componentDidUpdate(prevProps: Props, prevState: State) {

  }

  open func componentWillUnmount() {

  }

  open func render() -> Element? {
    fatalError("Render needs to be overridden")
  }
}
