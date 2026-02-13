//
//  LocationOccupationQuestTask.swift
//  PQPrototype
//
//  Created by William Hart on 11/02/2026.
//

import Foundation
import MapKit

extension LocationOccupationQuestTask: MKMapViewDelegate {
    
    func lateInit(locName: String, taskArea: CLCircularRegion, questDuration: TimeInterval) {
        self.locationName = locName
        self.taskArea = taskArea
        self.recordedOccupationTime = 0
        self.requiredOccupationDuration = questDuration
        if self.requiredOccupationDuration == 0 {self.requiredOccupationDuration = 1}
        self.occupiedAtLastUpdate = false
        super.lateInit(name: "Task: Spend time at "+locationName!)
    }
    override func start() {
        reset()
        lastUpdate = Date.now
        LocationServices.service.verifyAppLocationPerms()
        LocationServices.service.locationManager.startMonitoring(for: taskArea!)
    }
    
    //lastUpdate is set after this method in update() and in LocationManager.onRegionEnter/Exit
    func updateRecordedTime(){
        if occupiedAtLastUpdate{
            let timeToClear = Date.now.timeIntervalSince(lastUpdate!)
            recordedOccupationTime += timeToClear
            
            if recordedOccupationTime >= requiredOccupationDuration{
                recordedOccupationTime = requiredOccupationDuration
                completed = true
            }
        }
    }
    //func called during liveUpdates
    //calcDistance may not be necessary if the locationmanager automatically handles region entering/exiting
    override func update() {
        if completed {return}
        
        let taskArea = taskArea!
        
        guard let curPos = LocationServices.service.locationManager.location?.coordinate else {return}
        
        if LocationServices.calcDistance(p1: curPos, p2: taskArea.center) <= taskArea.radius{
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
        LocationServices.service.locationManager.stopMonitoring(for: taskArea!)
    
    }
    
    override func toString() -> String{
        var magnitude: Double
        var unit: String
        if requiredOccupationDuration < 60 { magnitude = 1; unit = "seconds" }
        else if requiredOccupationDuration < 3600 { magnitude = 60; unit = "minutes"}
        else { magnitude = 3600; unit = "hours" }
        
        let prcnt = recordedOccupationTime/requiredOccupationDuration * 100.0
        let nf = NumberFormatter()
        nf.roundingMode = .up
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 3
        return (nf.string(for:  prcnt) ?? "?")+"% of \(requiredOccupationDuration/magnitude) \(unit) spent at \(locationName!)"
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
