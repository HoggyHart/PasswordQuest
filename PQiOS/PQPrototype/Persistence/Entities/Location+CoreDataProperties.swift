//
//  Location+CoreDataProperties.swift
//  PQPrototype
//
//  Created by William Hart on 18/02/2026.
//
//

import Foundation
import CoreData


extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var radius: Double
    @NSManaged public var name: String?
    @NSManaged public var tasks: NSSet?

}

// MARK: Generated accessors for tasks
extension Location {

    @objc(addTasksObject:)
    @NSManaged public func addToTasks(_ value: LocationOccupationQuestTask)

    @objc(removeTasksObject:)
    @NSManaged public func removeFromTasks(_ value: LocationOccupationQuestTask)

    @objc(addTasks:)
    @NSManaged public func addToTasks(_ values: NSSet)

    @objc(removeTasks:)
    @NSManaged public func removeFromTasks(_ values: NSSet)

}

extension Location : Identifiable {

}
