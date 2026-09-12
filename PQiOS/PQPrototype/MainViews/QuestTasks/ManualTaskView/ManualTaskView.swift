import SwiftUI
struct MTRow: View {
    @Environment(\.editMode) private var editMode
    private var editing: Bool { get { return  editMode!.wrappedValue.isEditing }}
    
    @ObservedObject
    var task: ManualQuestTask
    
    @FetchRequest
    var subtasks: FetchedResults<ManualQuestTask>
    
    let inactive: Bool
    init(task: ManualQuestTask, toggleDisabled: Bool) {
        self.task = task
        _subtasks = FetchRequest(
            entity: ManualQuestTask.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \ManualQuestTask.name, ascending: true),
                              NSSortDescriptor(keyPath: \ManualQuestTask.objectID, ascending: true)],
            predicate: NSPredicate(format: "superTask == %@", task)
        )
        inactive = toggleDisabled
    }
    
    @State var testint: Int = 0
    @State var expanded: Bool = false
    var body: some View{
        VStack{
            HStack{
//                Button(){expanded.toggle()} label:{
//                    Rectangle().frame(width: 10, height: 10)
//                }
                Text(task.name ?? "huh")
                //Button(){addTask()} label: {
                  //  Rectangle().foregroundColor(.orange)
                //}
                if !editing{Toggle(isOn: $task.completed) {}.disabled(inactive)}
            }
//            if expanded{
//                ForEach(subtasks) { st in
//                    MTRow(task: st, toggleDisabled: inactive).padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 0))
//                }
//            }
        }
        .onChange(of: task.completed) { newValue in
            testint += 1
            task.chainCompletionToggle()
        }
    }
    func addTask(){
        task.managedObjectContext?.perform {
            withAnimation {
                let task = ManualQuestTask(context: task.managedObjectContext!)
                self.task.addToSubTasks(task)
                do{try task.managedObjectContext!.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
            }
        }
    }
}

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
    
    @State var allSubtasks: Dictionary<Int,ManualQuestTask> = [:]
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
                    .disabled(!editing)

                //TODO: implement addTask button (and remove)
                //List{
                List{
                    ForEach(subtasks){ stask in
                        MTRow(task: stask, toggleDisabled: !task.getQuest().isActive)
                            .padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 0))
                    }.onDelete(perform:deleteTasks)
                    .onMove { index, int in
                        print(index)
                    }
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
                var task = ManualQuestTask(context: context)
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
