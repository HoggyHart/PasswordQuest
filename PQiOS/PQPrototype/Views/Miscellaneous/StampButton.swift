//
//  StampButton.swift
//  PQPrototype
//
//  Created by William Hart on 22/10/2026.
//

import SwiftUI

struct MultiStateButton: View {
    @State private var text: String = ""
    var body: some View {
        Button(){
            text = "Stamped"
        } label: {
            Text(text)
            Rectangle()
            .padding()
            .frame(width: 120,height:120)
            .foregroundColor(.red)
            .background(.green)
            .cornerRadius(10)
        }
        //.disabled(currentState == .stamping)
        .buttonStyle(ButtonStampAnimationStyle())
    //    .buttonStyle(DefaultButtonStyle())
    }
}

#Preview {
    MultiStateButton()
}
