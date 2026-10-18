import Foundation
import CoreData

class QuestManagerViewModel: MultiPageListNSFRControllerDelegate<Quest, NSManagedObjectID>{

    override func addItem(){
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
    
    override func deleteItems() {
        context.perform { [self] in
            if selectedListItems.isEmpty { return }
            
            for q in fullList{
                if selectedListItems.contains(where: { id in
                    id == q.objectID
                }){
                    let nullifyKey = QuestKey.generateKey(quest: q)
                    nullifyKey.keyType = .deleted
                    context.delete(q)
                }
            }
            subList = [] //gets updated when controller sees changes
            // empty list now to prevent "mutating deleted object" log when they are displayed between these 2 events
            selectedListItems = []
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
        }
    }

    @Published var newQuestName: String = ""
    
    init(){
        let mainRequest = NSFetchRequest<Quest>(entityName: "Quest")
        mainRequest.sortDescriptors = []
        
        let controller = NSFetchedResultsController(fetchRequest: mainRequest, managedObjectContext: PQPrototypeApp.mainContext, sectionNameKeyPath: nil, cacheName: nil)
        super.init(context: PQPrototypeApp.mainContext, controller: controller)
        startController()
    }
}
