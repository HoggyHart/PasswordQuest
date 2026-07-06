//
//  RandomLocationQuestTask.swift
//  PQPrototype
//
//  Created by William Hart on 26/05/2026.
//

import Foundation
import MapKit

class RNGLTaskViewModel: LocationViewModel {
    //optional to allow creation of model, but is treated as non-optional
    var task: RNGLocationTask? = nil
    var mapMarkerUpdater: Timer?
    
    func loadTaskData(task: RNGLocationTask){
        self.task = task
        mapMarkerUpdater = mapMarkerUpdater ?? Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
              self.updateQuestMarkers()
        })
    }
//    var area: LocationOccupationQuestTask
//    var markerRenderer: MKCircleRenderer?
    override func refreshMarkers() {
        //create example random locations
        if !task!.quest!.isActive{
            //.start deletes current locations and generates new ones
            do{
                try task?.start()
            }catch{}
        }
        //and add them to the drawn areas
        updateQuestMarkers(forceRefresh: true)
        super.refreshMarkers()
    }
    
    func updateQuestMarkers(forceRefresh: Bool = false){
        //if number of areas has changed
        if markers.count != task!.randomLocations!.count+1 || forceRefresh{//+1 for the origin location
            areas = [task!.location!]
            areas.append(contentsOf: task!.randomLocations!.allObjects as! [Location])
        }
    }
}
