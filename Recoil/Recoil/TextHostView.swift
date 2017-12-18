//
//  TextHostView.swift
//  Recoil
//
//  Created by Leland Richardson on 12/13/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation

private protocol TextFriendlyView {}

extension TextLiteralHostView: TextFriendlyView {}

public class TextHostView: UILabel, TextFriendlyView {

  private var children: [TextFriendlyView] = []
  func updateTextIfNeeded() {
    var result = ""
    for view in children {
      if let view = view as? TextLiteralHostView {
        result += view.text ?? ""
      } else if let view = view as? TextHostView {
        view.updateTextIfNeeded()
        result += view.text ?? ""
      } else {
        //TODO: fail more gracefully
        fatalError()
      }
    }
    if result != text {
      text = result
      self.yoga.markDirty()
    }
  }

  override func insertRecoilSubview(_ view: UIView, at index: Int) {
    if let view = view as? TextLiteralHostView {
      children.insert(view, at: index)
    } else if let view = view as? TextHostView {
      children.insert(view, at: index)
    } else {
      //TODO: fail more gracefully
      fatalError()
    }
  }

  override func moveRecoilSubview(from fromIndex: Int, to toIndex: Int) {
    let view = children.remove(at: fromIndex)
    if let view = view as? TextLiteralHostView {
      children.insert(view, at: toIndex)
    } else if let view = view as? TextHostView {
      children.insert(view, at: toIndex)
    } else {
      //TODO: fail more gracefully
      fatalError()
    }
  }

  override func removeRecoilSubview(from fromIndex: Int) {
    children.remove(at: fromIndex)
  }
}
