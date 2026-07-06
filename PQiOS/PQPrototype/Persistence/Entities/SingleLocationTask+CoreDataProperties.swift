//
//  LocationOccupationQuestTask+CoreDataProperties.swift
//  PQPrototype
//
//  Created by William Hart on 21/05/2026.
//
//

import Foundation
import CoreData


extension SingleLocationTask {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SingleLocationTask> {
        return NSFetchRequest<SingleLocationTask>(entityName: "SingleLocationTask")
    }

    @NSManaged public var lastUpdate: Date?
    @NSManaged public var occupiedAtLastUpdate: Bool
    @NSManaged public var stayInside: Bool
    @NSManaged public var recordedOccupationTime: Double
    @NSManaged public var requiredOccupationDuration: Double
}
