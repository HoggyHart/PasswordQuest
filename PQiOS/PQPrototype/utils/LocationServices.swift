import Foundation
import CoreLocation
import CoreData

class LocationServices: NSObject, ObservableObject, CLLocationManagerDelegate{
    
    static let service = LocationServices()
    //---LOCATION MANAGER SETUP/OVERRIDES---
    let locationManager = CLLocationManager() //creating LM calls verify...() automatically via locationManagerDidChangeAuthorization()
    @Published var latestLocation: CLLocation?
    
    public func isAuthorized() -> Bool{
        return locationManager.authorizationStatus == .authorizedAlways
        
    }
    public func getLocation() -> CLLocationCoordinate2D{
        //returns current live location, or returns 0,0 if locationManager not inititalised, and 50,50 if just no current location is available
        guard let location = latestLocation?.coordinate else {
            return CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }
        return location
    }
    //---ERRORS
    private var err_globalLocationNotEnabled = true
    private var err_appLocationNotEnabled = true
    
    //1 instance of LocationServices must be made to set a delegate object for the locationManager
    //this is because CLLocationManager.delegate cannot be self in a static method since there is no self
    //and init cannot be used because it'd need to override
    
    
    override init(){
        self.context = PersistenceController.shared.container.newBackgroundContext()
        self.context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        super.init()
        verifyAppLocationPerms()
        initLocationManager()
    }
    func initLocationManager(){
        locationManager.delegate = self //! forces optional to be considered as object
        print("LocationServices: delegate set")
        locationManager.activityType = CLActivityType.fitness //not sure what this does. I guess delay between updates maybe? might just be stat-tracking
        err_globalLocationNotEnabled = false
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.pausesLocationUpdatesAutomatically = false
        err_globalLocationNotEnabled = true
        //used in View object to display error
    }
    
    func verifyAppLocationPerms() {
        print("location perms: \(locationManager.authorizationStatus)")
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse: // Now it's legal to request Always
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            locationManager.allowsBackgroundLocationUpdates = true
        case .restricted, .denied:
            // user must go to settings
            break
        @unknown default:
            break
        }
    }
    
    func locationAvailable() -> Bool{
        return locationManager.location != nil
    }
    //gets distance in meters
    func currentDistanceToPoint(point: CLLocationCoordinate2D) -> Double?{
        guard let curLoc = locationManager.location else { return nil }
        
        let otherPoint = CLLocation(latitude: point.latitude, longitude: point.longitude)
        
        return curLoc.distance(from: otherPoint)
    }
    
    static func generateRandomLocation(origin: CLLocationCoordinate2D, minRange: Double, maxRange: Double) -> CLLocationCoordinate2D{ // https://www.movable-type.co.uk/scripts/latlong.html
        //at the distances being used in this app, the curvature of the earth is irrelevant, so we can assume the area in play is a flat plane
        //this means we can ignore the effect on the arc distance from a 1˚ change in longitude relevant to different magnitudes of latitude
        //so basically we can just generate a random distance point within a circle instead of an oval
        //WWWRRROOOOINNNNGGGGGG!!!!!!!!! long must still be calc'd with lat impact in mind
        //generate a random distance within range, then generate a random angle in 2pi radians
        
        let lat = origin.latitude * Double.pi / 180
        let distance: Double = minRange>=maxRange ? Double(minRange) : Double(Double.random(in: 0..<(maxRange-minRange)) + minRange)//rand() % range
        let bearing: Double = Double.random(in: 0..<(2*Double.pi)) //rand() % 2pi
        let ad: Double = (distance/6378000) //angular distance, converted to radians for calculations
  
        let newLat = asin( sin(lat) * cos(ad) + cos(lat) * sin(ad) * cos(bearing)) * 180 / Double.pi
     // φ2 =         asin( sin φ    ⋅ cos δ   + cos φ1   ⋅ sin δ   ⋅ cos θ )
        let newLon = origin.longitude + atan2( sin(bearing) * sin( ad ) * cos(lat), cos(ad) - sin(lat) * sin(newLat*Double.pi/180))*180/Double.pi;
//      λ2 =         λ1               + atan2( sin θ        ⋅ sin δ     ⋅ cos φ1  , cos δ   − sin φ1   ⋅ sin φ2 )
        let result: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: newLat, longitude: newLon)
        return result
        
    }
    
    static func calcDistance(p1: CLLocationCoordinate2D, p2: CLLocationCoordinate2D) -> Double{ // https://www.movable-type.co.uk/scripts/latlong.html
        
        

        let r: Double = 6378000; // metres
        let lat1 = p1.latitude * Double.pi/180; // φ, λ in radians
        let lat2 = p2.latitude * Double.pi/180;
        let lat_diff = (p2.latitude-p1.latitude) * Double.pi/180;
        let lon_diff = (p2.longitude-p1.longitude) * Double.pi/180;

        let a = sin(lat_diff/2) * sin(lat_diff/2) +
             cos(lat1) * cos(lat2) *
             sin(lon_diff/2) * sin(lon_diff/2);
        let c = 2 * atan2(sqrt(a), sqrt(1-a));

        let d = r * c; // in metres
        
        return d
    }
    //---DELEGATE METHODS---
    
    //i think this gets called automatically when the func's name occurs
    @objc func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("changed location manager auth")
        verifyAppLocationPerms()
        initLocationManager()
    }
    
    @objc func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("__Updating Locations__")
        guard let loc = locations.last else { return }
        latestLocation = loc
        print("__Updated Locations__")
    }
    
    @objc func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
    }
    
    
    let context: NSManagedObjectContext
    
    func taskFor(region: CLRegion) -> LocationOccupationQuestTask?{
        do{
            let tasks = try context.fetch(LocationOccupationQuestTask.fetchRequest())
            for t in tasks{
                if t.taskArea!.identifier == region.identifier{
                    return t
                }
            }
        }catch{}
        return nil
    }
    
    @objc func locationManager(
        _ manager: CLLocationManager,
        didEnterRegion region: CLRegion
    ){
        print("entered region at \(Date.now)")
        guard let task = taskFor(region: region) else { return }
        task.occupiedAtLastUpdate = true
        task.lastUpdate = Date.now
        do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("left region at \(Date.now)")
        guard let task = taskFor(region: region) else { return }
        task.updateRecordedTime()
        task.occupiedAtLastUpdate = false
        task.lastUpdate = Date.now
        do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
    }
    
}
