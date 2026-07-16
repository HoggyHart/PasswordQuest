//
//  MainView.swift
//  PQPrototype
//
//  Created by William Hart on 11/12/2025.
//

import SwiftUI

struct TimeInABottleUpgradeView: View{
    @Environment(\.managedObjectContext) private var context
    
    @State var infoDisplay: Bool = false
    
    @FetchRequest(entity: TimeInABottle.entity(), sortDescriptors: []) private var gql: FetchedResults<TimeInABottle>
    
    var body: some View{
        VStack{
            HStack{
                Text("Weekly Limit: \(gql[0].weeklyTimeCollected)/\(gql[0].weeklyTimeLimit)")
                Spacer()
                Button(){
                    context.perform {
                        if gql[0].updateStoredTime(amount: -Int(gql[0].weeklyTimeLimit)){
                            gql[0].weeklyTimeLimit += 30
                        }
                        do{try context.save()}catch{}
                    }
                } label:{
                    HStack{
                        Text("Upgrade Cost: \(gql[0].weeklyTimeLimit)")
                        Image(systemName: "hourglass")
                    }
                }
            }.padding(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 40))
        }
    }
}

struct TimeInABottleDisplay: View{
    @Environment(\.managedObjectContext) private var context
    
    @State var infoDisplay: Bool = false
    
    @FetchRequest(entity: TimeInABottle.entity(), sortDescriptors: []) private var gql: FetchedResults<TimeInABottle>
    
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
                    Text("\(gql[0].timeStored)")
                }.padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 10)).foregroundColor(.black)
            }
            .frame(minWidth: 90, idealWidth: 90, maxWidth: 90, minHeight: 30, idealHeight: 30, maxHeight: 30)
        }
        .sheet(isPresented: $infoDisplay, content: {
            Text("Time is stored when quests are completed.\nIt can be spent to delay, skip, and complete failed quests.")
            TimeInABottleUpgradeView()
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
