//
//  QuestReward+CoreDataProperties.swift
//  PQPrototype
//
//  Created by William Hart on 08/04/2026.
//
//

import Foundation
import CoreData


extension QuestReward {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<QuestReward> {
        return NSFetchRequest<QuestReward>(entityName: "QuestReward")
    }

    @NSManaged public var key: UUID?
    @NSManaged public var obtainmentDate: Date?
    @NSManaged public var questComplete: Bool
    @NSManaged public var scheduled: Bool
    @NSManaged public var rawType: Int16
    @NSManaged public var quest: Quest?

}

extension QuestReward : Identifiable {

}
