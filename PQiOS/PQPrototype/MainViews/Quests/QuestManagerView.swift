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
    
    var body: some View {
            Form{
                Section(header: Text("Active Quests")){
                    ForEach(questfs) { quest in
                        if quest.isActive{
                            NavigationLink (
                                destination: QuestView(quest: quest)
                                    .id(quest.objectID)
                            ) {
                                Text("\(quest.questName!)")
                            }
                        }
                    }
                    .onDelete(perform:deleteQuests)
                    
                }
               // Text(String(quests.allSatisfy({ v in return v.isActive })))
                Section(header:Text("Inactive Quests")){
                    ForEach(questfs) { quest in
                        if !quest.isActive{
                            NavigationLink {
                                QuestView(quest: quest)
                                    .id(quest.objectID)
                            } label: {
                                Text("\(quest.questName!)")
                            }
                        }
                    }.onDelete(perform:deleteQuests)
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
            refreshQuests(context: viewContext)
        }
        .navigationViewStyle(.stack)
    }
    
    private func refreshQuests(context: NSManagedObjectContext){
        let fr = NSFetchRequest<Quest>()
        fr.entity = Quest.entity()
        fr.sortDescriptors = [NSSortDescriptor(keyPath: \Quest.questName, ascending: true)]
        do{
            try questfs = context.fetch(fr)
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
    NavigationView{
        QuestManagerView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
