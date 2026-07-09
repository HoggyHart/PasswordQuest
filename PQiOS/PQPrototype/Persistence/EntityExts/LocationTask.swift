//
//  LocationTask.swift
//  PQPrototype
//
//  Created by William Hart on 08/07/2026.
//

import Foundation

extension LocationTask{
    override func start() throws{
        reset()
        if true{
            LocationServices.shared.verifyAppLocationPerms()
            LocationServices.shared.locationManager.startUpdatingLocation()
        }
    }
    
    override func update() throws {
        try super.update()
        //TODO: change this whole tbd "if not updating, start updating" thing (called elsewhere too i think) to a method in LocationServices titled "continueUpdating()" maybe
        //TODO: throw a "no permission to track location" error if needed
        if true{
            LocationServices.shared.verifyAppLocationPerms()
            LocationServices.shared.locationManager.startUpdatingLocation()
        }
    }
}
