//
//  LocationTaskViewModel.swift
//  PQPrototype
//
//  Created by William Hart on 13/03/2026.
//

import Foundation
import MapKit
import CoreLocation
import CoreData

class LocationManagerModel : NSObject, ObservableObject, MKMapViewDelegate{
    
    var map: MKMapView = MKMapView()
    var markers: Dictionary<NSManagedObjectID, Dictionary<MKCircle,MKAnnotation>> = [:]
    
    
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
        //if already has loc, ignore
        if self.markers.keys.contains(where: { id in return id == loc.objectID}){return}
        
        let questPin = MKPointAnnotation()
        questPin.title = loc.name
        questPin.coordinate = loc.center()
        //create circle to be drawn
        let questCircle = MKCircle(center: loc.center(), radius: loc.radius)
        
        self.markers.updateValue([questCircle:questPin], forKey: loc.objectID)
        
        self.showArea(areaID: loc.objectID)
    }
    func unregisterLocation(areaID: NSManagedObjectID){
        hideArea(areaID: areaID)
        markers.removeValue(forKey: areaID)
    }
    
    func showArea(areaID: NSManagedObjectID){
        guard let pair = markers[areaID]?.first else {return}
        map.addOverlay(pair.key, level:.aboveRoads)
        map.addAnnotation(pair.value)
    }
    func hideArea(areaID: NSManagedObjectID){
        guard let pair = markers[areaID]?.first else {return}
        map.removeOverlay(pair.key)
        map.removeAnnotation(pair.value)
    }
    func clearMap(){
        map.removeAnnotations(map.annotations)
        map.removeOverlays(map.overlays)
    }
    
    func centerOn(_ location: Location){
        map.setRegion(MKCoordinateRegion(center:
                                            location.center(),
                                            span: MKCoordinateSpan(
                                            latitudeDelta: 0.005519282850478646,
                                            longitudeDelta: 0.0040233132599780674)),
                      animated: true)
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
