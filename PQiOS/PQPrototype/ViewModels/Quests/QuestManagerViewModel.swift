import Foundation
import CoreData

class QuestManagerViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate{
    var context: NSManagedObjectContext = PQPrototypeApp.mainContext
    
    var controller: NSFetchedResultsController<Quest>
    var request = NSFetchRequest<Quest>(entityName: "Quest")
    @Published var quests: [Quest] = []
    
    @Published var toDelete: IndexSet = IndexSet()
    @Published var newQuestName: String = ""
    
    @Published var listOffset: Int = 0
    var listSize: Int = 8
    
    override init(){
        self.request.sortDescriptors = []
        
        self.controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        super.init()
        self.controller.delegate = self
        
        do{
            try controller.performFetch()
            quests = controller.fetchedObjects ?? []
        }catch{}
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        context.perform { [self] in
            do{
                self.quests = try context.fetch(request)
            }catch{
                self.quests = []
            }
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
    
    func deleteQuests(offsets: IndexSet) {
        context.perform { [self] in
            offsets.map {quests[$0] }.forEach { q in
                let nullifyKey = QuestKey.generateKey(quest: q)
                nullifyKey.keyType = .deleted
                context.delete(q)
            }
            quests = [] //empty to prevent "error: Mutating a managed object" before array is resorted via controllerDidChangeContent() and to prevent list shuffling in the view
            toDelete = IndexSet()
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
        }
    }
}
