//
//  Journal.swift
//  PQPrototype
//
//  Created by William Hart on 20/09/2026.
//

import SwiftUI

struct JournalView<Header: View, Content: View>: View {
    
    let backgroundPages: Int
    let bCCornerRadius: CGFloat = 10
    let extraPages: Int
    let lines: Int
    @ObservedObject var viewModel: JournalViewModel
    let content: (() -> Content)
    let header: (() -> Header)
    init(extraPages: Int, lines: Int = 17, backgroundPages: Bool = false, viewModel: JournalViewModel = JournalViewModel(), header: @escaping (() -> Header), content: @escaping (() -> Content)
    ){
        self.lines = lines
        self.backgroundPages = backgroundPages ? 5 : 0
        self.viewModel = viewModel
        self.header = header
        self.content = content
        if extraPages < 0 { self.extraPages = Int.max-1}
        else { self.extraPages = extraPages}
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
                    ForEach(0..<min(5,max(backgroundPages,viewModel.page))){i in
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
                            VStack(alignment: .center, spacing:0){
                                //  Spacer().frame(minHeight: 0)
                                ZStack{
                                    header().frame(minHeight: 50, maxHeight: .infinity)
                                    .padding(EdgeInsets(top: 0, leading: max(viewModel.pageSide*11,0), bottom: 0, trailing: max(-viewModel.pageSide*11,0)))
                                }
                               // Spacer().frame(minHeight: 0)
                                ZStack{
                                    VStack{
                                        ForEach(0..<lines){i in
                                            Divider()
                                            Spacer().frame(height: 29.5)
                                        }
                                        if lines > 0 {Divider()}
                                    }
                                    content().padding(EdgeInsets(top: 0, leading: max(viewModel.pageSide*11,0), bottom: 0, trailing: max(-viewModel.pageSide*11,0)))
                                }
                            }.offset(x:-viewModel.pageSide*11).padding(EdgeInsets(top: 0, leading: min(viewModel.pageSide*11,0), bottom: 0, trailing: min(-viewModel.pageSide*11,0)))
                        Spacer().frame(height: 50)
                    }
                    //page turn overlay
                    VStack(spacing:0){
                        Spacer()
                        ZStack{
                            HStack{
                                if extraPages != 0{
                                    if viewModel.page > 1{
                                        Button(){
                                            if viewModel.page == 1 {return}
                                            viewModel.page -= 1
                                            viewModel.pageSide *= -1
                                        } label: {
                                            Image(systemName: "arrowshape.turn.up.left.fill")
                                                .foregroundColor(.darkRed)
                                        }
                                    }
                                    Spacer()
                                    if viewModel.page < extraPages+1{
                                        Button(){
                                            if viewModel.page == extraPages+1{return}
                                            viewModel.page += 1
                                            viewModel.pageSide *= -1
                                        } label: {
                                            Image(systemName: "arrowshape.turn.up.right.fill")
                                                .foregroundColor(.darkRed)
                                        }
                                    }
                                }
                            }
                            Text("\(viewModel.page)")
                        }.frame(height: 20)
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
    JournalView(extraPages: -1, backgroundPages: false)
    {
        Rectangle().foregroundColor(.blue)
            .opacity(0.2)
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
