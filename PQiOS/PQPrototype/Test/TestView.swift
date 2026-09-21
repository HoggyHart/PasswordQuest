//
//  TestView.swift
//  PQPrototype
//
//  Created by William Hart on 21/09/2026.
//

import SwiftUI

class TestVM: ObservableObject{
    @Published var variable: Int = 0
}

struct TestVOne: View{
    @StateObject var viewModel = TestVM()
    var body: some View{
        HStack{
            Text("\(viewModel.variable)")
            Button(){
                viewModel.variable+=1
            } label: {
                Rectangle().frame(width: 10,height: 10)
            }
            
        }
    }
}

struct TestView: View {
    @StateObject var viewModel = TestVM()
    var body: some View {
        TestVOne(viewModel: viewModel)
        HStack{
            Text("\(viewModel.variable)")
            Button(){
                viewModel.variable+=1
            } label: {
                Rectangle().frame(width: 10,height: 10)
            }
            
        }
    }
}

#Preview {
    TestView()
}
