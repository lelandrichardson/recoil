//
//  App.swift
//  RecoilApp
//
//  Created by Leland Richardson on 12/12/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

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
        <Text text="Hello World" />
      </View>
    </View>
    */

    var children = [
      h(Image.self, key: 0, ImageProps()
        .style(styles.child + styles.red)
        .source("https://unsplash.it/80/80?image=123")
      ),
      h(View.self, key: 1, ViewProps()
        .style(styles.child + styles.blue + Style().width(state.count % 10 == 0 ? 60 : 80))
      ),
    ]

    children.insert(
      h(View.self, key: 2, ViewProps()
      .style(styles.purple)
      .onPress({ [weak self] in
        self?.setState { state in
          return AppState(count: state.count + 1 )
        }
      })
      .children(h([
        h(Text.self, TextProps()
          .style(Style().color(.white))
          .text("Count: \(state.count), Click me!")
        ),
      ]))
    ), at: state.count % 5 == 0 ? 0 : 1)

    return h(View.self, ViewProps()
      .style(styles.container + styles.green)
      .children(h(children))
    )
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
  let green = Style().backgroundColor(.uiColor(UIColor.green))
  let red = Style().backgroundColor(.uiColor(UIColor.red))
  let blue = Style().backgroundColor(.uiColor(UIColor.blue))
  let purple = Style().backgroundColor(.uiColor(UIColor.purple))
}

private let styles = Styles()
