//
//  RandomLocationQuestTask.swift
//  PQPrototype
//
//  Created by William Hart on 26/05/2026.
//

import Foundation
import CoreData
import CoreLocation

extension RNGLocationTask{
    //completion can be calculated, no DB/entity attribute needed
    var completedAreas: Int{ //TODO: can this be removed? whats it used for? (doing smth else rn)
        get{
            return self.randomLocationTasks!.map({ task in
                return (task as! SingleLocationTask).completed
            }).count
        }
    }
}
extension RNGLocationTask{
    convenience init(context: NSManagedObjectContext, dummyVar: Bool){
        self.init(context: context)
        self.name = "Visit 1/1 Locations"
        self.location  = Location(context: context,
                                       name: "Generation Area",
                                       area: CLCircularRegion(center: LocationServices.shared.getLocation(), radius: 1000, identifier: UUID().uuidString))
        self.minimumLocationsForCompletion = 1
        self.numberOfGeneratedLocations = 1
    }
    
    override func start() throws{
        reset()
        generateLocations()
    }
    
    func generateLocations(){
        for _ in 0..<self.numberOfGeneratedLocations{
            let newLoc = Location(context: self.managedObjectContext!, name: "TempLocation", area: CLCircularRegion(center: LocationServices.generateRandomLocation(origin: location!.center(), minRange: Double(self.minGenerationRange), maxRange: location!.radius), radius: 37.5,identifier: UUID().uuidString))
            newLoc.temporary = true
            let slt = SingleLocationTask(context: self.managedObjectContext!)
            slt.location = newLoc
            slt.requiredOccupationDuration = 1
            self.addToRandomLocationTasks(slt)
        }
    }
    
    override func reset(){
        for entity in self.randomLocationTasks!{
            self.managedObjectContext?.delete(entity as! NSManagedObject)
        }
        self.randomLocationTasks = NSSet()
    }
    
    override func update() throws {
        if completed {return}
        
        for task in self.randomLocationTasks!{
            let task = task as! SingleLocationTask
            try task.update()
        }
    }
    
    
    
}
