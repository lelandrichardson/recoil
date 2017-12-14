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
    
}

class App: Component<AppProps> {
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
    return h(View.self, ViewProps()
      .style(styles.container + styles.green)
      .children(h([
        h(View.self, ViewProps()
            .style(styles.child + styles.red)
        ),
        h(View.self, ViewProps()
          .style(styles.child + styles.blue)
        ),
        h(View.self, ViewProps()
          .style(styles.purple)
          .children(h([
            h(Text.self, TextProps()
              .style(Style().color(.white))
              .text("Hello World really long string that might end up wrapping to two or three lines")
            ),
          ]))
        ),
      ]))
    )
  }
}

struct Styles {
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

let styles = Styles()
