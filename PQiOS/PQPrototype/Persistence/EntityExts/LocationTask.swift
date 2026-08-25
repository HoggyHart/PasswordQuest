//
//  LocationTask.swift
//  PQPrototype
//
//  Created by William Hart on 08/07/2026.
//

import Foundation

extension LocationTask{
    override func start() throws{
        try super.start()
    }
    
    override func initDependenciesAndTrackers() throws {
        try super.initDependenciesAndTrackers()
        if true{
            LocationServices.shared.verifyAppLocationPerms()
            LocationServices.shared.locationManager.startUpdatingLocation()
        }
    }
    
    override func update() throws {
        try super.update()
        LocationServices.shared.locationManager.requestLocation()
    }
}
