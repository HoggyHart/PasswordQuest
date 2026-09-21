//
//  Journal.swift
//  PQPrototype
//
//  Created by William Hart on 20/09/2026.
//

import SwiftUI

struct Journal<Header: View, Content: View>: View {
    
    let bCCornerRadius: CGFloat = 10
    let multiplePages: Bool
    
    @ObservedObject var viewModel: JournalViewModel
    let content: (() -> Content)
    let header: (() -> Header)
    init(multiplePages: Bool, viewModel: JournalViewModel = JournalViewModel(), header: @escaping (() -> Header), content: @escaping (() -> Content)
    ){
        self.viewModel = viewModel
        self.header = header
        self.content = content
        self.multiplePages = multiplePages
    }
    
    var body: some View {
        ZStack{
            //table
            Rectangle().foregroundColor(.tableWood)
            
            ZStack{
                //book cover
                RoundedRectangle(cornerRadius: bCCornerRadius)
                    .foregroundColor(.bookCover)
                    .id(viewModel.page)
                
                //page(s)
                ZStack{
                    
                    //gives page selection some 'UI depth'
                    ForEach(0..<min(5,viewModel.page)){i in
                        Rectangle().foregroundColor(.journalPaper).offset(x:-viewModel.pageSide*CGFloat(i)).shadow(radius: 1)
                    }.id(viewModel.page)
                    //other side of journal, probably a smoother way to do this
                    HStack(spacing:0){
                        if(viewModel.pageSide == -1){
                            Spacer()
                            Rectangle().frame(width: 1)
                            Rectangle().frame(width: 11).foregroundColor(.journalPaper)
                        }else{
                            Rectangle().frame(width: 11).foregroundColor(.journalPaper)
                            Rectangle().frame(width: 1)
                            Spacer()
                        }
                    }.offset(x:-viewModel.pageSide*11)
                    
                    VStack(alignment: .center, spacing: 0){
                        Spacer().frame(height: 50)
                        GeometryReader{h in
                            VStack(alignment: .center, spacing:0){
                                Spacer().frame(minHeight: 0)
                                header().offset(y:-25).frame(height: 0)
                                    .padding(EdgeInsets(top: 0, leading: max(viewModel.pageSide*11,0), bottom: 0, trailing: max(-viewModel.pageSide*11,0)))
                                Spacer().frame(minHeight: 0)
                                ForEach(0..<max(Int(h.size.height)/30,2)){i in
                                    Divider()
                                    Spacer().frame(height: 29.5)
                                }
                                Divider()
                            }.offset(x:-viewModel.pageSide*11).padding(EdgeInsets(top: 0, leading: min(viewModel.pageSide*11,0), bottom: 0, trailing: min(-viewModel.pageSide*11,0)))
                        }
                        Spacer().frame(height: 50)
                    }
                    content()
                    //page turn overlay
                    VStack(spacing:0){
                        Spacer()
                        HStack{
                            
                            Button(){
                                if viewModel.page == 1 {return}
                                viewModel.page = max(1,viewModel.page-1)
                                viewModel.pageSide *= -1
                            } label: {
                                Image(systemName: "arrowshape.turn.up.left.fill")
                                    .foregroundColor(.darkRed)
                            }
                            Spacer()
                            //Text("\(page*2 + min(0,Int(pageSide)))")
                            Text("\(viewModel.page)")
                            Spacer()
                            Button(){
                                viewModel.page += 1
                                viewModel.pageSide *= -1
                            } label: {
                                Image(systemName: "arrowshape.turn.up.right.fill")
                                    .foregroundColor(.darkRed)
                            }
                            
                        }
                    }
                    .padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
                }
                .padding(EdgeInsets(top: 10,
                                    leading: max(10,viewModel.pageSide*21),
                                    bottom: 10,
                                    trailing: max(10,-viewModel.pageSide*21)))
                
            }.padding(
                EdgeInsets(top: 10,
                           leading: min(1,-viewModel.pageSide*bCCornerRadius),
                           bottom: 10,
                           trailing: min(1,viewModel.pageSide*bCCornerRadius)))
            
        }
    }
}
    
#Preview {
    Journal(multiplePages: true)
    {
        Rectangle().foregroundColor(.blue)
            .opacity(0.2).frame(height: 50)
    } content: {
        ZStack{
            VStack(alignment: .leading){
                Rectangle().foregroundColor(.red)
                    .opacity(0.2).frame(width: 200, height: 200)
               // Spacer()
            }
            Rectangle().foregroundColor(.red)
                .opacity(0.2)
        }
    }
}
