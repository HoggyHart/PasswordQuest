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
    
    func generateExampleLocations(){
        //create example random locations
        if !task!.quest!.isActive{
            task!.reset()
            task?.generateLocations()
        }
    }
//    var area: LocationOccupationQuestTask
//    var markerRenderer: MKCircleRenderer?
    override func refreshMarkers() {
        //create example random locations
        generateExampleLocations()
        //and add them to the drawn areas
        updateQuestMarkers(forceRefresh: true)
        super.refreshMarkers()
    }
    
    func updateQuestMarkers(forceRefresh: Bool = false){
        //if number of areas has changed
        if markers.count != task!.numberOfGeneratedLocations+1 || forceRefresh{//+1 for the origin location
            areas = [task!.location!]
            for lTask in task!.randomLocationTasks!.allObjects{
                let lTask = lTask as! SingleLocationTask
                guard let location = lTask.location else {continue} //TODO: make throw
                areas.append(location)
            }
        }
        //TODO: mutual code with SLTask, makee shared method to call instead
        for lTask in task!.randomLocationTasks!.allObjects{
            let lTask = lTask as! SingleLocationTask
            let location = lTask.location!
            guard let markerRenderer = markers[location.objectID]?.first!.key else {continue}
            if lTask.completed{
                markerRenderer.strokeColor = UIColor.systemGreen
                markerRenderer.fillColor = UIColor.systemGreen.withAlphaComponent(0.2)
                markerRenderer.strokeEnd = 0
            }
            //else indicate progress
            else{
                //doesnt throw an error for dividing by 0 :)
                markerRenderer.strokeEnd = (lTask.requiredOccupationDuration-lTask.recordedOccupationTime) / lTask.requiredOccupationDuration
            }
        }
    }
}
