//
//  GlobalQueestLoot.swift
//  PQPrototype
//
//  Created by William Hart on 24/06/2026.
//

import Foundation
import CoreData

extension GlobalQuestLoot{
    
    static var shared: GlobalQuestLoot {
        get {
            do{
                return try PQPrototypeApp.mainContext.fetch(GlobalQuestLoot.fetchRequest()).first ?? {
                    let gql = GlobalQuestLoot(context: PQPrototypeApp.mainContext)
                    try PQPrototypeApp.mainContext.save()
                    return gql
                }()
            }catch{
                let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")
            }
        }
    }
    
    var timeInABottle: TimeInABottle {
        get{ return self.rawTimeInABottle ??
            {
                do{
                    self.rawTimeInABottle = TimeInABottle(context: self.managedObjectContext!)
                    try self.managedObjectContext!.save()
                }catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
                
                return self.rawTimeInABottle!
            }()}
    }
    
    static func getLoot(_ context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) -> GlobalQuestLoot {
        do{
            return try context.fetch(GlobalQuestLoot.fetchRequest()).first
            ?? GlobalQuestLoot(context: context)
        }catch{
            let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")
        }
    }
}
