//
//  QuestKey+CoreDataProperties.swift
//  PQPrototype
//
//  Created by William Hart on 21/05/2026.
//
//

import Foundation
import CoreData


extension QuestKey {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<QuestKey> {
        return NSFetchRequest<QuestKey>(entityName: "QuestKey")
    }

    @NSManaged public var hidden: NSNumber?
    @NSManaged public var key: UUID?
    @NSManaged public var obtainmentDate: Date?
    @NSManaged public var questWasLocked: Bool
    @NSManaged public var rawType: Int16
    @NSManaged public var scheduled: UUID?
    @NSManaged public var quest: Quest?

}

extension QuestKey : Identifiable {

}
