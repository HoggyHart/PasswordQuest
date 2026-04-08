//
//  QuestKey+CoreDataProperties.swift
//  PQPrototype
//
//  Created by William Hart on 06/04/2026.
//
//

import Foundation
import CoreData


extension QuestKey {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<QuestKey> {
        return NSFetchRequest<QuestKey>(entityName: "QuestKey")
    }

    @NSManaged public var questUUID: UUID?
    @NSManaged public var acquisitionDate: Date?
    @NSManaged public var type: String?

}

extension QuestKey : Identifiable {

}
