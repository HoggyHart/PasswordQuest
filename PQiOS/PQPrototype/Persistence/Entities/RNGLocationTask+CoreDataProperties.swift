//
//  RandomLocationQuestTask+CoreDataProperties.swift
//  PQPrototype
//
//  Created by William Hart on 27/05/2026.
//
//

import Foundation
import CoreData


extension RNGLocationTask {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RNGLocationTask> {
        return NSFetchRequest<RNGLocationTask>(entityName: "RNGLocationTask")
    }

    @NSManaged public var minGenerationRange: Double
    @NSManaged public var numberOfGeneratedLocations: Int16
    @NSManaged public var minimumLocationsForCompletion: Int16
    @NSManaged public var randomLocations: NSSet?
    @NSManaged public var randomLocationTasks: NSSet?

}

// MARK: Generated accessors for randomLocations
extension RNGLocationTask {

    @objc(addRandomLocationsObject:)
    @NSManaged public func addToRandomLocations(_ value: Location)

    @objc(removeRandomLocationsObject:)
    @NSManaged public func removeFromRandomLocations(_ value: Location)

    @objc(addRandomLocations:)
    @NSManaged public func addToRandomLocations(_ values: NSSet)

    @objc(removeRandomLocations:)
    @NSManaged public func removeFromRandomLocations(_ values: NSSet)

}

// MARK: Generated accessors for randomLocationTasks
extension RNGLocationTask {

    @objc(addRandomLocationTasksObject:)
    @NSManaged public func addToRandomLocationTasks(_ value: SingleLocationTask)

    @objc(removeRandomLocationTasksObject:)
    @NSManaged public func removeFromRandomLocationTasks(_ value: SingleLocationTask)

    @objc(addRandomLocationTasks:)
    @NSManaged public func addToRandomLocationTasks(_ values: NSSet)

    @objc(removeRandomLocationTasks:)
    @NSManaged public func removeFromRandomLocationTasks(_ values: NSSet)

}
