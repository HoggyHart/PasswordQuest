//
//  ManualQuestTask+CoreDataProperties.swift
//  PQPrototype
//
//  Created by William Hart on 08/09/2026.
//
//

import Foundation
import CoreData


extension ManualQuestTask {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManualQuestTask> {
        return NSFetchRequest<ManualQuestTask>(entityName: "ManualQuestTask")
    }

    @NSManaged public var subTasks: ManualQuestTask?
    @NSManaged public var superTask: ManualQuestTask?

}
