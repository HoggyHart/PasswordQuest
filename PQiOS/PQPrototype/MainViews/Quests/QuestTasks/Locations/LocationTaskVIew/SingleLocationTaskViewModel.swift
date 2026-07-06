//
//  LocationTaskViewModel.swift
//  PQPrototype
//
//  Created by William Hart on 19/02/2026.
//

import Foundation
import MapKit
class SingleLocationTaskViewModel: LocationViewModel{
    //optional to allow creation of model, but is treated as non-optional
    var task: SingleLocationTask? = nil
    var mapMarkerUpdater: Timer?
    
    func loadTaskData(task: SingleLocationTask){
        self.task = task
        
        mapMarkerUpdater = mapMarkerUpdater ?? Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
              self.updateQuestMarkers()
        })
        
        guard let loc = task.location else {return}
       // self.markArea(area: loc)
    }
    
    func updateMap(){
        
    }
    
    func updateQuestMarkers(){
        guard let task = task else {return}
        guard let location = task.location else {return}
        
        guard let markerRenderer = markers[location.objectID]?.first!.key else {return}
        if task.completed{
            markerRenderer.strokeColor = UIColor.systemGreen
            markerRenderer.fillColor = UIColor.systemGreen.withAlphaComponent(0.2)
            markerRenderer.strokeEnd = 0
        }
        //else indicate progress
        else{
            //doesnt throw an error for dividing by 0 :)
            markerRenderer.strokeEnd = (task.requiredOccupationDuration-task.recordedOccupationTime) / task.requiredOccupationDuration
        }
    }
    
    @MainActor
    override public func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer{
        if overlay is MKCircle{
            let circR = MKCircleRenderer(circle: overlay as! MKCircle)
            circR.strokeColor = task!.stayInside ? UIColor.systemYellow : UIColor.systemRed
            circR.fillColor = (task!.stayInside ? UIColor.systemYellow : UIColor.systemRed).withAlphaComponent(0.2)
            circR.lineWidth = 3
            return circR
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}
