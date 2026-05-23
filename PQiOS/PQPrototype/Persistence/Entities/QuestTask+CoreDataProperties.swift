//
//  QuestTask+CoreDataProperties.swift
//  PQPrototype
//
//  Created by William Hart on 21/05/2026.
//
//

import Foundation
import CoreData


extension QuestTask {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<QuestTask> {
        return NSFetchRequest<QuestTask>(entityName: "QuestTask")
    }

    @NSManaged public var completed: Bool
    @NSManaged public var name: String?
    @NSManaged public var quest: Quest?

}

extension QuestTask : Identifiable {

}
