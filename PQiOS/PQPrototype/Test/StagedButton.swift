//
//  StagedButton.swift
//  PQPrototype
//
//  Created by William Hart on 03/02/2026.
//

import SwiftUI

struct StagedButton<T: View>: View {
    
    let stages: [Button<T>]
    @State var curStage: Int = 0
    init(stages: [Button<T>]){
        self.stages = stages
    }
    
    var body: some View {
        ZStack{
            stages[curStage]
            Button(){
                nextStage()
                stages[curStage]
            } label: {Rectangle().opacity(0)}
        }
        Text("\(curStage)")
    }
    
    private func nextStage(){
        curStage += 1
        if curStage>stages.count-1{
            curStage = stages.count-1
        }
    }
    
    
    
}

#Preview {
    StagedButton(stages: [
        Button(){
            
        } label:{
            Rectangle().foregroundColor(.red)
        }
//            ,Button(){
//
//        } label:{
//            Circle().foregroundColor(.yellow)
//        },
//        Button(){
//            
//        } label:{
//            Rectangle().foregroundColor(.green)
//        }
//        
        ])
}
