import CoreData
import Foundation

class ScheduleManagerViewModel: MultiPageListNSFRControllerDelegate<Schedule,NSManagedObjectID>{
    
    override func deleteItems() {
        context.perform { [self] in
            if selectedListItems.isEmpty { return }
            
            for q in fullList{
                if selectedListItems.contains(where: { id in
                    id == q.objectID
                }){
                    context.delete(q)
                }
            }
            subList = [] //gets updated when controller sees changes
            // empty list now to prevent "mutating deleted object" log when they are displayed between these 2 events
            selectedListItems = []
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
        }
    }
    
    init(){
        let mainRequest = NSFetchRequest<Schedule>(entityName: "Schedule")
        mainRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Schedule.isActive, ascending: false),
            NSSortDescriptor(keyPath: \Schedule.startTime, ascending: true)
        ]
        
        let controller = NSFetchedResultsController(fetchRequest: mainRequest, managedObjectContext: PQPrototypeApp.mainContext, sectionNameKeyPath: nil, cacheName: nil)
        super.init(context: PQPrototypeApp.mainContext, controller: controller)
        startController()
    }
}
