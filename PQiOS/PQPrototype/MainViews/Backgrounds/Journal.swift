//
//  Journal.swift
//  PQPrototype
//
//  Created by William Hart on 20/09/2026.
//

import SwiftUI

struct Journal<Content: View>: View {
    
    var bCCornerRadius: CGFloat = 10
    
    @State var page = 1
    @State var pageSide: CGFloat = -1
    let multiplePages: Bool
    
    let content: (() -> Content)
    init(multiplePages: Bool, content: @escaping (() -> Content)){
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
                    .id(page)
                
                //page(s)
                ZStack{
                    
                    //gives page selection some 'UI depth'
                    ForEach(0..<min(5,page)){i in
                        Rectangle().foregroundColor(.journalPaper).offset(x:-pageSide*CGFloat(i)).shadow(radius: 1)
                    }.id(page)
                    //other side of journal, probably a smoother way to do this
                    HStack(spacing:0){
                        if(pageSide == -1){
                            Spacer()
                            Rectangle().frame(width: 1)
                            Rectangle().frame(width: 11).foregroundColor(.journalPaper)
                        }else{
                            Rectangle().frame(width: 11).foregroundColor(.journalPaper)
                            Rectangle().frame(width: 1)
                            Spacer()
                        }
                    }.offset(x:-pageSide*11)
                    
                    GeometryReader{h in
                        VStack(alignment: .center, spacing:0){
                           // Rectangle()
                            Spacer()
                            ForEach(0..<Int(h.size.height-60)/30){i in
                                Divider().offset(x:-pageSide*11).padding(EdgeInsets(top: 0, leading: min(pageSide*11,0), bottom: 0, trailing: min(-pageSide*11,0)))
                                if i < Int(h.size.height-60)/30-1 {Spacer().frame(height: 30)}
                            }
                            Spacer()
                            //Rectangle()
                        }
                    }
                    content()
                    //page turn overlay
                    VStack(spacing:0){
                        Spacer()
                        HStack{
                            
                            Button(){
                                if page == 1 {return}
                                page = max(1,page-1)
                                pageSide *= -1
                            } label: {
                                Image(systemName: "arrowshape.turn.up.left.fill")
                                    .foregroundColor(.darkRed)
                            }
                            Spacer()
                            //Text("\(page*2 + min(0,Int(pageSide)))")
                            Text("\(page)")
                            Spacer()
                            Button(){
                                page += 1
                                pageSide *= -1
                            } label: {
                                Image(systemName: "arrowshape.turn.up.right.fill")
                                    .foregroundColor(.darkRed)
                            }
                            
                        }.frame(height:30)
                    }
                    .padding(EdgeInsets(top: 7, leading: 10, bottom: 7, trailing: 10))
                }
                .padding(EdgeInsets(top: 10,
                                    leading: max(10,pageSide*21),
                                    bottom: 10,
                                    trailing: max(10,-pageSide*21)))
                
            }.padding(
                EdgeInsets(top: 10,
                           leading: min(1,-pageSide*bCCornerRadius),
                           bottom: 10,
                           trailing: min(1,pageSide*bCCornerRadius)))
            
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    Journal(multiplePages: true) {
        Rectangle().foregroundColor(.red)
            .opacity(0.4)
        }
}
