//
//  QuestResult+CoreDataProperties.swift
//  PQPrototype
//
//  Created by William Hart on 19/01/2026.
//
//

import Foundation
import CoreData


extension QuestReward {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<QuestReward> {
        return NSFetchRequest<QuestReward>(entityName: "QuestResult")
    }

    @NSManaged public var completedOnTime: Bool
    @NSManaged public var key: UUID?
    @NSManaged public var scheduled: Bool
    @NSManaged public var obtainmentDate: Date?
    @NSManaged public var quest: Quest?

}

extension QuestReward : Identifiable {

    func toJson() -> String{
        var data = "{\n"
        data.append("\"questUUID\" : \"" + key!.uuidString + "\",\n")
        data.append("\"completedOnTime\" : \"" + (self.completedOnTime ? "True" : "False") + "\",\n")
        data.append("\"obtainmentDate\" : \"" + self.obtainmentDate!.formatted(date: .numeric, time: .standard) + "\",\n")
        data.append("\"scheduled\" : \"" + (self.scheduled ? "True" : "False") + "\"\n}")
        return data
    }
}
