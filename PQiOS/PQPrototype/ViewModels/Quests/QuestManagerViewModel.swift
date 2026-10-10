import Foundation
import CoreData

class QuestManagerViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate{
    var context: NSManagedObjectContext = PQPrototypeApp.mainContext
    
    var controller: NSFetchedResultsController<Quest>
    var mainRequest = NSFetchRequest<Quest>(entityName: "Quest")
    @Published var quests: [Quest] = []
    var subRequest = NSFetchRequest<Quest>(entityName: "Quest")
    @Published var subListQuests: [Quest] = []
    @Published var toDelete = [NSManagedObjectID]()
    @Published var newQuestName: String = ""
    
    var listOffset: Int = 0
    let listSize: Int = 8
    
    override init(){
        self.mainRequest.sortDescriptors = []
        
        self.subRequest.sortDescriptors = []
        self.subRequest.fetchOffset = 0
        self.subRequest.fetchLimit = listSize
        
        self.controller = NSFetchedResultsController(fetchRequest: mainRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        super.init()
        self.controller.delegate = self
        
        do{
            try controller.performFetch()
            quests = controller.fetchedObjects ?? []
        }catch{}
        updateDisplayList()
    }
    
    func updateDisplayList(){
        self.subRequest.predicate = self.mainRequest.predicate
        do{
            self.subListQuests = try context.fetch(subRequest)
        }catch{
            self.subListQuests = []
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        context.perform { [self] in
            do{
                self.quests = try context.fetch(mainRequest)
            }catch{
                self.quests = []
            }
            updateDisplayList()
        }
        
    }
    
    func addQuest() {
        if newQuestName == "" || newQuestName == "Error" { return }
    
        context.perform{ [self] in
            _ = Quest(context: context, name: newQuestName)
            do {
                try context.save()
                newQuestName = ""
            } catch {
                context.rollback()
                newQuestName = "Error"
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func deleteQuests(ids: [NSManagedObjectID]) {
        context.perform { [self] in
            var offsets = IndexSet()
            
            for i in 0..<quests.count{
                if ids.contains(where: { id in
                    id == quests[i].objectID
                }){
                    offsets.insert(i)
                }
            }
            
            offsets.map {quests[$0] }.forEach { q in
                let nullifyKey = QuestKey.generateKey(quest: q)
                nullifyKey.keyType = .deleted
                context.delete(q)
            }
            subListQuests = [] //gets updated when controller sees changes
            // empty list now to prevent "mutating deleted object" log when they are displayed between these 2 events
            toDelete = [NSManagedObjectID]()
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
        }
    }
}
