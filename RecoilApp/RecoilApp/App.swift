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
    setState { state in
      return AppState(count: state.count + 1 )
    }
  }
  override func render() -> Element? {
    var children = [
      h(Image.self, key: 0, ImageProps()
        .style(styles.child + styles.red + styles.transform)
        .source("https://unsplash.it/80/80?image=456")
      ),
      h(View.self, key: 1, ViewProps()
        .style(styles.child + styles.red + Style().width(state.count % 10 == 0 ? 60 : 80))
      ),
    ]
    let toInsert = h(View.self, key: 2, ViewProps()
      .style(styles.yellow)
      .onPress { [weak self] in
        self?.setState { state in
          return AppState(count: state.count + 1 )
        }
      }
    ) {[
      h(Text.self, TextProps()) {[
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
    .width(80)
    .height(80)
  let transform = Style()
    .transform([
      .rotateZ(30, .deg),
    ])
  let green = Style().backgroundColor(.uiColor(.green))
  let red = Style().backgroundColor(.uiColor(.red))
  let yellow = Style().backgroundColor(.uiColor(.yellow))
}

private let styles = Styles()
