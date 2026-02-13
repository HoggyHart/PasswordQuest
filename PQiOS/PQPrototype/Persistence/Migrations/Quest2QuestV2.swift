//
//  Quest2QuestV2.swift
//  PQPrototype
//
//  Created by William Hart on 11/02/2026.
//

import Foundation
import CoreData

///__params__
///forSource: the source entity, the one that needs to migrate
///in: no idea what mapping is
///manager: holds the managedObjectContext to put the objects in? idk
class QuestToQuestV2MigrationPolicy: NSEntityMigrationPolicy {
    override func createDestinationInstances(
        forSource sInstance: NSManagedObject,
        in mapping: NSEntityMapping,
        manager: NSMigrationManager
    ) throws 
    {
        //create goal entity
        let dest = NSEntityDescription.insertNewObject(
            forEntityName: "QuestV2",
            into: manager.destinationContext
        )
        
        //set values of goal entity using values of source entity
        dest.setValue(sInstance.value(forKey: "name"), forKey: "fullName")
 
        //idk. call super method to finalise i think
        try super.createDestinationInstances(
            forSource: sInstance,
            in: mapping,
            manager: manager
        )
    }
}
