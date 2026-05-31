//
//  RandomLocationQuestTask.swift
//  PQPrototype
//
//  Created by William Hart on 26/05/2026.
//

import Foundation
import MapKit

class RandomLocationQuestTaskViewModel: LocationViewModel {
    //optional to allow creation of model, but is treated as non-optional
    var task: RandomLocationQuestTask? = nil
    var mapMarkerUpdater: Timer?
    
    func loadTaskData(task: RandomLocationQuestTask){
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
            task?.start()
        }
        //and add them to the drawn areas
        updateQuestMarkers()
    }
    
    func updateQuestMarkers(){
        //if area has been removed
        if markers.count != task!.randomLocations!.count+1 {//+1 for the origin location
            areas = [task!.location!]
            areas.append(contentsOf: task!.randomLocations!.allObjects as! [Location])
            super.refreshMarkers()
        }
    }
}
