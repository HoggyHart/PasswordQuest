//
//  TwoHeadedSlider.swift
//  PQPrototype
//
//  Created by William Hart on 06/05/2026.
//

import SwiftUI

struct TwoHeadedSlider: View{
    var varA: Binding<Double>
    var varB: Binding<Double>
    
    init(a: Binding<Double>, b: Binding<Double>){
        varA = a
        varB = b
    }
    
    var body: some View{
        ZStack{
            RoundedRectangle(cornerRadius: 999)
            
            Circle()
                .frame(width: 20,height: 20)
                .onLongPressGesture {
                    
                    
                }
            Circle()
                .frame(width: 20,height: 20)
        }
    }
}

#Preview {
    struct test: View{
        @State var a = 0.0
        @State var b = 100.0
        
        var body: some View{
            TwoHeadedSlider(a: $a, b: $b)
        }
    }
    return test()
}
