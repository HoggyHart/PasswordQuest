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
    
    func asRegion() -> CLCircularRegion{
        return CLCircularRegion.init(center: self.center(), radius: self.radius, identifier: self.regionIdentifier)
    }
    
    var regionIdentifier: String{
        get { return self.objectID.uriRepresentation().absoluteString }
    }
    
    func center() -> CLLocationCoordinate2D{
        return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }
}

