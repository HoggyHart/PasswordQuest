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
    
    private var fullView: Bool
    init(quest: Quest, full: Bool){
        self.quest = quest
        self.fullView = full
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
                Image(systemName: "circle.fill")
                    .foregroundColor( QuestTaskList.taskStatusColor(task: qtask) )
                    .shadow(color:.black, radius: 1)
                Text(qtask.currentStatus() + " - " + (qtask.name ?? "Error")).foregroundColor(UITraitCollection.current.userInterfaceStyle == .dark ? Color.white : Color.black)
            }
        }
    }
    
    var body: some View {
        VStack{
            HStack{
                Text("Tasks: ")
                Spacer()
                if editing{
                    Button(){
                        taskTypeSheetActive = true
                        //   addTask()
                    } label: {
                        Label("Add Task", systemImage: "plus")
                    }
                } else if !fullView{
                    NavigationLink(destination: QuestTaskList(quest: quest, full: true)) {
                        Image(systemName: "arrow.right")
                    }
                }
            }
            ScrollView{ //must NOT be list to allow the config to be usable
                ForEach(tasks){qtask in
                   // if fullView{
                        MyExpandable(
                            header:
                                Button(){
                                    inspectedTaskID = qtask.objectID
                                    //diwn/right arrow to indicate expansion status
                                } label: {
                                   QuestTaskListEntry(qtask: qtask)
                                },
                            content: VStack{
                                QuestTaskConfigView(task: qtask )
                                Button(){
                                    deleteTask(task: qtask)
                                } label : {
                                    Image(systemName:"multiply").foregroundColor(.red)
                                }
                            },
                            expandable: fullView
                        )
                    Divider()
                }
            }.padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
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
                        // for each task type
                        Button(){
                            addTask(task: TrainingQuestTask(context: context))
                            taskTypeSheetActive = false
                        } label:{
                            Image(systemName:"timer")
                                .frame(width: UIScreen.main.bounds.width/2,height: UIScreen.main.bounds.width/2)
                        }
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
                expandedConfigs[task.objectID] = false
            }
        }
    }
    
    
    private func deleteTask(task: QuestTask) {
        context.perform {
            withAnimation {
            
                context.delete(task)
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
        else{
            Text("No View Assigned To This Task Type!")
        }
    }
}

#Preview {

        let q = Quest(context: PersistenceController.preview.container.viewContext, name: "New Quest")
        let task = SingleLocationTask(context: PersistenceController.preview.container.viewContext, dummyVar: true)
        q.addToTasks(task)
    return VStack{
        EditButton()
        QuestTaskList(quest: q, full: true).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }

}
