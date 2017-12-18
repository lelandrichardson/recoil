//
//  App.swift
//  RecoilApp
//
//  Created by Leland Richardson on 12/12/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

// NOTE:
// This is essentially a line-for-line port of RCTBorderDrawing.m from React Native

import Foundation
import Recoil
import YogaKit

struct AppProps {
  let foo: String
}

struct AppState {
  let count: Int
}

class App: Component<AppProps, AppState> {
  override func getInitialState() -> AppState {
    return AppState(count: 1)
  }
  override func componentDidMount() {
//    setState { state in
//      return AppState(count: state.count + 1 )
//    }
  }
  override func componentDidUpdate(prevProps: AppProps, prevState: AppState) {
//    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//      self.setState { state in
//        return AppState(count: state.count + 1 )
//      }
//    }
  }

  func increment() {
    setState { state in
      return AppState(count: state.count + 1 )
    }
  }

  override func render() -> Element? {
    /*
    <View style={styles.container}>
      <View style={styles.child} />
      <View style={styles.child} />
      <View style={styles.child}>
        <Text>Hello world {state.count}!</Text>
      </View>
    </View>
    */

    /*

     return h(View.self, ViewProps().style(styles.container)) {[
       h(View.self, ViewProps().style(styles.child)),
       h(View.self, ViewProps().style(styles.child)),
       h(View.self, ViewProps().style(styles.child)) {
         h(Text.self, TextProps()) {[
           h("Hello world "),
           h(state.count),
           h("!"),
         ]},
       },
     ]}

     */

    var children = [
      h(Image.self, key: 0, ImageProps()
        .style(styles.child + styles.red)
        .source("https://unsplash.it/80/80?image=123")
      ),
      h(View.self, key: 1, ViewProps()
        .style(styles.child + Style().width(state.count % 10 == 0 ? 60 : 80))
      ),
    ]

    let toInsert = h(View.self, key: 2, ViewProps()
      .style(styles.purple)
      .onPress({ [weak self] in
        self?.setState { state in
          return AppState(count: state.count + 1 )
        }
      })
    ) {[
      h(Text.self, TextProps().style(Style().color(.white))) {[
        h("Count: "),
        h(Text.self, TextProps()) {
          h(self.state.count)
        },
        h(", Click me!"),
      ]},
    ]}

    children.insert(toInsert, at: state.count % 5 == 0 ? 0 : 1)

    return h(View.self, ViewProps().style(styles.container + styles.green)) { children }
  }
}

private struct Styles {
  let container = Style()
    .padding(20)
    .flexDirection(.row)
    .justifyContent(.spaceBetween)
  let child = Style()
    .width(60)
    .height(60)
    .borderWidth(2)
    .borderLeftWidth(20)
    .borderLeftColor(.white)
    .borderColor(.black)
    .borderStyle(.solid)
    .backgroundColor(.clear)
  let green = Style().backgroundColor(.uiColor(UIColor.green))
  let red = Style().backgroundColor(.uiColor(UIColor.red))
  let blue = Style().backgroundColor(.uiColor(UIColor.blue))
  let purple = Style().backgroundColor(.uiColor(UIColor.purple))
}

private let styles = Styles()
