//
//  MyPretracker.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 4/29/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import Foundation
import CoreLocation
import Parse

public class MyPretracker: NSObject, CLLocationManagerDelegate {
    // tracker parameters and storage variables
    var distance: Double = 20.0
    var radius: Double = 150.0
    var accuracy: Double = kCLLocationAccuracyBestForNavigation
    var distanceFilter: Double = -1.0
    
    var locationDic: [String: [String: Any]] = [:]
    var locationManager: CLLocationManager?
    
    var parseRefreshTimer: NSTimer? = NSTimer() // refreshing locations being tracked
    
    let appUserDefaults = NSUserDefaults.init(suiteName: "group.com.delta.les")
    var window: UIWindow?
    
    // background task
    let backgroundTaskManager = BackgroundTaskManager()
    let bgTask: BackgroundTaskManager = BackgroundTaskManager.sharedBackgroundTaskManager()
    
    var timer: NSTimer? = NSTimer()
    var delay10Seconds: NSTimer? = NSTimer()
    
    // MARK: Initializations, getters, and setters
    required public override init() {
        super.init()
        
        self.locationManager = CLLocationManager()
        guard let locationManager = self.locationManager else {
            return
        }
        
        locationManager.delegate = self
    }
    
    public static let sharedManager = MyPretracker()
    
    public func setupParameters(distance: Double?, radius: Double?, accuracy: CLLocationAccuracy?, distanceFilter: Double?) {
        print("Setting up tracker parameters")
        
        // assign class variables values from caller's input
        if let unwrappedDistance = distance {
            self.distance = unwrappedDistance
        }
        if let unwrappedRadius = radius {
            self.radius = unwrappedRadius
        }
        if let unwrappedAccurary = accuracy {
            self.accuracy = unwrappedAccurary
        }
        if let unwrappedDistanceFilter = distanceFilter {
            self.distanceFilter = unwrappedDistanceFilter
        }
        
        // set location manager parameters
        locationManager!.desiredAccuracy = self.accuracy
        locationManager!.distanceFilter = self.distanceFilter
    }
    
    public func clearAllMonitoredRegions() {
        for region in locationManager!.monitoredRegions {
            locationManager!.stopMonitoringForRegion(region)
        }
    }
    
