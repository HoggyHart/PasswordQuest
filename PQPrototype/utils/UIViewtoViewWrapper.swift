//
//  WrapperView.swift
//  PasswordQuest
//
//  Created by William Hart on 27/07/2025.
//

import UIKit
import SwiftUI

struct UIViewToViewWrapper<V: UIView>: UIViewRepresentable {
  typealias UIViewType = V

  var view: V
 
  init(view: V) {
    self.view = view
  }
 
  func makeUIView(context: Context) -> V {
    return view
  }
 
  func updateUIView(_ uiView: V, context: Context) {}
}
