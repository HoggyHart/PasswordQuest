//
//  GlobalQueestLoot.swift
//  PQPrototype
//
//  Created by William Hart on 24/06/2026.
//

import Foundation
import CoreData

extension GlobalQuestLoot{
    
    var shared: GlobalQuestLoot{
        get{
            return GlobalQuestLoot.getLoot(context: PQPrototypeApp.isPreview ?  PersistenceController.preview.container.viewContext : PersistenceController.shared.container.viewContext)
        }
    }
    
    static func getLoot(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) -> GlobalQuestLoot {
        do{
            return try context.fetch(GlobalQuestLoot.fetchRequest())[0]
        }catch{
            let gql = GlobalQuestLoot(context: context)
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
            return gql
        }
    }
}
