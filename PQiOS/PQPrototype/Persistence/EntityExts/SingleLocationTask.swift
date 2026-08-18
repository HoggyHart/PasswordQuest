//
//  LocationOccupationQuestTask.swift
//  PQPrototype
//
//  Created by William Hart on 11/02/2026.
//

import Foundation
import MapKit
import CoreData

extension SingleLocationTask: MKMapViewDelegate {
    
    override public var currentReward: Int{  //TODO: include "if incompletion rewards == true" when that var is added
        get { if completed { return maxReward} else {return Int(self.recordedOccupationTime/60*0.1)}}
    }
    override public var maxReward: Int{
        get { return max(Int(self.requiredOccupationDuration/60*0.5),5)} //TODO: add a user 'origin/home' location var for the app so that distance from home can be added to these calcs to replace min reward of 5. Because if quest is 'stay where you are for 0 seconds' it shouldnt have the same reward as 'go to a place 1km from home and be there for 0 seconds'. This is both an incentive to move AND an anti-cheat measure
    }
    
    convenience init(context: NSManagedObjectContext, dummyVar: Bool = false){
        self.init(context: context)
        self.name = "Unnamed Location Task"
       // let loc = Location(context: context,name: "Unnamed Location",area: CLCircularRegion(center: LocationServices.service.getLocation(), radius: 25, identifier: UUID().uuidString))
      //  loc.addToTasks(self)
        self.occupiedAtLastUpdate = false
    }
    
    override func start() throws{
        try super.start()
    }
    override func initDependenciesAndTrackers() throws {
        try super.initDependenciesAndTrackers()
        guard let location = self.location else {
            throw InvalidTaskError(task: self.name!, invalidAttribute: "Location is nil")
        }
        LocationServices.shared.startTrackingRegion(region: location.asRegion(),forTask: self.objectID)
        lastUpdate = Date.now
    }
    
    override func endDependenciesAndTrackers() {
        guard let location = self.location else {
            return }
        LocationServices.shared.stopTrackingRegion(regionID: location.regionIdentifier, forTask: self.objectID)
    }
    
    //lastUpdate is set after this method in update() and in LocationManager.onRegionEnter/Exit
    func updateRecordedTime(){
        if occupiedAtLastUpdate{
            let timeToClear = Date.now.timeIntervalSince(lastUpdate!)
            recordedOccupationTime += timeToClear
            
            if recordedOccupationTime >= requiredOccupationDuration{
                recordedOccupationTime = requiredOccupationDuration
                completed = true
                if location != nil  {LocationServices.shared.stopTrackingRegion(regionID: location!.regionIdentifier,forTask: self.objectID)}
            }
        }
    }
    //func called during liveUpdates
    //calcDistance may not be necessary if the locationmanager automatically handles region entering/exiting
    override func update() throws {
        try super.update()
        
        guard let taskArea = location else { throw InvalidTaskError(task: self.name!, invalidAttribute: "Location") } //in case it somehow gets deleted mid-quest
        
        guard let curPos = LocationServices.shared.locationManager.location?.coordinate else {return} //TODO: throw location error (wont end task)
        if stayInside == (LocationServices.calcDistance(p1: curPos, p2: taskArea.center()) <= taskArea.radius){
            updateRecordedTime()
            occupiedAtLastUpdate = true
        }else{
            occupiedAtLastUpdate = false
        }
        lastUpdate = Date.now
    }
    
    override func reset(){
        super.reset()
        lastUpdate = nil
        occupiedAtLastUpdate = false
        recordedOccupationTime = 0
        if location != nil  {LocationServices.shared.stopTrackingRegion(regionID: location!.regionIdentifier,forTask: self.objectID)}
    }
    
    var completionPercent: Double{
        get{
            if completed { return 100.0 }
            return recordedOccupationTime/(requiredOccupationDuration == 0 ? 1 : requiredOccupationDuration) * 100.0}
    }
    override func toString() -> String{
        var magnitude: Double
        var unit: String
        if requiredOccupationDuration < 60 { magnitude = 1; unit = "seconds" }
        else if requiredOccupationDuration < 3600 { magnitude = 60; unit = "minutes"}
        else { magnitude = 3600; unit = "hours" }
        
        let nf = NumberFormatter()
        nf.roundingMode = .up
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 3
        return (nf.string(for:  self.completionPercent) ?? "?")+"% of \(requiredOccupationDuration/magnitude) \(unit) spent at \(self.location!.name!)"
    }
    
    override func currentStatus() -> String {
        if !(self.quest?.isActive ?? true) { return "" }
        let nf = NumberFormatter()
        nf.roundingMode = .up
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 3
        return nf.string(for:  self.completionPercent)! + "%"
    }
    
    @MainActor
    public func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer{
        if overlay is MKCircle{
            let circR = MKCircleRenderer(circle: overlay as! MKCircle)
            circR.strokeColor = UIColor.systemYellow
            circR.fillColor = UIColor.systemYellow.withAlphaComponent(0.2)
            circR.lineWidth = 3
            return circR
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}
