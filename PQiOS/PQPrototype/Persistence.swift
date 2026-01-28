//
//  Persistence.swift
//  PQPrototype
//
//  Created by William Hart on 27/11/2025.
//

import CoreData
import CoreLocation
struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for i in 0..<4 {
            let newQuest = Quest(context: viewContext)
            newQuest.lateInit(name: "Test Quest \(i+1)")
            
            //0%2 == T
            //1%2 == F
            //2%2 == T
            //3%2 == F
            if i%2 == 0{
                let task = LocationOccupationQuestTask(context: viewContext)
                task.lateInit(
                    locName: "Unnamed Location",
                    taskArea: CLCircularRegion(
                        center: CLLocationCoordinate2D(
                            latitude: 0,
                            longitude: 0
                        ),
                        radius: 0,
                        identifier: "newLocTask"),
                    questDuration: 1
                )
                newQuest.addToTasks(task)
                
            }
            //0%3 == T
            //1%3 == F
            //2%3 == F
            //1%3 == T
            if i%3 == 0{
                let newSchedule = Schedule(context: viewContext)
                newSchedule.lateInit(quest: newQuest)
            }
            
            let newReward = QuestReward(context: viewContext)
            newReward.quest = newQuest
            newReward.key = newQuest.questUUID!
            newReward.obtainmentDate = Date.now + TimeInterval(i*60)
            newReward.completedOnTime = i%2 == 0
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        
        container = NSPersistentContainer(name: "PQPrototype")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
