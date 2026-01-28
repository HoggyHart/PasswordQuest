//
//  Schedule+CoreDataProperties.swift
//  PQPrototype
//
//  Created by William Hart on 01/01/2026.
//
//

import Foundation
import CoreData


extension Schedule {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Schedule> {
        return NSFetchRequest<Schedule>(entityName: "Schedule")
    }

    @NSManaged public var isActive: Bool
    @NSManaged public var scheduledEndTime: Date?
    @NSManaged public var scheduledStartTime: Date?
    @NSManaged public var scheduleName: String?
    @NSManaged public var scheduleUUID: UUID?
    @NSManaged public var startTime: Date?
    @NSManaged public var schedule: ScheduleTypeInfo?
    @NSManaged public var quest: Quest?
    @NSManaged public var lastScheduleCompletedOnTime: Bool
    @NSManaged public var synchronised: Bool
    @NSManaged public var lastEndDate: Date?

}
