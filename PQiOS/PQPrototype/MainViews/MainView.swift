//
//  MainView.swift
//  PQPrototype
//
//  Created by William Hart on 11/12/2025.
//

import SwiftUI

struct MainView: View {
    @Environment(\.managedObjectContext) private var context
    let views = 4
    @State var menu = 0

    var body: some View {
        NavigationView{
            VStack{
                if menu == 0{
                    QuestManagerView()
                }
                else if menu == 1{
                    ScheduleManagerView()
                }
                else if menu == 2{
                    QuestKeyManagerView()
                }
                else if menu == 3{
                    LocationManagerView()
                }
            }
            
            .navigationTitle("PasswordQuest")
                .navigationBarTitleDisplayMode(.inline)
                .navigationViewStyle(.stack)
                .toolbar{
                    ToolbarItem{
                        TimeInABottleDisplay(GlobalQuestLoot.getLoot(context).timeInABottle)
                    }
                }
        }
        
        HStack(spacing: 1){
            ForEach(0..<views,id:\.self){i in
                Button(){
                    menu = i
                } label: {
                    Rectangle()
                }
            }
        }
        .frame(height: 30)
    }
}

#Preview {
   MainView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
