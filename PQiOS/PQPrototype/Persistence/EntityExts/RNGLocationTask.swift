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
    var completedAreas: Int16{
        get{
            return self.numberOfGeneratedLocations-Int16((self.randomLocations?.count ?? 0))
        }
    }
}
extension RNGLocationTask{
    convenience init(context: NSManagedObjectContext, dummyVar: Bool){
        self.init(context: context)
        self.name = "Visit 1/1 Locations"
        self.location  = Location(context: context,
                                       name: "Generation Area",
                                       area: CLCircularRegion(center: LocationServices.service.getLocation(), radius: 1000, identifier: UUID().uuidString))
        self.minimumLocationsForCompletion = 1
        self.numberOfGeneratedLocations = 1
    }
    
    override func start() {
        reset()
        generateLocations()
    }
    
    func generateLocations(){
        for _ in 0..<self.numberOfGeneratedLocations{
            let newLoc = Location(context: self.managedObjectContext!, name: "TempLocation", area: CLCircularRegion(center: LocationServices.generateRandomLocation(origin: location!.center(), minRange: Double(self.minGenerationRange), maxRange: location!.radius), radius: 37.5,identifier: UUID().uuidString))
            newLoc.temporary = true
            self.addToRandomLocations(newLoc)
        }
    }
    
    override func reset(){
        for entity in self.randomLocations!{
            self.managedObjectContext?.delete(entity as! NSManagedObject)
        }
        self.randomLocations = NSSet()
    }
    
    override func update(){
        if completed {return}
        
        guard let curPos = LocationServices.service.locationManager.location?.coordinate else {return}
        
        for area in self.randomLocations!{
            let area = area as! Location
            
            if LocationServices.calcDistance(p1: curPos, p2: area.center()) <= area.radius{
                
                area.managedObjectContext!.delete(area)
                
            }
        }
    }
    
    
    
}
