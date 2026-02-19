//
//  LocationTaskViewModel.swift
//  PQPrototype
//
//  Created by William Hart on 01/01/2026.
//

import Foundation
import MapKit
import CoreLocation

class LocationTaskViewModel : ObservableObject{
    
    var area: LocationOccupationQuestTask?
    
    var map: MKMapView = MKMapView()
    var markerRenderer: MKCircleRenderer? = nil
    
    var mapMarkerUpdater: Timer? = nil
    
    init(){
        mapMarkerUpdater = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            self.updateQuestMarkers()
        })
        
    }
    
    func lateInit(area: LocationOccupationQuestTask){
        self.area = area
        //map stuff
        // map.userTrackingMode = .follow
         //longitude min is 0.0005029141584742547, in the interest of having max zoom be 8.0x, standard span is set to 8x the min
         //lat value is obtained by setting these to whatever, and then lat is set based on long. So i set them both to 0.004 (8x 0.0005) and then copied the span as was measured and outputted upon the first call of setBaseSpan()
        map.setRegion(MKCoordinateRegion(center:
                                            area.taskArea!.center(),
                                           span: MKCoordinateSpan(
                                            latitudeDelta: 0.005519282850478646,
                                            longitudeDelta: 0.0040233132599780674)),
                      animated: true)
        map.showsUserLocation=true
       // map.pointOfInterestFilter=MKPointOfInterestFilter(excluding: [])
        map.isZoomEnabled = true
        
        map.delegate = area.self
        
        markQuestsOnMap()
    }
    
    
    func refresh(){
        clearMap()
        markQuestsOnMap()
    }
    func clearMap(){
        map.removeAnnotations(map.annotations)
        map.removeOverlays(map.overlays)
    }
    
    func markQuestsOnMap(){
        
        //add a central pin to mark the quest (to be replaced with a quest-related png (i.e. goblin tower png)
        //this makes it easily visible when zoomed out
        let questPin = MKPointAnnotation()
        questPin.title = area!.taskArea!.name!
        questPin.coordinate = area!.taskArea!.center()
        
        //this shows the area to go to to complete the quest
        let questCircle = MKCircle(center: area!.taskArea!.center(), radius: CLLocationDistance(area!.taskArea!.radius))
        
        self.map.addAnnotation(questPin)
        self.map.addOverlay(questCircle, level:.aboveRoads)
        self.markerRenderer = self.map.renderer(for: questCircle) as! MKCircleRenderer?
        //and then maybe implement some overlay tracking code
    }
    
    //FIX: the first change and last change both cause the view to close
    func updateQuestMarkers(){
        if area!.completed{
            markerRenderer?.strokeColor = UIColor.systemGreen
            markerRenderer?.fillColor = UIColor.systemGreen.withAlphaComponent(0.2)
            markerRenderer?.strokeEnd = 0
        }
        //else indicate progress
        else{
            //doesnt throw an error for dividing by 0 :)
            markerRenderer?.strokeEnd = (area!.requiredOccupationDuration-area!.recordedOccupationTime) / area!.requiredOccupationDuration
        }
    }
}
