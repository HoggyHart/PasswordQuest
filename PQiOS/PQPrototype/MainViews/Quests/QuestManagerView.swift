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

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Quest.isActive, ascending: false),NSSortDescriptor(keyPath: \Quest.questName, ascending: true)],animation: .default)
    private var quests: FetchedResults<Quest>
    
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
                    }.onDelete(perform: deleteQuests)
                }
            }
        }
    }
    
    private func addQuest() {
        withAnimation {
            let newItem = Quest(context: viewContext)
            newItem.lateInit(name: "New Quest")

            do {
                try viewContext.save()
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
                offsets.map {quests[$0] }.forEach(viewContext.delete)
                do{try viewContext.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
            }
        }
    }
}

#Preview {
    QuestManagerView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
