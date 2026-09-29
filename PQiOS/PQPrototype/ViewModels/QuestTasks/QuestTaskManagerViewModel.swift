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
    
    var controller: NSFetchedResultsController<QuestTask>
    var request = NSFetchRequest<QuestTask>(entityName: "QuestTask")
    @Published var questTasks: [QuestTask] = []
    
    var context: NSManagedObjectContext = PQPrototypeApp.mainContext
    @Published var newTaskName: String = ""
    @Published var newTaskType: AnyClass?
    @Published var taskCreationError: String = ""
    
    @Published var taskTypeSheetActive: Bool = false
    
    @Published var toDelete: IndexSet = IndexSet()
    
    init(quest: Quest? = nil){
        request.sortDescriptors = []
        controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        super.init()
    }
    func assignPredicateQuest(quest: Quest){
        self.quest = quest
        
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "quest == %@", quest)
        
        controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        controller.delegate = self
        
        do{
            try controller.performFetch()
            questTasks = controller.fetchedObjects ?? []
        }catch{}
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        context.perform { [self] in
            do{
                self.questTasks = try context.fetch(request)
            }catch{
                self.questTasks = []
            }
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
    
    func deleteTasks(offsets: IndexSet) {
        context.perform { [self] in
            offsets.map {self.questTasks[$0] }.forEach { q in
                context.delete(q)
            }
            toDelete = IndexSet()
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
        }
    }
}
