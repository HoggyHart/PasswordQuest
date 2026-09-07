//
//  ManualTask+CoreDataProperties.swift
//  PQPrototype
//
//  Created by William Hart on 07/09/2026.
//
//

import Foundation
import CoreData


extension ManualQuestTask {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManualQuestTask> {
        return NSFetchRequest<ManualQuestTask>(entityName: "ManualQuestTask")
    }


}
