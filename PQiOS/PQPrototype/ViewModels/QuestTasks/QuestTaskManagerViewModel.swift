//
//  QuestTaskManagerViewModel.swift
//  PQPrototype
//
//  Created by William Hart on 28/09/2026.
//

import Foundation
import CoreData

class QuestTaskManagerViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate{
    var quest: Quest? = nil
    var context: NSManagedObjectContext = PQPrototypeApp.mainContext
    
    var controller: NSFetchedResultsController<QuestTask>
    var mainRequest = NSFetchRequest<QuestTask>(entityName: "QuestTask")
    @Published var questTasks: [QuestTask] = []
    var subRequest = NSFetchRequest<QuestTask>(entityName: "QuestTask")
    @Published var displayedQuestTasks: [QuestTask] = []
    
    @Published var newTaskName: String = ""
    @Published var newTaskType: AnyClass?
    @Published var taskCreationError: String = ""
    
    @Published var taskTypeSheetActive: Bool = false
    
    @Published var toDelete = [NSManagedObjectID]()
    var listOffset: Int = 0
    var listSize: Int = 7
    
    override init(){
        mainRequest.sortDescriptors = []
        
        self.subRequest.sortDescriptors = []
        self.subRequest.fetchOffset = 0
        self.subRequest.fetchLimit = listSize
        
        controller = NSFetchedResultsController(fetchRequest: mainRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        super.init()
    }
    func assignPredicateQuest(quest: Quest){
        self.quest = quest
        
        mainRequest.sortDescriptors = []
        mainRequest.predicate = NSPredicate(format: "quest == %@", quest)
        
        controller = NSFetchedResultsController(fetchRequest: mainRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        controller.delegate = self
        
        do{
            try controller.performFetch()
            questTasks = controller.fetchedObjects ?? []
        }catch{}
        updateDisplayList()
    }
    func updateDisplayList(){
        self.subRequest.predicate = self.mainRequest.predicate
        do{
            self.displayedQuestTasks = try context.fetch(subRequest)
        }catch{
            self.displayedQuestTasks = []
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        context.perform { [self] in
            do{
                self.questTasks = try context.fetch(mainRequest)
            }catch{
                self.questTasks = []
            }
            updateDisplayList()
        }
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
    
    func addTask(){
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
    
    func deleteTasks(ids: [NSManagedObjectID]) {
        context.perform { [self] in
            
            var offsets = IndexSet()
            
            for i in 0..<questTasks.count{
                if ids.contains(where: { id in
                    id == questTasks[i].objectID
                }){
                    offsets.insert(i)
                }
            }
            
            offsets.map {self.questTasks[$0] }.forEach { q in
                context.delete(q)
            }
            toDelete = [NSManagedObjectID]()
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
        }
    }
}
