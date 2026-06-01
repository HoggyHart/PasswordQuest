//
//  LocationTaskViewModel.swift
//  PQPrototype
//
//  Created by William Hart on 19/02/2026.
//

import Foundation
import MapKit
class SingleLocationTaskViewModel: NSObject, ObservableObject{
    //optional to allow creation of model, but is treated as non-optional
    var task: SingleLocationTask? = nil
    var mapModel: LocationViewModel? = nil
    var mapMarkerUpdater: Timer?
    
    func loadTaskData(task: SingleLocationTask){
        self.task = task
        mapMarkerUpdater = mapMarkerUpdater ?? Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
              self.updateQuestMarkers()
        })
    }
    
    func updateQuestMarkers(){
        guard let task = task else {return}
        guard let location = task.location else {return}
        
        let markerRenderer = mapModel!.markers[location.objectID]!.first!.key
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
}
