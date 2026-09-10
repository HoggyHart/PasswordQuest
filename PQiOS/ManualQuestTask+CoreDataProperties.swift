//
//  ManualQuestTask+CoreDataProperties.swift
//  PQPrototype
//
//  Created by William Hart on 08/09/2026.
//
//

import Foundation
import CoreData


extension ManualQuestTask {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManualQuestTask> {
        return NSFetchRequest<ManualQuestTask>(entityName: "ManualQuestTask")
    }

    @NSManaged public var subTasks: NSSet?
    @NSManaged public var superTask: ManualQuestTask?

}

// MARK: Generated accessors for subTasks
extension ManualQuestTask {

    @objc(addSubTasksObject:)
    @NSManaged public func addToSubTasks(_ value: ManualQuestTask)

    @objc(removeSubTasksObject:)
    @NSManaged public func removeFromSubTasks(_ value: ManualQuestTask)

    @objc(addSubTasks:)
    @NSManaged public func addToSubTasks(_ values: NSSet)

    @objc(removeSubTasks:)
    @NSManaged public func removeFromSubTasks(_ values: NSSet)

}
