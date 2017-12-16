//
//  FunctionalApp.swift
//  RecoilApp
//
//  Created by Leland Richardson on 12/15/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation
import Recoil


func FunctionalComponent(props: (foo: String, bar: Int)) -> Element? {
  return h(View.self, key: 2, ViewProps()
    .style(styles.purple)
    .children(h([
      h(Text.self, TextProps()
        .style(Style().color(.white))
        .text("Count: \(props.foo), Click me!")
      ),
    ]))
  )
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
