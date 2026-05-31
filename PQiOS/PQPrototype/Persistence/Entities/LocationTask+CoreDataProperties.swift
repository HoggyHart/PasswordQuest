//
//  LocationTask+CoreDataProperties.swift
//  PQPrototype
//
//  Created by William Hart on 30/05/2026.
//
//

import Foundation
import CoreData


extension LocationTask {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocationTask> {
        return NSFetchRequest<LocationTask>(entityName: "LocationTask")
    }

    @NSManaged public var location: Location?

}
