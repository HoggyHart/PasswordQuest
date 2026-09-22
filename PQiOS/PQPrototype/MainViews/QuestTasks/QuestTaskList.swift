//
//  QuestTaskList.swift
//  PQPrototype
//
//  Created by William Hart on 21/05/2026.
//

import SwiftUI
import CoreData
import MapKit

struct MyExpandable<Header: View, Content: View>: View {
    @Environment(\.editMode) private var editMode
    private var editing: Bool { get { return  editMode!.wrappedValue.isEditing }}
    @State var expanded: Bool = false
    var expandable: Bool
    let header: Header
    let content: Content
    init(header: Header, content: Content, expandable: Bool){
        self.content = content
        self.header = header
        self.expandable = expandable
    }
    
    var body: some View{
        VStack{
            HStack{
                header
                Spacer()
                if editing && expandable{
                    Button(){
                        expanded.toggle()
                    } label:{
                        if !expanded {
                            Image(systemName:"chevron.right")
                        } else{
                            Image(systemName: "chevron.down")
                        }
                    }
                }
            }
            if expanded && editing && expandable{
                content
            }
        }
    }
}


struct QuestTaskList: View {
    @Environment(\.editMode) private var editMode
    private var editing: Bool { get { return  editMode!.wrappedValue.isEditing }}
    @Environment(\.managedObjectContext) private var context
    
    @FetchRequest private var tasks: FetchedResults<QuestTask>
    
    @ObservedObject
    var quest: Quest
    
    @State private var inspectedTaskID: NSManagedObjectID? = nil
    private var isTaskSheetPresented: Binding<Bool> { Binding(get: { inspectedTaskID != nil }, set: { if !$0 { inspectedTaskID = nil } }) }
    
    @State private var expandedConfigs: Dictionary<NSManagedObjectID,Bool> = [:]
    @State private var toggleUpdate = false
    
    @State private var taskTypeSheetActive: Bool = false
    
    let firstTaskIndex: Int
    let lastTaskIndex: Int
    
    init(quest: Quest, firstTaskIndex: Int, lastTaskIndex: Int){
        self.quest = quest
        self.firstTaskIndex = firstTaskIndex
        self.lastTaskIndex = lastTaskIndex
        
        _tasks = FetchRequest(
                sortDescriptors: [
                    NSSortDescriptor(keyPath: \QuestTask.objectID, ascending: true)
                ],
                predicate: NSPredicate(format: "quest == %@", quest)
            )
        for task in tasks{
            expandedConfigs[task.objectID] = false
        }
    }
    
    struct QuestTaskListEntry: View {
        @ObservedObject
        var qtask: QuestTask
        
        init(qtask: QuestTask) {
            self.qtask = qtask
        }
        var body: some View {
            HStack(){
                if qtask.quest!.isActive{
                    ZStack{
                        RoundedRectangle(cornerRadius: 20).frame(width:60,height:20).foregroundColor( QuestTaskList.taskStatusColor(task: qtask) )
                            .shadow(color:.black, radius: 1)
                        Text(qtask.currentStatus() + " ")
                    }
                }
                Text("- " + (qtask.name ?? "Error")).foregroundColor(UITraitCollection.current.userInterfaceStyle == .dark ? Color.white : Color.black).font(.custom("Bradley Hand", size: 20))
            }.frame(height: 30)
        }
    }
    
    struct TaskTypeSelectorView: View {
        @Environment(\.dismiss) var dismiss
        @Environment(\.managedObjectContext) var context
        @Binding var selection: QuestTask?
        
