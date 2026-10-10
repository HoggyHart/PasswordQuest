//
//  Placeholder.swift
//  PQPrototype
//
//  Created by William Hart on 22/09/2026.
//

import SwiftUI

struct Placeholder: View {
    
    let description: String
    var body: some View {
        ZStack{
            Rectangle().opacity(0.5).border(.black,width: 10)
            Text(description)
        }
    }
}

#Preview {
    Placeholder(description: "Placeholder")
}
