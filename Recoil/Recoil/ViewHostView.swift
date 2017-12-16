//
//  ViewHostView.swift
//  Recoil
//
//  Created by Leland Richardson on 12/13/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation


public class ViewHostView: UIView {
  private var tap: UITapGestureRecognizer? = nil
  var onPress: (() -> ())? = nil {
    didSet {
      // TODO: clean this up!
      if self.tap == nil {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleOnPress(_:)))
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(tap)
        self.tap = tap
      }
    }
  }

  @objc
  func handleOnPress(_ sender: UITapGestureRecognizer) {
    if let onPress = self.onPress {
      onPress()
    }
  }

  /*
   TODO:
   - border
   - border radii
   - transforms

   */
}

