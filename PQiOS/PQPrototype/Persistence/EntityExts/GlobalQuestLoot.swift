//
//  GlobalQueestLoot.swift
//  PQPrototype
//
//  Created by William Hart on 24/06/2026.
//

import Foundation
import CoreData

extension GlobalQuestLoot{
    
    static func getLoot(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) -> GlobalQuestLoot {
        do{
            return try context.fetch(GlobalQuestLoot.fetchRequest())[0]
        }catch{
            let gql = GlobalQuestLoot(context: context)
            gql.timeInABottle = TimeInABottle(context: context)
            gql.timeInABottle!.refreshWeeklyLimit()
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
            return gql
        }
    }
}
