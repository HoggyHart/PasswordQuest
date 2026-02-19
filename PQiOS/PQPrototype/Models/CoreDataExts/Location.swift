//
//  Location.swift
//  PQPrototype
//
//  Created by William Hart on 18/02/2026.
//

import Foundation
import CoreLocation

extension Location{
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
