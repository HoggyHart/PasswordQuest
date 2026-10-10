//
//  MainHeader.swift
//  PQPrototype
//
//  Created by William Hart on 30/09/2026.
//

import SwiftUI

struct MainHeader: View {
    @Environment(\.managedObjectContext) var viewContext
    var body: some View {
        ZStack{
            Rectangle().frame(height: 50).foregroundColor(.tableWood)
            HStack(spacing: 0){
                Text("P").font(.journalTitle).foregroundColor(.yellow).bold()
                Text("assword").font(.journalBody).foregroundColor(.yellow).bold()
                Text("Q").font(.journalTitle).foregroundColor(.yellow).bold()
                Text("uest").font(.journalBody).foregroundColor(.yellow).bold()
            }
            TimeInABottleDisplay(GlobalQuestLoot.getLoot(viewContext).timeInABottle).frame(maxWidth: .infinity,alignment: .trailing)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
        }.frame(maxWidth: .infinity)
    }
}

#Preview {
    MainHeader().environment(\.managedObjectContext, PQPrototypeApp.mainContext)
}
