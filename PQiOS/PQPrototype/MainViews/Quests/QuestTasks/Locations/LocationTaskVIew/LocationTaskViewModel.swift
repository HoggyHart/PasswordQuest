//
//  LocationTaskViewModel.swift
//  PQPrototype
//
//  Created by William Hart on 19/02/2026.
//

import Foundation
import MapKit
class LocationTaskViewModel: LocationMapModel{
    //optional to allow creation of model, but is treated as non-optional
    var task: LocationOccupationQuestTask? = nil
    var mapMarkerUpdater: Timer?
    
    func loadTaskData(){
        mapMarkerUpdater = mapMarkerUpdater ?? Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
              self.updateQuestMarkers()
        })
    }
//    var area: LocationOccupationQuestTask
//    var markerRenderer: MKCircleRenderer?
    func updateQuestMarkers(){
        if task!.completed{
            markerRenderer?.strokeColor = UIColor.systemGreen
            markerRenderer?.fillColor = UIColor.systemGreen.withAlphaComponent(0.2)
            markerRenderer?.strokeEnd = 0
        }
        //else indicate progress
        else{
            //doesnt throw an error for dividing by 0 :)
            markerRenderer?.strokeEnd = (task!.requiredOccupationDuration-task!.recordedOccupationTime) / task!.requiredOccupationDuration
        }
    }

}
