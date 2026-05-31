//
//  LocationTaskViewModel.swift
//  PQPrototype
//
//  Created by William Hart on 01/01/2026.
//

import Foundation
import MapKit
import CoreLocation
import CoreData

class LocationViewModel : NSObject, ObservableObject, MKMapViewDelegate{
    
    var areas: [Location] = []
    var selectedLocation: Location? = nil
    var editing: Bool = false
    var map: MKMapView = MKMapView()
    
    var markers: Dictionary<NSManagedObjectID, Dictionary<MKCircleRenderer,MKAnnotation>> = [:]
    
  //  var mapMarkerUpdater: Timer? = nil
    override init(){
        //init map
        super.init()
        map.setRegion(
            MKCoordinateRegion(
                center:
                    LocationServices.service.getLocation(),
                    span: MKCoordinateSpan(
                        latitudeDelta: 0.005519282850478646,
                        longitudeDelta: 0.0040233132599780674
                    )
            ),
            animated: true
        )
        map.showsUserLocation=true
        map.isZoomEnabled = true
        map.delegate = self
        
        //init interaction
        let gr = UITapGestureRecognizer(target: self, action: #selector(LocationViewModel.clickToSetLocation))
        map.addGestureRecognizer(gr)
        
    }
    
    @objc public func clickToSetLocation(recognizer: UIGestureRecognizer){
        if !editing { return }
        guard let selectedLocation = selectedLocation else {return}
        
        let displayTapCoords = recognizer.location(in: map)
        let coords = map.convert(displayTapCoords, toCoordinateFrom: map)
        
        selectedLocation.latitude = coords.latitude
        selectedLocation.longitude = coords.longitude
        
        self.refreshMarkerFor(area: selectedLocation)
    }
    
    func markArea(area: Location){
        //add to list
        if selectedLocation == nil {
            selectedLocation = area
        }
        
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
        let renderer = self.map.renderer(for: questCircle) as! MKCircleRenderer
        //get overlay renderer we just created with .addOverlay in case we want to alter it
        
        self.markers.updateValue([renderer:questPin], forKey: area.objectID)
        
    }
    
    func refreshMarkers(){
        //annotation stuff is get-only, so delete them, create new ones, and re-draw
        clearMap()
        //and re-draw
        for area in areas {
            self.markArea(area: area)
        }
    }
    func clearMap(){
        self.markers = [:]
        map.removeAnnotations(map.annotations)
        map.removeOverlays(map.overlays)
    }
    func removeMarkerFor(area: Location){
        let pair = self.markers.removeValue(forKey: area.objectID)
        map.removeOverlay(pair!.first!.key.circle)
        map.removeAnnotation(pair!.first!.value)
    }
    func refreshMarkerFor(area: Location){
        removeMarkerFor(area: area)
        markArea(area: area)
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
