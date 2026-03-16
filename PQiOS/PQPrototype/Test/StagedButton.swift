//
//  StagedButton.swift
//  PQPrototype
//
//  Created by William Hart on 03/02/2026.
//

import SwiftUI

struct StagedButton: View {
    @Environment(\.editMode) private var editMode
    
    @State var choice: Int? = nil
    
    
    var body: some View{
        Picker("choice", selection: $choice){
            ForEach(0..<5){v in
                Text("\(v)").tag(v as Int?)
            }
        }
    }
    
    
    
    
}

#Preview {
    StagedButton()
}
