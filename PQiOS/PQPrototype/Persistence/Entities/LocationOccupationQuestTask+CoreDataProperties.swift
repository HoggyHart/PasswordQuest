//
//  LocationOccupationQuestTask+CoreDataProperties.swift
//  PQPrototype
//
//  Created by William Hart on 18/02/2026.
//
//

import Foundation
import CoreData


extension LocationOccupationQuestTask {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocationOccupationQuestTask> {
        return NSFetchRequest<LocationOccupationQuestTask>(entityName: "LocationOccupationQuestTask")
    }

    @NSManaged public var lastUpdate: Date?
    @NSManaged public var occupiedAtLastUpdate: Bool
    @NSManaged public var recordedOccupationTime: Double
    @NSManaged public var requiredOccupationDuration: Double
    @NSManaged public var taskArea: Location?

}
