//
//  LocationOccupationQuestTask+CoreDataProperties.swift
//  PQPrototype
//
//  Created by William Hart on 28/12/2025.
//
//

import Foundation
import CoreData
import CoreLocation
import MapKit

extension LocationOccupationQuestTask {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocationOccupationQuestTask> {
        return NSFetchRequest<LocationOccupationQuestTask>(entityName: "LocationOccupationQuestTask")
    }

    @NSManaged public var lastUpdate: Date?
    @NSManaged public var locationName: String?
    @NSManaged public var occupiedAtLastUpdate: Bool
    @NSManaged public var recordedOccupationTime: Double
    @NSManaged public var requiredOccupationDuration: Double
    @NSManaged public var taskArea: CLCircularRegion?

}


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
    
    //lastUpdate is set after this method in update() and LocationManager.onRegionExit
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
    
    override func update() {
        if completed {return}
        
        let taskArea = taskArea!
        
        guard let curPos = LocationServices.service.locationManager.location?.coordinate else {return}
        
        if LocationServices.calcDistance(p1: curPos, p2: taskArea.center) <= taskArea.radius{
            updateRecordedTime()
            occupiedAtLastUpdate = true
        }else{
            occupiedAtLastUpdate=false
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
