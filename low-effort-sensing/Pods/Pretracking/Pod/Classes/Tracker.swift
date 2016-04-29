//
//  Tracker.swift
//  Testing
//
//  Created by Yongsung on 1/26/16.
//  Copyright © 2016 Delta. All rights reserved.
//
import CoreLocation

public class Tracker: NSObject, CLLocationManagerDelegate{
    var distance: Double?
    var latitude: Double?
    var longitude: Double?
    var radius: Double?
    var accuracy: Double?
    var loc_name: String?
    var locationDic: Dictionary<String,Double> = [:]
    private var myLocation = CLLocation()
    private let locationManager = CLLocationManager()
    
    required public override init() {
        super.init()
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.delegate = self
    }
    
    public class var sharedManager: Tracker {
        return Constants.sharedManager
    }
    
    private struct Constants {
        static let sharedManager = Tracker()
    }
    
    public func setupParameters(distance: Double, latitude: Double, longitude: Double, radius: Double, accuracy: CLLocationAccuracy, name: String) {
        self.distance = distance
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        myLocation = CLLocation(latitude: self.latitude!, longitude: self.longitude!)
        self.accuracy = accuracy
        self.loc_name = name
        locationManager.desiredAccuracy = self.accuracy!
        self.locationDic[name] = distance
        print("initialization")
        
    }
    
    public func initLocationManager() {
        print("init location manager here")
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        
        let center = CLLocationCoordinate2DMake(self.latitude!, self.longitude!)
        let monitoringRegion = CLCircularRegion.init(center: center, radius: 100, identifier: self.loc_name!)
        
        locationManager.startMonitoringForRegion(monitoringRegion)
        locationManager.startUpdatingLocation()
    }
    
    public func addLocation(distance: Double, latitude: Double, longitude: Double, radius: Double, name: String) {
        let center = CLLocationCoordinate2DMake(latitude, longitude)
        let monitoringRegion = CLCircularRegion.init(center: center, radius: radius, identifier: name)
        locationManager.startMonitoringForRegion(monitoringRegion)
        self.locationDic[name] = distance
    }
    
    public func removeLocation(name: String) {
        let monitoredRegion = locationManager.monitoredRegions
        for region in monitoredRegion {
            if name == region.identifier {
                locationManager.stopMonitoringForRegion(region)
                print("stopped monitoring \(name)")
//                print(locationManager.monitoredRegions)
            }
        }
        self.locationDic.removeValueForKey(name)
    }
    
    public func notifyPeople() {
        print("do your thing here")
    }
    
    public func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations.last!
        let age = -lastLocation.timestamp.timeIntervalSinceNow
        if (lastLocation.horizontalAccuracy < 0 || lastLocation.horizontalAccuracy > 65.0) {
            return
        }
        
        if (age > 20) {
            return
        }
        
        for region in locationManager.monitoredRegions {
            if let monitorRegion = region as? CLCircularRegion {
                let monitorLocation = CLLocation(latitude: monitorRegion.center.latitude, longitude: monitorRegion.center.longitude)
                
                let distanceToLocation = lastLocation.distanceFromLocation(monitorLocation)
//                print(self.locationDic)
                let distance = self.locationDic[monitorRegion.identifier]
//                print("distance is \(distanceToLocation)")
                if (distanceToLocation <= distance) {
                    notifyPeople()
//                    print("distance threshold is: \(distance)")
                }
            }

        }

    }
    
    public func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print(error.description)
    }
    
    public func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        print("did enter region \(region.identifier)")
    }
    
    public func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        locationManager.desiredAccuracy = self.accuracy!
        print("did exit region \(region.identifier)")
    }
    
}