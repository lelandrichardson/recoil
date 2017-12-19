package com.airbnb.android.recoil

interface BaseComponent<Props> {
  var props: Props
}

abstract class Component<Props, State>(override var props: Props): BaseComponent<Props> {
  var state: State = getInitialState()
  var instance: RecoilCompositeInstance? = null

  fun setPropsInternal(props: Any) {
    @Suppress("UNCHECKED_CAST")
    this.props = props as Props
  }
  fun setStateInternal(state: Any) {
    @Suppress("UNCHECKED_CAST")
    this.state = state as State
  }
  fun getStateInternal(): Any {
    return this.props as Any
  }
  fun componentWillUpdateInternal(nextProps: Any, nextState: Any) {
    @Suppress("UNCHECKED_CAST")
    return componentWillUpdate(nextProps as Props, nextState as State)
  }
  fun componentDidUpdateInternal(prevProps: Any, prevState: Any) {
    @Suppress("UNCHECKED_CAST")
    return componentDidUpdate(prevProps as Props, prevState as State)
  }
  fun componentWillReceivePropsInternal(nextProps: Any) {
    @Suppress("UNCHECKED_CAST")
    return componentWillReceiveProps(nextProps as Props)
  }
  fun shouldComponentUpdateInternal(nextProps: Any, nextState: Any): Boolean {
    @Suppress("UNCHECKED_CAST")
    return shouldComponentUpdate(nextProps as Props, nextState as State)
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
