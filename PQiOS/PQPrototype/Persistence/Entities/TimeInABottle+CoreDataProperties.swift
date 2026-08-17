//
//  TimeInABottle+CoreDataProperties.swift
//  PQPrototype
//
//  Created by William Hart on 15/07/2026.
//
//

import Foundation
import CoreData


extension TimeInABottle {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TimeInABottle> {
        return NSFetchRequest<TimeInABottle>(entityName: "TimeInABottle")
    }

    @NSManaged public var weeklyTimeLimit: Int16
    @NSManaged public var weeklyTimeReset: Date?
    @NSManaged public var weeklyLimitIncreaseDate: Date?
    @NSManaged public var weeklyTimeCollected: Int16
    @NSManaged public var timeStored: Int64

}

extension TimeInABottle : Identifiable {

}