    public func getAuthorizationForLocationManager() {
        print("Requesting authorization for always-on location")
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            locationManager!.requestAlwaysAuthorization()
        }
    }
    
    public func initLocationManager() {
        clearAllMonitoredRegions()
        
        locationManager!.allowsBackgroundLocationUpdates = true
        locationManager!.pausesLocationUpdatesAutomatically = false
        locationManager!.startUpdatingLocation()
        
        // print debug string with all location manager parameters
        let locActivity = locationManager!.activityType == .Other
        let locAccuracy = locationManager!.desiredAccuracy
        let locDistance = locationManager!.distanceFilter
        let locationManagerParametersDebugString = "Manager Activity = \(locActivity)\n" +
            "Manager Accuracy = \(locAccuracy)\n" +
            "Manager Distance Filter = \(locDistance)\n"
        
        let authStatus = CLLocationManager.authorizationStatus() == .AuthorizedAlways
        let locServicesEnabled = CLLocationManager.locationServicesEnabled()
        let locationManagerPermissionsDebugString = "Location manager setup with following parameters:\n" +
            "Authorization = \(authStatus)\n" +
            "Location Services Enabled = \(locServicesEnabled)\n"
        
        print("Initialized Location Manager Information:\n" + locationManagerPermissionsDebugString + locationManagerParametersDebugString)
    }
    
    public func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        initLocationManager()
        beginMonitoringParseRegions()
    }
    
    // MARK: - Location Functions
    func refreshLocationsFromParse() {
        print("refreshing tracked locations")
        clearAllMonitoredRegions()
        beginMonitoringParseRegions()
    }
    
    func beginMonitoringParseRegions() {
        PFGeoPoint.geoPointForCurrentLocationInBackground {
            (geoPoint: PFGeoPoint?, error: NSError?) -> Void in
            if error == nil {
                PFCloud.callFunctionInBackground("retrieveLocationsForTracking",
                                                withParameters: ["latitude": (geoPoint?.latitude)!,
                                                                 "longitude": (geoPoint?.longitude)!,
                                                                 "vendorId": vendorId,
                                                                 "count": 10]) {
                    (foundObjs: AnyObject?, error: NSError?) -> Void in
                    if error == nil {
                        // parse response
                        if let foundObjs = foundObjs {
                            let foundObjsArray = foundObjs as! [AnyObject]
                            var monitoredHotspotDictionary: [String : AnyObject] = [String : AnyObject]()
                            
                            for object in foundObjsArray {
                                if let object = object as? PFObject {
                                    let currGeopoint = object["location"] as! PFGeoPoint
                                    let currLat = currGeopoint.latitude
                                    let currLong = currGeopoint.longitude
                                    let id = object.objectId!
                                    self.addLocation(nil, latitude: currLat, longitude: currLong, radius: nil, name: id)
                                    
                                    // Add data to user defaults
                                    var unwrappedEntry = [String : AnyObject]()
                                    unwrappedEntry["latitude"] = currLat
                                    unwrappedEntry["longitude"] = currLong
                                    unwrappedEntry["id"] = id
                                    unwrappedEntry["tag"] = object["tag"] as! String
                                    let info : [String : AnyObject]? = object["info"] as? [String : AnyObject]
                                    unwrappedEntry["info"] = info
                                    
                                    monitoredHotspotDictionary[id] = unwrappedEntry
                                }
                            }
                            // save regions to user defaults
                            self.appUserDefaults?.setObject(monitoredHotspotDictionary, forKey: savedHotspotsRegionKey)
                            self.appUserDefaults?.synchronize()
                            
                            // refresh data every 10 minutes
                            self.parseRefreshTimer = NSTimer.scheduledTimerWithTimeInterval(10.0 * 60.0,
                                                                                            target: self,
                                                                                            selector: #selector(MyPretracker.refreshLocationsFromParse),
                                                                                            userInfo: nil,
                                                                                            repeats: false)
                            
                            // reset accuracy and distance filter to original
                            self.locationManager!.desiredAccuracy = self.accuracy
                            self.locationManager!.distanceFilter = self.distanceFilter
                        }
                    } else {
                        print("Error in querying regions from Parse: \(error). Trying again.")
                        self.beginMonitoringParseRegions()
                    }
                }
            }
        }
    }
    
    // MARK: Adding/Removing Locations
    public func addLocation(distance: Double?, latitude: Double, longitude: Double, radius: Double?, name: String) {
        // check if optional distance and radius values are set
        var newLocationDistance: Double = self.distance
        if let unwrappedDistance = distance {
            newLocationDistance = unwrappedDistance
        }
        
        var newLocationRadius: Double = self.radius
        if let unwrappedRadius = radius {
            newLocationRadius = unwrappedRadius
        }
        
        // create and start monitoring new region
        let newRegionCenter = CLLocationCoordinate2DMake(latitude, longitude)
        let newRegionForMonitoring = CLCircularRegion.init(center: newRegionCenter, radius: newLocationRadius, identifier: name)
        
        locationManager!.startMonitoringForRegion(newRegionForMonitoring)
        self.locationDic[name] = ["distance": newLocationDistance, "withinRegion": false, "notifiedForRegion": false]
    }
    
    public func removeLocation(name: String) {
        if self.locationDic.removeValueForKey(name) != nil {
            let monitoredRegions = locationManager!.monitoredRegions
            print(locationManager!.monitoredRegions)
            for region in monitoredRegions {
                if name == region.identifier {
                    locationManager!.stopMonitoringForRegion(region)
                    print("stopped monitoring \(name)")
                }
            }
        }
    }
    
    // MARK: Pre-tracking algorithm and notifications
    public func notifyIfWithinDistance(lastLocation: CLLocation) {
        print("User position \(lastLocation), course \(lastLocation.course) and, elevation \(lastLocation.altitude) with location accuracy \(locationManager?.desiredAccuracy)")
        
        // check if location update is recent and accurate enough
        let age = -lastLocation.timestamp.timeIntervalSinceNow
        if (lastLocation.horizontalAccuracy < 0 || lastLocation.horizontalAccuracy > 65.0 || age > 20) {
            return
        }
        
        // compute distance from current point to all monitored regions and notifiy if close enough
        var distanceToRegions: [String: String] = [:]
        
        for region in locationManager!.monitoredRegions {
            if let monitorRegion = region as? CLCircularRegion {
                let monitorLocation = CLLocation(latitude: monitorRegion.center.latitude, longitude: monitorRegion.center.longitude)
                let distanceToLocation = lastLocation.distanceFromLocation(monitorLocation)
                
                distanceToRegions[monitorRegion.identifier] = String(distanceToLocation)
                
                if let currentLocationInfo = self.locationDic[monitorRegion.identifier] {
                    let distance = currentLocationInfo["distance"] as! Double
                    let hasBeenNotifiedForRegion = currentLocationInfo["notifiedForRegion"] as! Bool
                    
                    if (distanceToLocation <= distance && !hasBeenNotifiedForRegion) {
                        print(distanceToLocation)
                        self.locationDic[monitorRegion.identifier]?["notifiedForRegion"] = true
                        self.locationDic[monitorRegion.identifier]?["withinRegion"] = true
                        
                        notifyPeople(monitorRegion, locationWhenNotified: lastLocation)
                    }
                }
            }
        }
    }
    
    public func notifyPeople(region: CLRegion, locationWhenNotified: CLLocation) {
        print("notify for region id \(region.identifier)")
        // Get NSUserDefaults
        var monitoredHotspotDictionary = appUserDefaults!.dictionaryForKey(savedHotspotsRegionKey) ?? [:]
        let currentRegion = monitoredHotspotDictionary[region.identifier]
        let message = region.identifier
        
        // Log notification to parse
        let date = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDateString = dateFormatter.stringFromDate(date)
        
        var distanceToLocation: Double = 0.0
        var notificationString: String = ""
        if let monitorRegion = region as? CLCircularRegion {
            let monitorLocation = CLLocation(latitude: monitorRegion.center.latitude, longitude: monitorRegion.center.longitude)
            distanceToLocation = locationWhenNotified.distanceFromLocation(monitorLocation)
            notificationString = "Notified for \(region.identifier) (\(monitorLocation.coordinate.latitude), \(monitorLocation.coordinate.longitude)) when at location (\(locationWhenNotified.coordinate.latitude), \(locationWhenNotified.coordinate.longitude)) at distance \(distanceToLocation)"
        } else {
            notificationString = "Notified for \(region.identifier) (nil, nil) when at location (\(locationWhenNotified.coordinate.latitude), \(locationWhenNotified.coordinate.longitude)) at distance nil"
        }
        
        let newLog = PFObject(className: "pretracking_debug")
        newLog["vendor_id"] = vendorId
        newLog["timestamp_epoch"] = Int(Int64(NSDate().timeIntervalSince1970 * 1000))
        newLog["timestamp_string"] = currentDateString
        newLog["console_string"] = notificationString
        newLog.saveInBackground()
        
        // Show alert if app active, else local notification
        if UIApplication.sharedApplication().applicationState == .Active {
            if let viewController = window?.rootViewController {
                let alert = UIAlertController(title: "Region Entered", message: "You are near \(message).", preferredStyle: .Alert)
                let action = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
                alert.addAction(action)
                viewController.presentViewController(alert, animated: true, completion: nil)
            }
        } else {
            let notification = UILocalNotification()
            notification.alertBody = "You are near \(message)"
            notification.soundName = "Default"
            notification.category = "INVESTIGATE_CATEGORY"
            notification.userInfo = currentRegion as? Dictionary
            UIApplication.sharedApplication().presentLocalNotificationNow(notification)
        }
    }
    
    //MARK: Background Task Functions
    @objc private func stopLocationUpdates() {
        print("Background stopping location updates")
        
        if (timer != nil) {
            timer!.invalidate()
            timer = nil
        }
        
        locationManager!.stopUpdatingLocation()
    }
    
    @objc private func stopLocationWithDelay() {
        print("Background delay 50 seconds")
        
        locationManager!.stopUpdatingLocation()
    }
    
    @objc private func restartLocationUpdates() {
        print("Background restarting location updates")
        
        if (timer != nil) {
            timer!.invalidate()
            timer = nil
        }
        locationManager!.startUpdatingLocation()
    }
    
    func presentNotificationForEnteredRegion(region: CLRegion!) {
        // Get NSUserDefaults
        var monitoredHotspotDictionary = NSUserDefaults.init(suiteName: "group.com.delta.les")?.dictionaryForKey(savedHotspotsRegionKey) ?? [:]
        let currentRegion = monitoredHotspotDictionary[region.identifier]
        let message = region.identifier
        
        // Show alert if app active, else local notification
        if UIApplication.sharedApplication().applicationState == .Active {
            if let viewController = window?.rootViewController {
                let alert = UIAlertController(title: "Region Entered", message: "You have entered region \(message)", preferredStyle: .Alert)
                let action = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
                alert.addAction(action)
                viewController.presentViewController(alert, animated: true, completion: nil)
            }
        } else {
            let notification = UILocalNotification()
            notification.alertBody = "You have entered region \(message)"
            notification.soundName = "Default"
            notification.category = "INVESTIGATE_CATEGORY"
            notification.userInfo = currentRegion as? Dictionary
            UIApplication.sharedApplication().presentLocalNotificationNow(notification)
        }
    }
    
    //MARK: Tracking Location Updates
    public func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations.last!
        notifyIfWithinDistance(lastLocation)
        
        // reset timer
        if (timer != nil) {
            return
        }
        
        let bgTask = BackgroundTaskManager.sharedBackgroundTaskManager()
        bgTask.beginNewBackgroundTask()
        
        // restart location manager after 1 minute
        let intervalLength = 60.0
        let delayLength = intervalLength - 10.0
        
        timer = NSTimer.scheduledTimerWithTimeInterval(intervalLength, target: self, selector: #selector(MyPretracker.restartLocationUpdates), userInfo: nil, repeats: false)
        
        // keep location manager inactive for 10 seconds every minute to save battery
        if (delay10Seconds != nil) {
            delay10Seconds!.invalidate()
            delay10Seconds = nil
        }
        delay10Seconds = NSTimer.scheduledTimerWithTimeInterval(delayLength, target: self, selector: #selector(MyPretracker.stopLocationWithDelay), userInfo: nil, repeats: false)
    }
    
    public func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        let date = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDateString = dateFormatter.stringFromDate(date)
        
        let newLog = PFObject(className: "pretracking_debug")
        newLog["vendor_id"] = vendorId
        newLog["timestamp_epoch"] = Int(Int64(NSDate().timeIntervalSince1970 * 1000))
        newLog["timestamp_string"] = currentDateString
        newLog["console_string"] = error.description
        newLog.saveInBackground()
    }
    
    public func locationManagerDidPauseLocationUpdates(manager: CLLocationManager) {
        let date = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDateString = dateFormatter.stringFromDate(date)
        
        let newLog = PFObject(className: "pretracking_debug")
        newLog["vendor_id"] = vendorId
        newLog["timestamp_epoch"] = Int(Int64(NSDate().timeIntervalSince1970 * 1000))
        newLog["timestamp_string"] = currentDateString
        newLog["console_string"] = "Location Updates Paused by iOS"
        newLog.saveInBackground()
    }
    
    public func locationManagerDidResumeLocationUpdates(manager: CLLocationManager) {
        let date = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDateString = dateFormatter.stringFromDate(date)
        
        let newLog = PFObject(className: "pretracking_debug")
        newLog["vendor_id"] = vendorId
        newLog["timestamp_epoch"] = Int(Int64(NSDate().timeIntervalSince1970 * 1000))
        newLog["timestamp_string"] = currentDateString
        newLog["console_string"] = "Location Updates Resumed by iOS"
        newLog.saveInBackground()
    }
    
    public func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("did enter region \(region.identifier)")
        locationManager!.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager!.distanceFilter = kCLDistanceFilterNone
        self.locationDic[region.identifier]?["withinRegion"] = true
        
        // log region entry events to Parse
        let date = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDateString = dateFormatter.stringFromDate(date)
        
        var notificationString: String = ""
        if let monitorRegion = region as? CLCircularRegion {
            let monitorLocation = CLLocation(latitude: monitorRegion.center.latitude, longitude: monitorRegion.center.longitude)
            notificationString = "Entered region \(region.identifier) (\(monitorLocation.coordinate.latitude), \(monitorLocation.coordinate.longitude))"
        } else {
            notificationString = "Entered region \(region.identifier) (nil, nil)"
        }
        
        let newLog = PFObject(className: "pretracking_debug")
        newLog["vendor_id"] = vendorId
        newLog["timestamp_epoch"] = Int(Int64(NSDate().timeIntervalSince1970 * 1000))
        newLog["timestamp_string"] = currentDateString
        newLog["console_string"] = notificationString
        newLog.saveInBackground()
    }
    
    public func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("did exit region \(region.identifier)")
        self.locationDic[region.identifier]?["withinRegion"] = false
        self.locationDic[region.identifier]?["notifiedForRegion"] = false
        
        if outOfAllRegions() {
            locationManager!.desiredAccuracy = self.accuracy
            locationManager!.distanceFilter = self.distanceFilter
        }
        
        // log region exit events to Parse
        let date = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDateString = dateFormatter.stringFromDate(date)
        
        var notificationString: String = ""
        if let monitorRegion = region as? CLCircularRegion {
            let monitorLocation = CLLocation(latitude: monitorRegion.center.latitude, longitude: monitorRegion.center.longitude)
            notificationString = "Exited region \(region.identifier) (\(monitorLocation.coordinate.latitude), \(monitorLocation.coordinate.longitude))"
        } else {
            notificationString = "Exited region \(region.identifier) (nil, nil)"
        }
        
        let newLog = PFObject(className: "pretracking_debug")
        newLog["vendor_id"] = vendorId
        newLog["timestamp_epoch"] = Int(Int64(NSDate().timeIntervalSince1970 * 1000))
        newLog["timestamp_string"] = currentDateString
        newLog["console_string"] = notificationString
        newLog.saveInBackground()
    }
    
    private func outOfAllRegions() -> Bool {
        print("checking all regions")
        for (_, regionInfo) in self.locationDic {
            if regionInfo["withinRegion"] as! Bool{
                return false
            }
        }
        return true
    }
}