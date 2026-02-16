//
//  StagedButton.swift
//  PQPrototype
//
//  Created by William Hart on 03/02/2026.
//

import SwiftUI

struct StagedButton: View {
    @Environment(\.editMode) private var editMode
    
    private var editing: Bool { get { return  editMode!.wrappedValue.isEditing }}
    
    var body: some View{
        Rectangle()
            .foregroundColor(editing ? .green : .red)
        EditButton()
    }
    
    
    
    
}

#Preview {
    StagedButton()
}
