//
//  TextLiteral.swift
//  Recoil
//
//  Created by Leland Richardson on 12/16/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation

import Foundation
import UIKit
import YogaKit

final public class TextLiteral: HostComponent<String, TextLiteralHostView> {
  override public func mountComponent() -> TextLiteralHostView {
    let view = TextLiteralHostView()
    view.text = props
    return view
  }

  override public func updateComponent(view: TextLiteralHostView, prevProps: String) {
    view.text = props
  }

  override public func renderChildren() -> Element? {
    return nil
  }
}

