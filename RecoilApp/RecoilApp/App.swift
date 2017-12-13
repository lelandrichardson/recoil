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
    return h(View.self, ViewProps()
      .style(styles.container)
      .children(h([
        h(View.self, ViewProps()
          .style(styles.child)
        ),
        h(View.self, ViewProps()
          .style(styles.child)
        ),
        h(View.self, ViewProps()
          .style(styles.child)
        )
      ]))
    )
  }
}

struct Styles {
  let container = Style()
    .padding(20)
    .backgroundColor(.uiColor(UIColor.green))
    .flexDirection(.row)
    .justifyContent(.spaceBetween)
  let child = Style()
    .backgroundColor(.uiColor(UIColor.red))
    .height(100)
    .width(100)
}

let styles = Styles()
