//
//  TrainingTaskView.swift
//  PQPrototype
//
//  Created by William Hart on 18/08/2026.
//

import SwiftUI

struct TrainingTaskView: View {
    @Environment(\.editMode) private var editMode
    private var editing: Bool { get { return  editMode!.wrappedValue.isEditing }}
    @Environment(\.managedObjectContext) private var context
    
    @ObservedObject
    var task: TrainingQuestTask
    
    @State var editedDuration: Date = Date(timeIntervalSinceReferenceDate:3600)

    init(task: TrainingQuestTask){
        self.task = task
        //self.locationView = LocationView(location: locationTask.taskArea!)
    }
    
    func loadData(){
        editedDuration = Date(timeIntervalSinceReferenceDate: task.duration)
    }
    
    var body: some View {
        VStack{
            VStack{
                //edit button header since atm this view is broght up as a form from the bottom of QuestView
                if !task.quest!.isActive{
                    HStack{
                        Spacer()
                        EditButton()
                    }
                }
                
                TextField("Task Name", text: $task.name ?? "Task Name")
                    .font(.title)
                    .disabled(!editing)
                
                DatePicker(selection: $editedDuration, displayedComponents:.hourAndMinute, label: {Text("Duration:")})
                    .environment(\.locale, Locale(identifier: "en_UK"))
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .frame(width: 170)
                    .disabled(!editing)
            }.padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
        }
        .toolbar(){
            EditButton()
        }
        .onChange(of: editMode!.wrappedValue.isEditing) { v in
            if v == false{
                //if attempted to save and couldnt
                if !save() {
                    //maintain edit mode
                    editMode?.wrappedValue = EditMode.active
                }
            }
        }
        .onAppear(perform: loadData)
    }
    
    func save() -> Bool{
        context.perform {
            let dur = editedDuration.timeIntervalSinceReferenceDate
            task.duration = dur
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
            
        }
        return true
    }
}

#Preview {
    var quest: Quest
    do{
        quest = try PersistenceController.preview.container.viewContext.fetch(Quest.fetchRequest())[0]
    }catch{quest = Quest(context: PersistenceController.preview.container.viewContext)}
    let task = TrainingQuestTask(context: PersistenceController.preview.container.viewContext)
    quest.addToTasks(task)
    return TrainingTaskView(task: task).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
