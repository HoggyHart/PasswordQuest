//
//  Checkbox.swift
//  PasswordQuest
//
//  Created by William Hart on 20/08/2025.
//

import SwiftUI

struct Checkbox: View {
    var size: CGFloat = 30
    var ticked: Binding<Bool>
    @State var checked = false
    var body: some View {
        ZStack{
            Rectangle()
                .border(/*@START_MENU_TOKEN@*/Color.black/*@END_MENU_TOKEN@*/)
                .foregroundColor(.white)
            Circle().foregroundColor(.black).opacity(checked ? 1 : 0)
            Button(){
                check()
            } label: { Rectangle().opacity(0)
            }
            
        }
        .frame(width: size, height: size)
        
    }
    
    func check(){
        checked.toggle()
        ticked.wrappedValue = checked
    }
}

#Preview {
    @State var b = false
    return Checkbox(ticked: $b)
}
