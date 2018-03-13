//
//  View.swift
//  Recoil
//
//  Created by Leland Richardson on 12/12/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation
import UIKit
import YogaKit


protocol HostComponent {
  associatedtype TProps
  associatedtype TView: UIView

  func mountComponent() -> TView

  func updateComponent(view: TView, prevProps: TProps)

  func renderChildren() -> Element?
}

class HostComponent<Props, View: UIView> {
  var props: Props

  func mountComponent() -> View {

  }

  func updateComponent(view: View, prevProps: Props) {

  }

  func renderChildren() -> Element? {

  }
}


class CustomComponent: HostComponent<Props, View> {
  override public func mountComponent() -> View {

  }

  override public func updateComponent(view: View, prevProps: Props) {

  }

  override public func renderChildren() -> Element? {

  }
}

