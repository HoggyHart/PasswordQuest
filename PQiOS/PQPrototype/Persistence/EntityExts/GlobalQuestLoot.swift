//
//  GlobalQueestLoot.swift
//  PQPrototype
//
//  Created by William Hart on 24/06/2026.
//

import Foundation
import CoreData

extension GlobalQuestLoot{
    
    static func getLoot(_ context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) -> GlobalQuestLoot {
        do{
            return try context.fetch(GlobalQuestLoot.fetchRequest()).first 
            ?? initLoot(context)
        }catch{
            return initLoot(context)
        }
    }
    
    static private func initLoot(_ context: NSManagedObjectContext) -> GlobalQuestLoot{
        let gql = GlobalQuestLoot(context: context)
        gql.timeInABottle = TimeInABottle(context: context)
        do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
        return gql
    }
}
