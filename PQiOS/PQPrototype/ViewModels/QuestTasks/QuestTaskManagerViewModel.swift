import Foundation
import CoreData

class QuestTaskManagerViewModel: MultiPageListNSFRControllerDelegate<QuestTask,NSManagedObjectID>{

    override func addItem() {
        context.perform{
            if let quest = self.quest{
                let task: QuestTask
                do{
                    task = try self.buildTask()
                }catch let e{
                    self.taskCreationError = "\(e)"
                    return
                }
                self.taskCreationError = ""
                quest.addToTasks(task)
                self.breakTask()
                do{try self.context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
                self.taskTypeSheetActive = false
            }else{
                self.taskCreationError = "No Quest To Add To!"
            }
        }
    }
    
    override func deleteItems() {
        context.perform { [self] in
            if selectedListItems.isEmpty { return }
            for qt in fullList{
                if selectedListItems.contains(where: { id in
                    id == qt.objectID
                }){
                    context.delete(qt)
                }
            }
            subList = []
            selectedListItems = []
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
        }
    }
    var quest: Quest? = nil
    
    @Published var newTaskName: String = ""
    @Published var newTaskType: AnyClass?
    @Published var taskCreationError: String = ""
    
    @Published var taskTypeSheetActive: Bool = false
    
    init(){
        let mainRequest = NSFetchRequest<QuestTask>(entityName: "QuestTask")
        mainRequest.sortDescriptors = []
        
        let controller = NSFetchedResultsController(fetchRequest: mainRequest, managedObjectContext: PQPrototypeApp.mainContext, sectionNameKeyPath: nil, cacheName: nil)
        super.init(context: PQPrototypeApp.mainContext, controller: controller)
    }
    
    func assignPredicateQuest(quest: Quest){
        self.quest = quest
        
        controller.fetchRequest.predicate = NSPredicate(format: "quest == %@", quest)
        
        //start tracking changes
        startController()
    }
    
    private func buildTask() throws -> QuestTask{
        let t: QuestTask
        if newTaskType == ManualQuestTask.self{
            t = ManualQuestTask(context: context)
        }
        else if newTaskType == TrainingQuestTask.self{
            t = TrainingQuestTask(context: context)
        }
        else if newTaskType == SingleLocationTask.self{
            t = SingleLocationTask(context: context)
        }
        else if newTaskType == RNGLocationTask.self{
            t = RNGLocationTask(context: context)
        }else{
            throw InvalidTaskError(task: "New Task", invalidAttribute: "Unsupported Task Type")
        }
        t.name = newTaskName
        return t
    }
    func breakTask(){
        newTaskName = ""
        newTaskType = nil
    }
}
