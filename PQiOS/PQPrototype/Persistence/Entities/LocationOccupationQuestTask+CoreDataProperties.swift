//
//  LocationOccupationQuestTask+CoreDataProperties.swift
//  PQPrototype
//
//  Created by William Hart on 28/12/2025.
//
//

import Foundation
import CoreData
import CoreLocation
import MapKit

extension LocationOccupationQuestTask {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocationOccupationQuestTask> {
        return NSFetchRequest<LocationOccupationQuestTask>(entityName: "LocationOccupationQuestTask")
    }

    @NSManaged public var lastUpdate: Date?
    @NSManaged public var locationName: String?
    @NSManaged public var occupiedAtLastUpdate: Bool
    @NSManaged public var recordedOccupationTime: Double
    @NSManaged public var requiredOccupationDuration: Double
    @NSManaged public var taskArea: CLCircularRegion?

}

extension LocationOccupationQuestTask{
    
}
