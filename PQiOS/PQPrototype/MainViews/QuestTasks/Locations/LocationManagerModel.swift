//
//  LocationTaskViewModel.swift
//  PQPrototype
//
//  Created by William Hart on 13/03/2026.
//

import Foundation
import MapKit
import CoreLocation

class LocationManagerModel : NSObject, ObservableObject, MKMapViewDelegate{
    
    var map: MKMapView = MKMapView()
    
    var locationCircles: [MKOverlay] = []
    var locationPins: [MKAnnotation] = []
    
    
  //  var mapMarkerUpdater: Timer? = nil
    override init(){
        super.init()
        map.setRegion(MKCoordinateRegion(center:
                                            LocationServices.service.getLocation(),
                                           span: MKCoordinateSpan(
                                            latitudeDelta: 0.005519282850478646,
                                            longitudeDelta: 0.0040233132599780674)),
                      animated: true)
        map.showsUserLocation=true
        map.isZoomEnabled = true
        
        map.delegate = self
    }
    
    func registerLocation(loc: Location){
        //add a central pin to mark the quest (to be replaced with a quest-related png (i.e. goblin tower png)
        //this makes it easily visible when zoomed out
        let questPin = MKPointAnnotation()
        questPin.title = loc.name
        questPin.coordinate = loc.center()
        
        //create circle to be drawn
        let questCircle = MKCircle(center: loc.center(), radius: loc.radius)
        
        //get overlay renderer we just created with .addOverlay in case we want to alter it
        self.locationPins.append(questPin)
        self.locationCircles.append(questCircle)
        
        self.showArea(areaIndex: self.locationPins.count-1)
    }
    func unregisterLocation(areaIndex: Int){
        hideArea(areaIndex: areaIndex)
        locationCircles.remove(at: areaIndex)
        locationPins.remove(at: areaIndex)
    }
    
    func hideArea(areaIndex: Int){
        map.removeOverlay(locationCircles[areaIndex])
        map.removeAnnotation(locationPins[areaIndex])
    }
    
    func showArea(areaIndex: Int){
        map.addOverlay(locationCircles[areaIndex], level:.aboveRoads)
        map.addAnnotation(locationPins[areaIndex])
    }
    
    
    
    func centerOn(_ location: Location){
        map.setRegion(MKCoordinateRegion(center:
                                            location.center(),
                                           span: MKCoordinateSpan(
                                            latitudeDelta: 0.005519282850478646,
                                            longitudeDelta: 0.0040233132599780674)),
                      animated: true)
    }
    
    func clearMap(){
        map.removeAnnotations(map.annotations)
        map.removeOverlays(map.overlays)
    }
    
    // -- Drawing the overlay delegate method
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
