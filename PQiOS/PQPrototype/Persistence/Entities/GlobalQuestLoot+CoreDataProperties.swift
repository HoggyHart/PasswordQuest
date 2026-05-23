//
//  GlobalQuestLoot+CoreDataProperties.swift
//  PQPrototype
//
//  Created by William Hart on 21/05/2026.
//
//

import Foundation
import CoreData


extension GlobalQuestLoot {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GlobalQuestLoot> {
        return NSFetchRequest<GlobalQuestLoot>(entityName: "GlobalQuestLoot")
    }

    @NSManaged public var timeInABottle: Int64

}

extension GlobalQuestLoot : Identifiable {

}
