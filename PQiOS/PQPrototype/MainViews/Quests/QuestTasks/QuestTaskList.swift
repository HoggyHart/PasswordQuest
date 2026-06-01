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
    
    @FetchRequest private var tasks: FetchedResults<QuestTask>
    
    var quest: Quest
    
    @State private var inspectedTaskID: NSManagedObjectID? = nil
    private var isTaskSheetPresented: Binding<Bool> { Binding(get: { inspectedTaskID != nil }, set: { if !$0 { inspectedTaskID = nil } }) }
    
    @State private var taskTypeSheetActive: Bool = false
    
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
                Button(){
                        taskTypeSheetActive = true
                     //   addTask()
                    } label: {
                        Label("Add Task", systemImage: "plus")
                    }
            }
            List{
                ForEach(tasks){qtask in
                    Button(){
                        inspectedTaskID = qtask.objectID
                    } label:{
                        VStack{
                            HStack(){
                                Image(systemName: "circle.fill")
                                    .foregroundColor( QuestTaskList.taskStatusColor(task: qtask) )
                                    .shadow(color:.black, radius: 1)
                                Text(qtask.currentStatus() + " - " + qtask.name!)
                                Spacer()
                            }
                            if editing{ QuestTaskConfigView(task: qtask) }
                        }
                    }.disabled(editing)
                }
                .onDelete(perform: deleteTasks)
            }
            .listStyle(PlainListStyle())
        }.sheet(isPresented: isTaskSheetPresented){
            if let id = inspectedTaskID {
                let localTask = context.object(with: id) as! QuestTask
                getView(task: localTask)
            }
        }.sheet(isPresented: $taskTypeSheetActive){
            ZStack{
                ScrollView{
                    LazyVGrid(columns: [GridItem(), GridItem()]) {
                        // for each task type:
                        Button(){
                            addTask(task:SingleLocationTask(context: context, dummyVar: true))
                            taskTypeSheetActive = false
                        } label:{
                            Image("SingleLocationTaskIcon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: UIScreen.main.bounds.width/2,height: UIScreen.main.bounds.width/2)
                        }
                        Button(){
                            addTask(task:RNGLocationTask(context: context, dummyVar: true))
                            taskTypeSheetActive = false
                        } label:{
                            Image("RandomLocationTaskIcon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: UIScreen.main.bounds.width/2,height: UIScreen.main.bounds.width/2)
                        }
                    }
                }
            }
        }
        .toolbar(){
            if !quest.isActive { EditButton() }
        }
        .onChange(of: editing) { v in
            if v == false{
                context.perform {
                    do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
                }
            }
        }
    }
    
    func addTask(task: QuestTask){
        context.perform {
        withAnimation {
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
    static func taskStatusColor(task: QuestTask) -> Color{
        ///-2: inactive, no tasks -> doesnt matter what colour - take default
        ///-1: inactive, failed
        ///0: inactive, not started
        ///1: active
        ///2: inactive, completed successfully
        switch(task.quest!.questStatus()){
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
    
    @ViewBuilder
    func getView(task: QuestTask) -> some View{
        if task is SingleLocationTask{
            SingleLocationTaskView(locationTask: task as! SingleLocationTask)
        }
        else if task is RNGLocationTask{
            RNGLTaskView(locationTask: task as! RNGLocationTask)
        }
        else{
            EmptyView()
        }
    }
}

#Preview {

        let q = Quest(context: PersistenceController.preview.container.viewContext, name: "New Quest")
        let task = SingleLocationTask(context: PersistenceController.preview.container.viewContext, dummyVar: true)
        q.addToTasks(task)
        return QuestTaskList(quest: q).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)

}
