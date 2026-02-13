//
//  Schedule+CoreDataProperties.swift
//  PQPrototype
//
//  Created by William Hart on 01/02/2026.
//
//

import Foundation
import CoreData


extension Schedule {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Schedule> {
        return NSFetchRequest<Schedule>(entityName: "Schedule")
    }

    @NSManaged public var everyXDays: Bool
    @NSManaged public var isActive: Bool
    @NSManaged public var lastEndDate: Date?
    @NSManaged public var lastScheduleCompletedOnTime: Bool
    @NSManaged public var scheduledDays: NSWeek?
    @NSManaged public var scheduledEndTime: Date?
    @NSManaged public var scheduledStartTime: Date?
    @NSManaged public var scheduleName: String?
    @NSManaged public var scheduleUUID: UUID?
    @NSManaged public var startTime: Date?
    @NSManaged public var synchronised: Bool
    @NSManaged public var xDayDelay: Int32
    @NSManaged public var scheduledDaysInt: Int16
    @NSManaged public var quest: Quest?

}

extension Schedule : Identifiable {

}