        var body: some View {
            ZStack{
                ScrollView{
                    LazyVGrid(columns: [GridItem(), GridItem()]) {
                        Button(){
                            selection = ManualQuestTask(context: context)
                          //  taskTypeSheetActive = false
                        } label:{
                            Image(systemName: "checklist")
                        }
                        // for each task type
                        Button(){
                            selection = TrainingQuestTask(context: context)
                            dismiss()
                        } label:{
                            Image(systemName:"timer")
                                .frame(width: UIScreen.main.bounds.width/2,height: UIScreen.main.bounds.width/2)
                        }
                        Button(){
                            selection = SingleLocationTask(context: context, dummyVar: true)
                            dismiss()
                        } label:{
                            Image("SingleLocationTaskIcon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: UIScreen.main.bounds.width/2,height: UIScreen.main.bounds.width/2)
                        }
                        Button(){
                            selection = RNGLocationTask(context: context, dummyVar: true)
                            dismiss()
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
    }
    
    @State var newTaskName: String = ""
    @State var newTaskType: QuestTask? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 0){
            ForEach(firstTaskIndex..<lastTaskIndex){i in
                if i < tasks.count{
                    NavigationLink(destination: getView(task: tasks[i])) {
                        QuestTaskListEntry(qtask: tasks[i])
                    }.frame(height: 30)
                }else if i == tasks.count{
                    TextField("New Task \(Image(systemName: "plus"))", text: $newTaskName).font(.custom("Bradley Hand", size: 20)).submitLabel(.continue).onSubmit {taskTypeSheetActive=true}.frame(height: 30,alignment: .center)
                }else{
                    Spacer().frame(height: 30)
                }
            }
        }.frame(
            maxWidth: .infinity,
            alignment: .topLeading
        )
        //.sheet(isPresented: isTaskSheetPresented, onDismiss: {
        //            newTaskName = ""
        //        }){
        //            if let id = inspectedTaskID {
        //                let localTask = context.object(with: id) as! QuestTask
        //                getView(task: localTask)
        //            }
        //        }
        .sheet(isPresented: $taskTypeSheetActive,onDismiss: {
            if newTaskType != nil{
                newTaskType?.name = newTaskName
                addTask(task: newTaskType!)
                newTaskName = ""
                newTaskType = nil
            }
        }){
            TaskTypeSelectorView(selection: $newTaskType)
        }
    }
        //        .toolbar(){
        //            if !quest.isActive { EditButton() }
        //        }
        //        .onChange(of: editing) { v in
        //            if v == false{
        //                context.perform {
        //                    do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
        //                }
        //            }
        //        }
    
    func addTask(task: QuestTask){
        context.perform {
            withAnimation {
                quest.addToTasks(task)
                do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
                expandedConfigs[task.objectID] = false
            }
        }
    }
    
    
    private func deleteTask(task: QuestTask) {
        context.perform {
            withAnimation {
            
                context.delete(task)
                let key = QuestKey.generateKey(quest: quest)
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
        switch(task.quest?.questStatus()){
        case .failed:
            return .red
        case .inactive:
            return .white
        case .inProgress, .paused:
            if task.completed { return .green }
            return .yellow
        case .completed:
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
        else if task is TrainingQuestTask{
            TrainingTaskView(task: task as! TrainingQuestTask)
        }
        else if task is ManualQuestTask{
            ManualTaskView(task: task as! ManualQuestTask)
        }
        else{
            Text("No View Assigned To This Task Type!")
        }
    }
}

#Preview {

        let q = Quest(context: PersistenceController.preview.container.viewContext, name: "New Quest")
    let task = ManualQuestTask(context: PersistenceController.preview.container.viewContext)
    q.addToTasks(task)
   let task1 = TrainingQuestTask(context: PersistenceController.preview.container.viewContext)
    q.addToTasks(task1)
    let task2 = SingleLocationTask(context: PersistenceController.preview.container.viewContext, dummyVar: true)
    q.addToTasks(task2)
    let task3 = RNGLocationTask(context: PersistenceController.preview.container.viewContext, dummyVar: true)
    q.addToTasks(task3)
    return VStack{
        EditButton()
        QuestTaskList(quest: q,firstTaskIndex: 0,lastTaskIndex: 17).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }

}
