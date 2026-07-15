//
//  MainView.swift
//  PQPrototype
//
//  Created by William Hart on 11/12/2025.
//

import SwiftUI

struct TimeInABottleDisplay: View{
    @Environment(\.managedObjectContext) private var context
    
    @State var infoDisplay: Bool = false
    
    @FetchRequest(entity: GlobalQuestLoot.entity(), sortDescriptors: []) private var gql: FetchedResults<GlobalQuestLoot>
    
    var body: some View{
        Button{
            infoDisplay = true
        } label: {
            ZStack{
                RoundedRectangle(cornerRadius: 999).foregroundColor(.yellow)
                RoundedRectangle(cornerRadius: 999).foregroundColor(.white)
                    .padding(EdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2))
                HStack{
                    Image(systemName: "hourglass")
                    Text("\(gql[0].timeInABottle!.timeStored)")
                }.padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 10)).foregroundColor(.black)
            }
            .frame(minWidth: 90, idealWidth: 90, maxWidth: 90, minHeight: 30, idealHeight: 30, maxHeight: 30)
        }
        .sheet(isPresented: $infoDisplay, content: {
            Text("Time is stored when quests are completed.\nIt can be spent to delay, skip, and complete failed quests.")
        })
    }
}

struct MainView: View {
    
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
                        TimeInABottleDisplay()
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
   // MainView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    TimeInABottleDisplay()
}
