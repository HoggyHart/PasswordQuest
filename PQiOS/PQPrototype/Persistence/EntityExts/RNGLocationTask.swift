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
    //completion % can be calculated, no DB/entity attribute needed
    var completedAreas: Int{
        get{
            return self.randomLocationTasks?.filter({ task in
                return (task as! SingleLocationTask).completed
            }).count ?? 0
        }
    }
    override public var currentReward: Int{
        get {
            if completed { return maxReward }
            else { return max(5,Int(Double(self.completedAreas)*rangeMult)) }
        }
    }
    private var rangeMult: Double{
        // 100% +10% value per 100 meters range
        get {return 1.0 + (self.location?.radius ?? 0.0)*0.1/100.0}
    }
    override public var maxReward: Int{
        get{ return max(5,Int(Double(self.numberOfGeneratedLocations) * rangeMult)) }
    }
}
extension RNGLocationTask{
    convenience init(context: NSManagedObjectContext, dummyVar: Bool){
        self.init(context: context)
        self.name = "Explore Generation Area"
        self.location  = Location(context: context,
                                       name: "Generation Area",
                                       area: CLCircularRegion(center: LocationServices.shared.getLocation(), radius: 1000, identifier: UUID().uuidString))
        self.minimumLocationsForCompletion = 1
        self.numberOfGeneratedLocations = 1
    }
    
    override func start() throws{
        try super.start()
        generateLocations()
        for t in self.randomLocationTasks!{
            try (t as! SingleLocationTask).start()
        }
    }
    
    override func initDependenciesAndTrackers() throws {
        for t in self.randomLocationTasks!{
            try (t as! SingleLocationTask).initDependenciesAndTrackers()
        }
    }
    
    override func endDependenciesAndTrackers() {
        for t in self.randomLocationTasks!{
            (t as! SingleLocationTask).endDependenciesAndTrackers()
        }
    }
    
    func generateLocations(){
        for i in 0..<self.numberOfGeneratedLocations{
            let newLoc = Location(context: self.managedObjectContext!, name: "Location \(i+1)", area: CLCircularRegion(center: LocationServices.generateRandomLocation(origin: location!.center(), minRange: Double(self.minGenerationRange), maxRange: location!.radius), radius: 37.5,identifier: UUID().uuidString))
            newLoc.temporary = true
            let slt = SingleLocationTask(context: self.managedObjectContext!)
            slt.location = newLoc
            self.addToRandomLocationTasks(slt)
        }
    }
    
    override func reset(){
        super.reset()
        for entity in self.randomLocationTasks!{
            let entity = entity as! SingleLocationTask
            entity.reset()
            self.managedObjectContext?.delete(entity.location!)
            self.managedObjectContext?.delete(entity)
        }
        self.randomLocationTasks = NSSet()
    }
    
    override func update() throws {
        try super.update()
        
        var anyActive = false
        for task in self.randomLocationTasks!{
            
            let task = task as! SingleLocationTask
            try task.update()
            if !task.completed { anyActive = true }
        }
        if !anyActive {self.completed = true}
        
    }
    
    override func currentStatus() -> String {
        
        return !(self.quest?.isActive ?? true) ? "" : " \(self.completedAreas)/\(self.numberOfGeneratedLocations) Locations Visited"
    }
    
}
