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

    @State
    private var quests: [Quest] = [] //done to prevent FetchRequest causing view backtracking when activating quests (changing attributes)
    
    
    var body: some View {
        VStack{
            Form{
                Section(header: Text("Active Quests")){
                    ForEach(quests) { quest in
                        if quest.isActive{ NavigationLink {
                            QuestView(quest: quest)
                        } label: {
                            Text("\(quest.questName!)")
                        }
                        }
                    }
                    .onDelete(perform: deleteQuests)
                }
                
                Section(header:Text("Inactive Quests")){
                    ForEach(quests) { quest in
                        if !quest.isActive{
                            NavigationLink {
                                QuestView(quest: quest)
                            } label: {
                                Text("\(quest.questName!)")
                            }
                        }
                    }.onDelete { o in
                        print("Hi")
                        deleteQuests(offsets: o)
                    }
                }
            }
        }.toolbar(){
            HStack{
                Button(action:addQuest){
                    Label("Add Quest", systemImage: "plus")
                }
                EditButton()
            }
        }
        .onAppear {
            refreshQuests()
        }
    }
    
    private func refreshQuests(){
        let fr = NSFetchRequest<Quest>()
        fr.entity = Quest.entity()
        fr.sortDescriptors = [NSSortDescriptor(keyPath: \Quest.isActive, ascending: false),NSSortDescriptor(keyPath: \Quest.questName, ascending: true)]
        do{
            try self.quests = viewContext.fetch(fr)
        }catch{
            return
        }
        
    }
    private func addQuest() {
        withAnimation {
            let newItem = Quest(context: viewContext)
            newItem.lateInit(name: "New Quest")

            do {
                try viewContext.save()
                refreshQuests()
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
                    let nullifyKey = QuestReward.generateNullifyKey(quest: q)
                    viewContext.delete(q)
                }
                do{try viewContext.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
                refreshQuests()
            }
        }
    }
}

#Preview {
    QuestManagerView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
