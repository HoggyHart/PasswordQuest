//
//  QuestResult+CoreDataProperties.swift
//  PQPrototype
//
//  Created by William Hart on 19/01/2026.
//
//

import Foundation
import CoreData


extension QuestReward {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<QuestReward> {
        return NSFetchRequest<QuestReward>(entityName: "QuestResult")
    }

    @NSManaged public var completedOnTime: Bool
    @NSManaged public var key: UUID?
    @NSManaged public var scheduled: Bool
    @NSManaged public var obtainmentDate: Date?
    @NSManaged public var quest: Quest?

}

extension QuestReward : Identifiable {
    
}
