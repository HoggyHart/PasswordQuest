//
//  Location.swift
//  PQPrototype
//
//  Created by William Hart on 18/02/2026.
//

import Foundation
import CoreLocation
import CoreData

extension Location{
    
    convenience init(context: NSManagedObjectContext, name: String, area: CLCircularRegion){
        self.init(context: context)
        self.name = name
        self.latitude = area.center.latitude
        self.longitude = area.center.longitude
        self.radius = area.radius
        
    }
    
    func asRegion(questUUID: UUID) -> CLCircularRegion{
        return CLCircularRegion.init(center: self.center(), radius: self.radius, identifier: self.identifier(questUUID: questUUID))
    }
    
    //ensure this returns consistent but unique results across different calls.
    // e.g. Date.now based UUIDs are a no-go since later when identifier comparisons take place this won't return the same thing as before
    func identifier(questUUID: UUID) -> String{
        return self.name!+"_"+questUUID.uuidString
    }
    
    func center() -> CLLocationCoordinate2D{
        return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }
}

