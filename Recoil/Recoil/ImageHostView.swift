//
//  ImageHostView.swift
//  Recoil
//
//  Created by Leland Richardson on 12/15/17.
//  Copyright © 2017 Leland Richardson. All rights reserved.
//

import Foundation

func downloadImage(url: String, _ callback: @escaping (UIImage) -> Void) {
  guard let url = URL(string: url) else { return }
  URLSession.shared.dataTask(with: url) { (data, response, error)  in
    DispatchQueue.main.async {
      guard
        let data = data,
        error == nil,
        let image = UIImage(data: data) else { return }
      callback(image)
    }
  }.resume()
}


public class ImageHostView: UIImageView {
  var source: ImageSource? {
    didSet {
      if let source = source {
        downloadImage(url: source.url) { image in
          self.image = image
        }
      } else {
        self.image = nil
      }
    }
  }
}
