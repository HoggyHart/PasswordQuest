//
//  QuestTaskList.swift
//  PQPrototype
//
//  Created by William Hart on 21/05/2026.
//

import SwiftUI
import CoreData
import MapKit

struct QuestTaskListView: View {
    @Environment(\.editMode) private var editMode
    private var editing: Bool { get { return  editMode!.wrappedValue.isEditing }}
    @Environment(\.managedObjectContext) private var context
    
    let quest: Quest
    
    init(quest: Quest, listItemHeight: CGFloat = 30, viewModel: QuestTaskManagerViewModel? = nil){
        self.quest = quest
        self.listItemHeight = listItemHeight
        self.viewModel = viewModel ?? QuestTaskManagerViewModel()
    }
    
    struct QuestTaskListEntry: View {
        @ObservedObject
        var qtask: QuestTask
        
        init(qtask: QuestTask) {
            self.qtask = qtask
        }
        var body: some View {
            HStack(){
                if qtask.quest?.isActive ?? false{
                    ZStack{
                        RoundedRectangle(cornerRadius: 20).frame(width:60,height:20).foregroundColor( taskStatusColor )
                            .shadow(color:.black, radius: 1)
                        Text(qtask.currentStatus() + " ")
                    }
                }
                Text("- " + (qtask.name ?? "Error")).foregroundColor(UITraitCollection.current.userInterfaceStyle == .dark ? Color.white : Color.black).font(.journalBody)
            }
        }
        
        var taskStatusColor: Color{
            ///-2: inactive, no tasks -> doesnt matter what colour - take default
            ///-1: inactive, failed
            ///0: inactive, not started
            ///1: active
            ///2: inactive, completed successfully
            switch(qtask.quest?.questStatus()){
            case .failed:
                return .red
            case .inactive:
                return .white
            case .inProgress, .paused:
                if qtask.completed { return .green }
                return .yellow
            case .completed:
                return .green
            default:
                return .purple
            }
        }
    }
    
    @ObservedObject var viewModel: QuestTaskManagerViewModel
    let listItemHeight: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0){
            ForEach(viewModel.displayedQuestTasks){q in
                SelectableView(selections: $viewModel.toDelete, value: q.objectID) {
                    NavigationLink(destination: getView(task: q)) {
                        ZStack{
                            QuestTaskListEntry(qtask: q).frame(height: listItemHeight)
                            if viewModel.toDelete.contains(q.objectID){
                                Rectangle().frame(height: 2).foregroundColor(.red)
                            }
                        }
                    }
                    .disabled(editing)
                }
            }
            ForEach(0..<viewModel.listSize - viewModel.displayedQuestTasks.count, id: \.self){ i in
                if i == 0 && !quest.isActive{
                    TextField("New Task \(Image(systemName: "plus"))", text: $viewModel.newTaskName).font(.journalBody).submitLabel(.continue).onSubmit {viewModel.taskTypeSheetActive=true}.frame(height: listItemHeight,alignment: .center)
                }else{
                    Spacer().frame(height: listItemHeight)
                }
            }
        }.frame(
            maxWidth: .infinity,
            alignment: .topLeading
        )
        .sheet(isPresented: $viewModel.taskTypeSheetActive,onDismiss: {
            viewModel.breakTask()
        }){
            TaskCreationView(viewModel: viewModel)
        }
        .onChange(of: editing) { newValue in
            if viewModel.toDelete.isEmpty { return }
            viewModel.deleteTasks(ids: viewModel.toDelete)
        }
        .onAppear(){
            viewModel.assignPredicateQuest(quest: quest)
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
        QuestTaskListView(quest: q).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }

}
