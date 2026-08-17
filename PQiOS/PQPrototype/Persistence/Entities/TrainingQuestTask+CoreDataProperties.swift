//
//  TrainingQuestTask+CoreDataProperties.swift
//  PQPrototype
//
//  Created by William Hart on 12/08/2026.
//
//

import Foundation
import CoreData


extension TrainingQuestTask {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TrainingQuestTask> {
        return NSFetchRequest<TrainingQuestTask>(entityName: "TrainingQuestTask")
    }

    @NSManaged public var duration: Double

}
