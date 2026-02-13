//
//  Quest+CoreDataProperties.swift
//  PQPrototype
//
//  Created by William Hart on 19/01/2026.
//
//

import Foundation
import CoreData


extension Quest {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Quest> {
        return NSFetchRequest<Quest>(entityName: "Quest")
    }

    @NSManaged public var isActive: Bool
    @NSManaged public var maxQuestDuration: Double
    @NSManaged public var questName: String?
    @NSManaged public var questStartTime: Date?
    @NSManaged public var questUUID: UUID?
    @NSManaged public var restrictedDeviceIPs: String?
    @NSManaged public var locked: Bool
    @NSManaged public var schedulers: NSSet?
    @NSManaged public var tasks: NSSet?
    @NSManaged public var rewards: NSSet?

}

// MARK: Generated accessors for schedulers
extension Quest {

    @objc(addSchedulersObject:)
    @NSManaged public func addToSchedulers(_ value: Schedule)

    @objc(removeSchedulersObject:)
    @NSManaged public func removeFromSchedulers(_ value: Schedule)

    @objc(addSchedulers:)
    @NSManaged public func addToSchedulers(_ values: NSSet)

    @objc(removeSchedulers:)
    @NSManaged public func removeFromSchedulers(_ values: NSSet)

}

// MARK: Generated accessors for tasks
extension Quest {

    @objc(addTasksObject:)
    @NSManaged public func addToTasks(_ value: QuestTask)

    @objc(removeTasksObject:)
    @NSManaged public func removeFromTasks(_ value: QuestTask)

    @objc(addTasks:)
    @NSManaged public func addToTasks(_ values: NSSet)

    @objc(removeTasks:)
    @NSManaged public func removeFromTasks(_ values: NSSet)

}

// MARK: Generated accessors for rewards
extension Quest {

    @objc(addRewardsObject:)
    @NSManaged public func addToRewards(_ value: QuestReward)

    @objc(removeRewardsObject:)
    @NSManaged public func removeFromRewards(_ value: QuestReward)

    @objc(addRewards:)
    @NSManaged public func addToRewards(_ values: NSSet)

    @objc(removeRewards:)
    @NSManaged public func removeFromRewards(_ values: NSSet)

}

extension Quest: Identifiable{
    
}
