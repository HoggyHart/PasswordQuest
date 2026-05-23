//
//  QuestTaskList.swift
//  PQPrototype
//
//  Created by William Hart on 21/05/2026.
//

import SwiftUI
import CoreData
import MapKit
struct QuestTaskList: View {
    @Environment(\.editMode) private var editMode
    private var editing: Bool { get { return  editMode!.wrappedValue.isEditing }}
    @Environment(\.managedObjectContext) private var context
    
    @FetchRequest private var tasks: FetchedResults<LocationOccupationQuestTask>
    
    var quest: Quest
    
    @State private var inspectedTaskID: NSManagedObjectID? = nil
    private var isTaskSheetPresented: Binding<Bool> { Binding(get: { inspectedTaskID != nil }, set: { if !$0 { inspectedTaskID = nil } }) }
    
    init(quest: Quest){
        self.quest = quest
        
        _tasks = FetchRequest(
                sortDescriptors: [
                    NSSortDescriptor(keyPath: \QuestTask.objectID, ascending: true)
                ],
                predicate: NSPredicate(format: "quest == %@", quest)
            )
    }
    
    var body: some View {
        VStack{
            HStack{
                Text("Tasks: ")
                Spacer()
                if editing {
                    Button(){
                        addTask()
                    } label: {
                        Label("Add Task", systemImage: "plus")
                    }
                }
            }
            List{
                ForEach(tasks){qtask in
                    Button(){
                        inspectedTaskID = qtask.objectID
                    } label:{
                        HStack(){
                            Image(systemName: "circle.fill")
                                .foregroundColor( taskStatusColor(task: qtask) )
                                .shadow(color:.black, radius: 1)
                            Text(qtask.currentStatus() + " - " + qtask.name!)
                            Spacer()
                        }
                    }
                }
                .onDelete(perform: deleteTasks)
            }
            .listStyle(PlainListStyle())
        }.sheet(isPresented: isTaskSheetPresented){
            if let id = inspectedTaskID {
                let localTask = context.object(with: id) as! LocationOccupationQuestTask
                LocationTaskView(locationTask: localTask) }
        }
    }
    
    func addTask(){
        context.perform {
        withAnimation {
                let task = LocationOccupationQuestTask(context: context, location: nil, questDuration: 3)
                quest.addToTasks(task)
                do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
            }
        }
    }
    private func deleteTasks(offsets: IndexSet) {
        context.perform {
            withAnimation {
            
                offsets.map {tasks[$0] }.forEach(context.delete)
                var key = QuestKey.generateKey(quest: quest)
                key.keyType = .edited
                do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
            }
        }
    }
    func taskStatusColor(task: QuestTask) -> Color{
        ///-2: inactive, no tasks -> doesnt matter what colour - take default
        ///-1: inactive, failed
        ///0: inactive, not started
        ///1: active
        ///2: inactive, completed successfully
        switch(quest.questStatus()){
        case -1:
            return .red
        case 0:
            return .white
        case 1:
            if task.completed { return .green }
            return .yellow
        case 2:
            return .green
        default:
            return .purple
        }
    }
}

#Preview {

        let q = Quest(context: PersistenceController.preview.container.viewContext, name: "New Quest")
        let task = LocationOccupationQuestTask(context: PersistenceController.preview.container.viewContext, location: nil, questDuration: 5400)
        q.addToTasks(task)
        return QuestTaskList(quest: q).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)

}
