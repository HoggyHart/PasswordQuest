//
//  LocationTaskViewModel.swift
//  PQPrototype
//
//  Created by William Hart on 01/01/2026.
//

import Foundation
import MapKit
import CoreLocation

class LocationMapModel : NSObject, ObservableObject, MKMapViewDelegate{
    
    var area: Location? = nil
    var editing: Bool = false
    var map: MKMapView = MKMapView()
    var markerRenderer: MKCircleRenderer? = nil
    
  //  var mapMarkerUpdater: Timer? = nil
    override init(){
        //init map
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
        
        //init interaction
        let gr = UITapGestureRecognizer(target: self, action: #selector(LocationMapModel.clickToSetLocation))
        map.addGestureRecognizer(gr)
        
    }
    
    @objc public func clickToSetLocation(recognizer: UIGestureRecognizer){
        if !editing { return }
        
        let displayTapCoords = recognizer.location(in: map)
        let coords = map.convert(displayTapCoords, toCoordinateFrom: map)
        
        area?.latitude = coords.latitude
        area?.longitude = coords.longitude
        
        self.updateMarker()
    }
    
    func markArea(area: Location){
        //center map on location
        self.area = area
        
        //add a central pin to mark the quest (to be replaced with a quest-related png (i.e. goblin tower png)
        //this makes it easily visible when zoomed out
        let questPin = MKPointAnnotation()
        questPin.title = area.name
        questPin.coordinate = area.center()
        
        //create circle to be drawn
        let questCircle = MKCircle(center: area.center(), radius: area.radius)
        
        //add pin to the map
        self.map.addAnnotation(questPin)
        //draw the circular area
        self.map.addOverlay(questCircle, level:.aboveRoads)
        //get overlay renderer we just created with .addOverlay in case we want to alter it
        self.markerRenderer = self.map.renderer(for: questCircle) as! MKCircleRenderer?
        
    }
    
    func updateMarker(){
        //annotation stuff is get-only, so delete them, create new ones, and re-draw
        clearMap()
        //and re-draw
        guard let area = area else {return}
        self.markArea(area: area)
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
