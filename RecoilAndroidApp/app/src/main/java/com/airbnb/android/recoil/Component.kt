package com.airbnb.android.recoil

import android.os.Handler
import android.os.Looper

interface BaseComponent<Props> {
  var props: Props
}

abstract class Component<Props, State>(override var props: Props): BaseComponent<Props> {
  var state: State = getInitialState()
  internal var instance: RecoilCompositeInstance? = null

  internal fun setPropsInternal(props: Any) {
    @Suppress("UNCHECKED_CAST")
    this.props = props as Props
  }
  internal fun setStateInternal(state: Any) {
    @Suppress("UNCHECKED_CAST")
    this.state = state as State
  }
  internal fun getStateInternal(): Any {
    return this.state as Any
  }
  internal fun componentWillUpdateInternal(nextProps: Any, nextState: Any) {
    @Suppress("UNCHECKED_CAST")
    return componentWillUpdate(nextProps as Props, nextState as State)
  }
  internal fun componentDidUpdateInternal(prevProps: Any, prevState: Any) {
    @Suppress("UNCHECKED_CAST")
    return componentDidUpdate(prevProps as Props, prevState as State)
  }
  internal fun componentWillReceivePropsInternal(nextProps: Any) {
    @Suppress("UNCHECKED_CAST")
    return componentWillReceiveProps(nextProps as Props)
  }
  internal fun shouldComponentUpdateInternal(nextProps: Any, nextState: Any): Boolean {
    @Suppress("UNCHECKED_CAST")
    return shouldComponentUpdate(nextProps as Props, nextState as State)
  }
  fun setState(updater: (State) -> State) {
    setState { state, _ -> updater(state) }
  }
  fun setState(updater: (State, Props) -> State) {
    Handler(Looper.getMainLooper()).post {
      val instance = instance ?: throw IllegalStateException()

      @Suppress("UNCHECKED_CAST")
      val pendingState = instance.pendingState as? State ?: state

      instance.pendingState = updater(pendingState, props)
      Reconciler.performUpdateIfNecessary(instance)
    }
  }

  // MARK: public overridable lifecycle methods
  open fun componentWillMount() {}
  open fun componentDidMount() {}
  open fun componentWillUnmount() {}
  open fun shouldComponentUpdate(nextProps: Props, nextState: State): Boolean = true
  open fun componentWillReceiveProps(nextProps: Props) { }
  open fun componentWillUpdate(nextProps: Props, nextState: State) { }
  open fun componentDidUpdate(prevProps: Props, prevState: State) { }

  // MARK: required abstract methods
  abstract fun getInitialState(): State
  abstract fun render(): Element?
}
