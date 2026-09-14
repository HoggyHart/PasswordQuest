//
//  ContentView.swift
//  PQPrototype
//
//  Created by William Hart on 27/11/2025.
//

import SwiftUI
import CoreData

struct QuestManagerView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var questfs: [Quest] = [] //done to prevent FetchRequest causing view backtracking when activating quests (changing attributes)
    
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Quest.isActive, ascending: false),NSSortDescriptor(keyPath: \Quest.questName, ascending: true)]) private var quests: FetchedResults<Quest>
    
    struct QuestRow: View {
        let quest: Quest
        init(quest: Quest) {
            self.quest = quest
        }
        var body: some View {
            VStack(spacing: 0){
                ZStack{
                    RoundedRectangle(cornerRadius: 3).foregroundColor(.brown).offset(y:-7).opacity(0.3)
                    RoundedRectangle(cornerRadius: 3).foregroundColor(Color(red: 243/255, green: 227/255, blue: 172/255))
                    Text("\(quest.name)").frame(width:UIScreen.main.bounds.width,alignment: .center).font(.custom("Bradley Hand", fixedSize: 20))
                        .foregroundColor(Color(red: 22/255, green: 13/255, blue: 13/255))
                }
            }.frame(height: 40)
        }
    }
    @State var expandedQuest: Quest? = nil
    var body: some View {
        HStack{
            HStack{
                Button(action:addQuest){
                    Label("Add Quest", systemImage: "plus")
                }
            }
        }
        Divider()
        ScrollView{
            VStack(spacing: 0){
                ZStack{
                    Rectangle().foregroundColor(.brown)
                    Text("Active")
                }.frame(height: 30)
                
                VStack(spacing:-10){
                    ForEach(questfs) {  quest in
                        if quest.isActive{
                            Button(){
                                if expandedQuest == quest{
                                    expandedQuest = nil
                                }else{
                                    expandedQuest = quest
                                }
                            } label: {
                                if quest != expandedQuest{
                                    QuestRow(quest: quest)
                                }
                                else{
                                    QuestView(quest: quest)
                                }
                            }
                        }
                    }
                    .onDelete(perform:deleteQuests)
                }
                ZStack{
                    Rectangle().foregroundColor(.brown)
                    Text("ina")
                }.frame(height: 30)
                
                VStack(spacing:-10){
                    ForEach(questfs, id: \.self) { quest in
                        if !quest.isActive{
                            Button(){
                                expandedQuest = quest
                            } label: {
                                if quest != expandedQuest{
                                    QuestRow(quest: quest)
                                }
                            }
                            if quest == expandedQuest{
                                ZStack{
                                    Rectangle().foregroundColor(Color(red: 243/255, green: 227/255, blue: 172/255)).shadow(radius: 10)
                                    VStack(alignment: .trailing){
                                        NavigationLink(destination: QuestView(quest: quest)) {
                                            Rectangle().foregroundStyle(.black).frame(width: 100, height: 50)
                                        }
                                        Image(systemName: "arrow.right")
                                        QuestView(quest: quest)
                                    }
                                }
                            }
                        }
                    }.onDelete(perform:deleteQuests)
                    
                }
            }
        }.onAppear {
            refreshQuests(context: viewContext)
        }.navigationViewStyle(.stack)
    }
    
    private func refreshQuests(context: NSManagedObjectContext){
        let fr = NSFetchRequest<Quest>()
        fr.entity = Quest.entity()
        fr.sortDescriptors = [NSSortDescriptor(keyPath: \Quest.questName, ascending: true)]
        do{
            try questfs = context.fetch(fr)
            expandedQuest = questfs.last
        }catch{
            return
        }
    }
    
    
    private func addQuest() {
        withAnimation {
            _ = Quest(context: viewContext, name: "New Quest")

            do {
                try viewContext.save()
                refreshQuests(context: viewContext)
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteQuests(offsets: IndexSet) {
        viewContext.perform {
            withAnimation {
                offsets.map {quests[$0] }.forEach { q in
                    let nullifyKey = QuestKey.generateKey(quest: q)
                    nullifyKey.keyType = .deleted
                    viewContext.delete(q)
                }
                do{try viewContext.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
                refreshQuests(context: viewContext)
            }
        }
    }
}

#Preview {
    QuestManagerView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
