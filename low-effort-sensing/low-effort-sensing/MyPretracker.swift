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
    
    var parseRefreshTimer: Timer? = Timer() // refreshing locations being tracked
    
    let appUserDefaults = UserDefaults(suiteName: appGroup)
    var window: UIWindow?
    
    // background task
    let backgroundTaskManager = BackgroundTaskManager()
    let bgTask: BackgroundTaskManager = BackgroundTaskManager.shared()
    
    var timer: Timer? = Timer()
    var delay10Seconds: Timer? = Timer()
    
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
    
    public func setupParameters(_ distance: Double?, radius: Double?, accuracy: CLLocationAccuracy?, distanceFilter: Double?) {
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
        print("Monitored regions: \(locationManager!.monitoredRegions)")
        for region in locationManager!.monitoredRegions {
            if !(region is CLBeaconRegion) {
                locationManager!.stopMonitoring(for: region)
            }
        }
    }
    
    public func getAuthorizationForLocationManager() {
        print("Requesting authorization for always-on location")
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager!.requestAlwaysAuthorization()
        }
    }
    
    public func initLocationManager() {
        clearAllMonitoredRegions()
        
        locationManager!.allowsBackgroundLocationUpdates = true
        locationManager!.pausesLocationUpdatesAutomatically = false
        locationManager!.startUpdatingLocation()
        
        // print debug string with all location manager parameters
        let locActivity = locationManager!.activityType == .other
        let locAccuracy = locationManager!.desiredAccuracy
        let locDistance = locationManager!.distanceFilter
        let locationManagerParametersDebugString = "Manager Activity = \(locActivity)\n" +
            "Manager Accuracy = \(locAccuracy)\n" +
            "Manager Distance Filter = \(locDistance)\n"
        
        let authStatus = CLLocationManager.authorizationStatus() == .authorizedAlways
        let locServicesEnabled = CLLocationManager.locationServicesEnabled()
        let locationManagerPermissionsDebugString = "Location manager setup with following parameters:\n" +
            "Authorization = \(authStatus)\n" +
            "Location Services Enabled = \(locServicesEnabled)\n"
        
        print("Initialized Location Manager Information:\n" + locationManagerPermissionsDebugString + locationManagerParametersDebugString)
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        initLocationManager()
        beginMonitoringParseRegions()
    }
    
    // MARK: - Location Functions
    func refreshLocationsFromParse() {
        if (parseRefreshTimer != nil) {
            parseRefreshTimer!.invalidate()
            parseRefreshTimer = nil
        }
        
        print("refreshing tracked locations")
        clearAllMonitoredRegions()
        beginMonitoringParseRegions()
    }
    
    func beginMonitoringParseRegions() {
        print("Getting monitored regions")
        PFGeoPoint.geoPointForCurrentLocation(inBackground: ({
            (geoPoint: PFGeoPoint?, error: Error?) -> Void in
            print(geoPoint as Any)
            if error == nil {
                PFCloud.callFunction(inBackground: "retrieveLocationsForTracking",
                                     withParameters: ["latitude": (geoPoint?.latitude)!,
                                                      "longitude": (geoPoint?.longitude)!,
                                                      "vendorId": vendorId,
                                                      "count": 10],
                                     block: ({ (foundObjs: Any?, error: Error?) -> Void in
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
                                                        
                                                        let info : [String : AnyObject]? = object["info"] as? [String : AnyObject]
                                                        
                                                        // Add data to user defaults
                                                        var unwrappedEntry = [String : AnyObject]()
                                                        unwrappedEntry["id"] = id as AnyObject
                                                        unwrappedEntry["vendorId"] = (object["vendorId"] as! String) as AnyObject
                                                        unwrappedEntry["tag"] = (object["tag"] as! String) as AnyObject
                                                        unwrappedEntry["info"] = info as AnyObject
                                                        unwrappedEntry["latitude"] = currLat as AnyObject
                                                        unwrappedEntry["longitude"] = currLong as AnyObject
                                                        unwrappedEntry["archived"] = (object["archived"] as? Bool) as AnyObject
                                                        unwrappedEntry["timestampCreated"] = (object["timestampCreated"] as? Int) as AnyObject
                                                        unwrappedEntry["gmtOffset"] = (object["gmtOffset"] as? Int) as AnyObject
                                                        unwrappedEntry["timestampLastUpdate"] = (object["timestampLastUpdate"] as? Int) as AnyObject
                                                        unwrappedEntry["submissionMethod"] = (object["submissionMethod"] as? String) as AnyObject
                                                        unwrappedEntry["locationCommonName"] = (object["locationCommonName"] as? String) as AnyObject
                                                        
                                                        monitoredHotspotDictionary[id] = unwrappedEntry as AnyObject
                                                    }
                                                }
                                                // save regions to user defaults
//                                                print(monitoredHotspotDictionary)
//                                                print(type(of: monitoredHotspotDictionary))
//                                                for (id, keys) in monitoredHotspotDictionary {
//                                                    for (newId, newKey) in keys as! [String:AnyObject] {
//                                                        print("For \(newId): \(type(of: newKey))")
//                                                    }
//                                                }

                                                self.appUserDefaults?.set(monitoredHotspotDictionary, forKey: savedHotspotsRegionKey)
                                                self.appUserDefaults?.synchronize()
                                                
                                                // refresh data every 10 minutes
                                                self.parseRefreshTimer = Timer.scheduledTimer(timeInterval: 10.0 * 60.0,
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
                                     }))
            }
        }))
    }
    
    // MARK: Adding/Removing Locations
    public func addLocation(_ distance: Double?, latitude: Double, longitude: Double, radius: Double?, name: String) {
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
        
        locationManager!.startMonitoring(for: newRegionForMonitoring)
        self.locationDic[name] = ["distance": newLocationDistance, "withinRegion": false, "notifiedForRegion": false]
    }
    
    public func removeLocation(_ name: String) {
        if self.locationDic.removeValue(forKey: name) != nil {
            let monitoredRegions = locationManager!.monitoredRegions
            print(locationManager!.monitoredRegions)
            
            for region in monitoredRegions {
                if name == region.identifier {
                    locationManager!.stopMonitoring(for: region)
                    print("stopped monitoring \(name)")
                }
            }
        }
    }
    
    // MARK: Pre-tracking algorithm and notifications
    public func notifyIfWithinDistance(_ lastLocation: CLLocation) {
        //        print("User position \(lastLocation), course \(lastLocation.course) and, elevation \(lastLocation.altitude) with location accuracy \(locationManager?.desiredAccuracy)")
        
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
                let distanceToLocation = lastLocation.distance(from: monitorLocation)
                
                distanceToRegions[monitorRegion.identifier] = String(distanceToLocation)
                
                if let currentLocationInfo = self.locationDic[monitorRegion.identifier] {
                    let distance = currentLocationInfo["distance"] as! Double
                    let hasBeenNotifiedForRegion = currentLocationInfo["notifiedForRegion"] as! Bool
                    
                    if (distanceToLocation <= distance && !hasBeenNotifiedForRegion) {
                        self.locationDic[monitorRegion.identifier]?["notifiedForRegion"] = true
                        self.locationDic[monitorRegion.identifier]?["withinRegion"] = true
                        
                        notifyPeople(monitorRegion, locationWhenNotified: lastLocation)
                    }
                }
            }
        }
    }
    
    public func notifyPeople(_ region: CLRegion, locationWhenNotified: CLLocation) {
        if !(region is CLBeaconRegion) {
            //        print("notify for region id \(region.identifier)")
            // Get NSUserDefaults
            var monitoredHotspotDictionary = appUserDefaults!.dictionary(forKey: savedHotspotsRegionKey) ?? [:]
            let currentRegion = monitoredHotspotDictionary[region.identifier] as! [String : AnyObject]
            let message = region.identifier
            
            // Log notification to parse
            let epochTimestamp = Int(Date().timeIntervalSince1970)
            let gmtOffset = NSTimeZone.local.secondsFromGMT()
            
            var distanceToLocation: Double = 0.0
            var notificationString: String = ""
            if let monitorRegion = region as? CLCircularRegion {
                let monitorLocation = CLLocation(latitude: monitorRegion.center.latitude, longitude: monitorRegion.center.longitude)
                distanceToLocation = locationWhenNotified.distance(from: monitorLocation)
                notificationString = "Notified for \(region.identifier) (\(monitorLocation.coordinate.latitude), \(monitorLocation.coordinate.longitude)) when at location (\(locationWhenNotified.coordinate.latitude), \(locationWhenNotified.coordinate.longitude)) at distance \(distanceToLocation)"
            } else {
                notificationString = "Notified for \(region.identifier) (nil, nil) when at location (\(locationWhenNotified.coordinate.latitude), \(locationWhenNotified.coordinate.longitude)) at distance nil"
            }
            
            // Log notification sent event to parse
            let newResponse = PFObject(className: "notificationSent")
            newResponse["vendorId"] = vendorId
            newResponse["hotspotId"] = currentRegion["id"] as! String
            newResponse["timestamp"] = epochTimestamp
            newResponse["gmtOffset"] = gmtOffset
            newResponse["notificationString"] = notificationString
            newResponse.saveInBackground()
            
            // Show alert if app active, else local notification
            if UIApplication.shared.applicationState == .active {
                print("Application is active")
                if let viewController = window?.rootViewController {
                    let alert = UIAlertController(title: "Region Entered", message: "You are near \(message).", preferredStyle: .alert)
                    let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alert.addAction(action)
                    viewController.present(alert, animated: true, completion: nil)
                }
            } else {
                // Create context for notification
                let newNotification = NotificationCreator(scenario: currentRegion["tag"] as! String, hotspotInfo: currentRegion["info"] as! [String : String], currentHotspot: currentRegion)
                let notificationContent = newNotification.createNotificationForTag()
                
                // Display notification with context
                let notification = UILocalNotification()
                notification.alertBody = notificationContent["message"]
                notification.soundName = "Default"
                notification.category = notificationContent["notificationCategory"]
                notification.userInfo = currentRegion
                UIApplication.shared.presentLocalNotificationNow(notification)
            }
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
    
    //MARK: Tracking Location Updates
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations.last!
        notifyIfWithinDistance(lastLocation)
        
        // reset timer
        if (timer != nil) {
            return
        }
        
        let bgTask = BackgroundTaskManager.shared()
        bgTask?.beginNewBackgroundTask()
        
        // restart location manager after 1 minute
        let intervalLength = 60.0
        let delayLength = intervalLength - 10.0
        
        timer = Timer.scheduledTimer(timeInterval: intervalLength, target: self, selector: #selector(MyPretracker.restartLocationUpdates), userInfo: nil, repeats: false)
        
        // keep location manager inactive for 10 seconds every minute to save battery
        if (delay10Seconds != nil) {
            delay10Seconds!.invalidate()
            delay10Seconds = nil
        }
        delay10Seconds = Timer.scheduledTimer(timeInterval: delayLength, target: self, selector: #selector(MyPretracker.stopLocationWithDelay), userInfo: nil, repeats: false)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error)")
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDateString = dateFormatter.string(from: date)
        
        let newLog = PFObject(className: "pretracking_debug")
        newLog["vendor_id"] = vendorId
        newLog["timestamp_epoch"] = Int(date.timeIntervalSince1970)
        newLog["timestamp_string"] = currentDateString
        newLog["console_string"] = error.localizedDescription
        newLog.saveInBackground()
    }
    
    public func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDateString = dateFormatter.string(from: date)
        
        let newLog = PFObject(className: "pretracking_debug")
        newLog["vendor_id"] = vendorId
        newLog["timestamp_epoch"] = Int(date.timeIntervalSince1970)
        newLog["timestamp_string"] = currentDateString
        newLog["console_string"] = "Location Updates Paused by iOS"
        newLog.saveInBackground()
    }
    
    public func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDateString = dateFormatter.string(from: date)
        
        let newLog = PFObject(className: "pretracking_debug")
        newLog["vendor_id"] = vendorId
        newLog["timestamp_epoch"] = Int(date.timeIntervalSince1970)
        newLog["timestamp_string"] = currentDateString
        newLog["console_string"] = "Location Updates Resumed by iOS"
        newLog.saveInBackground()
    }
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if !(region is CLBeaconRegion) {
            print("did enter region \(region.identifier)")
            locationManager!.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager!.distanceFilter = kCLDistanceFilterNone
            self.locationDic[region.identifier]?["withinRegion"] = true
            
            //        // log region entry events to Parse
            //        let date = NSDate()
            //        let dateFormatter = NSDateFormatter()
            //        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            //        let currentDateString = dateFormatter.stringFromDate(date)
            //
            //        var notificationString: String = ""
            //        if let monitorRegion = region as? CLCircularRegion {
            //            let monitorLocation = CLLocation(latitude: monitorRegion.center.latitude, longitude: monitorRegion.center.longitude)
            //            notificationString = "Entered region \(region.identifier) (\(monitorLocation.coordinate.latitude), \(monitorLocation.coordinate.longitude))"
            //        } else {
            //            notificationString = "Entered region \(region.identifier) (nil, nil)"
            //        }
            //
            //        let newLog = PFObject(className: "pretracking_debug")
            //        newLog["vendor_id"] = vendorId
            //        newLog["timestamp_epoch"] = Int(date.timeIntervalSince1970)
            //        newLog["timestamp_string"] = currentDateString
            //        newLog["console_string"] = notificationString
            //        newLog.saveInBackground()
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if !(region is CLBeaconRegion) {
            print("did exit region \(region.identifier)")
            self.locationDic[region.identifier]?["withinRegion"] = false
            self.locationDic[region.identifier]?["notifiedForRegion"] = false
            
            if outOfAllRegions() {
                locationManager!.desiredAccuracy = self.accuracy
                locationManager!.distanceFilter = self.distanceFilter
            }
            
            //        // log region exit events to Parse
            //        let date = NSDate()
            //        let dateFormatter = NSDateFormatter()
            //        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            //        let currentDateString = dateFormatter.stringFromDate(date)
            //
            //        var notificationString: String = ""
            //        if let monitorRegion = region as? CLCircularRegion {
            //            let monitorLocation = CLLocation(latitude: monitorRegion.center.latitude, longitude: monitorRegion.center.longitude)
            //            notificationString = "Exited region \(region.identifier) (\(monitorLocation.coordinate.latitude), \(monitorLocation.coordinate.longitude))"
            //        } else {
            //            notificationString = "Exited region \(region.identifier) (nil, nil)"
            //        }
            //
            //        let newLog = PFObject(className: "pretracking_debug")
            //        newLog["vendor_id"] = vendorId
            //        newLog["timestamp_epoch"] = Int(date.timeIntervalSince1970)
            //        newLog["timestamp_string"] = currentDateString
            //        newLog["console_string"] = notificationString
            //        newLog.saveInBackground()
        }
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
