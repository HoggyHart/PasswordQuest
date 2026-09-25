import SwiftUI
struct ManualTaskView: View {
    @Environment(\.editMode) private var editMode
    private var editing: Bool { get { return  editMode!.wrappedValue.isEditing }}
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) var dismiss
    @ObservedObject
    var task: ManualQuestTask
    
    @FetchRequest
    var subtasks: FetchedResults<ManualQuestTask>
    
    init(task: ManualQuestTask){
        self.task = task
        
        _subtasks = FetchRequest(
            entity: ManualQuestTask.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \ManualQuestTask.name, ascending: true),
                              NSSortDescriptor(keyPath: \ManualQuestTask.objectID, ascending: true)],
            predicate: NSPredicate(format: "superTask == %@", task)
        )
        
    }
    
    struct MTRow: View{
        @ObservedObject
        var subtask: ManualQuestTask
        
        var body: some View{
            HStack{
                TextField("Task Name", text: $subtask.name ?? "Unnamed")
                Toggle(isOn: $subtask.completed, label: { Rectangle().foregroundColor(subtask.completed ? .green : .red)}).labelsHidden()
                   
            }.onChange(of: subtask.completed) { newValue in
                subtask.chainCompletionToggle()
            }
        }
    }
    
    var body: some View {
        VStack{
            VStack{
                //edit button header since atm this view is broght up as a form from the bottom of QuestView
                if !task.getQuest().isActive{
                    HStack{
                        Button(action:addTask){
                            Label("Add Task", systemImage: "plus")
                        }
                        Spacer()
                        EditButton()
                    }
                }
                
                TextField("Task Name", text: $task.name ?? "Task Name")
                    .font(.title)
                    .foregroundColor(task.completed ? .green : .red)
                    .disabled(!editing)

                //TODO: implement addTask button (and remove)
                List{
                    ForEach(subtasks){ stask in
                        MTRow(subtask: stask)
                        .frame(height: 30)
                    }.onDelete(perform:deleteTasks)
                }.listStyle(PlainListStyle())
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
        
    }
    
    func save() -> Bool{
        context.perform {
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
        }
        return true
    }
    
    func addTask(){
        context.perform {
            withAnimation {
                let task = ManualQuestTask(context: context)
                self.task.addToSubTasks(task)
                do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
            }
        }
    }
    private func deleteTasks(offsets: IndexSet) {
        context.perform {
            withAnimation {
                offsets.map {subtasks[$0]}.forEach(context.delete)
                do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
            }
        }
    }
}

#Preview {
    var quest: Quest
    do{
        quest = try PersistenceController.preview.container.viewContext.fetch(Quest.fetchRequest())[0]
    }catch{quest = Quest(context: PersistenceController.preview.container.viewContext)}
    let task = ManualQuestTask(context: PersistenceController.preview.container.viewContext)
    quest.addToTasks(task)
    quest.isActive = false
    return ManualTaskView(task: task).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
