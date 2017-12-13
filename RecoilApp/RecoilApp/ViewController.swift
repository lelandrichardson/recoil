//
//  ViewController.swift
//  RecoilApp
//
//  Created by Leland Richardson on 12/12/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import UIKit
import Recoil

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
  
    let el = h(App.self, AppProps())
  
    Recoil.render(el, view)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}
