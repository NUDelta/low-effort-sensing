//
//  MyPretracker.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 4/29/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import Foundation
import CoreLocation
import UserNotifications
import Parse

public class MyPretracker: NSObject, CLLocationManagerDelegate {
    // MARK: Class Variables
    // tracker parameters and storage variables
    var distance: Double = 20.0
    var radius: Double = 150.0
    var accuracy: Double = kCLLocationAccuracyBestForNavigation
    var distanceFilter: Double = -1.0
    
    var locationDic: [String: [String: Any]] = [:]
    var locationManager: CLLocationManager?
    
    // logging location data
    var previousLocation: CLLocation?
    var currentLocation: CLLocation?
    let distanceUpdate = 30.0
    
    // study conditions, expand and exploit variables
    var studyDistances: [Int] = []
    var withinDistanceRecorded: [String : [String : Bool]] = [:] // [hotspotId : [distance : bool]]
    var expandNotificationDistance: Double = 0.0
    var underExploit: Bool = false

    var shouldPingForExploit: Bool = false
    var currentlyUnderExpand: Bool = false
    var resetExpandExploitConditionsTimer: Timer?
    
    // refreshing locations being tracked
    var parseRefreshTimer: Timer?
    
    let appUserDefaults = UserDefaults(suiteName: appGroup)
    var window: UIWindow?
    
    // background task
    let backgroundTaskManager = BackgroundTaskManager()
    let bgTask: BackgroundTaskManager = BackgroundTaskManager.shared()
    
    var timer: Timer? = Timer()
    var delay10Seconds: Timer? = Timer()
    
    // MARK: - Initializations, Getters, and Setters
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
    public func clearAllMonitoredRegions() {
        print("Monitored regions: \(locationManager!.monitoredRegions)")
        for region in locationManager!.monitoredRegions {
            if !(region is CLBeaconRegion) {
                locationManager!.stopMonitoring(for: region)
            }
        }
    }
    
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
            if error == nil {
                PFCloud.callFunction(inBackground: "retrieveExpandExploitLocations",
                                     withParameters: ["latitude": (geoPoint?.latitude)!,
                                                      "longitude": (geoPoint?.longitude)!,
                                                      "vendorId": vendorId,
                                                      "count": 20],
                                     block: ({ (foundObjs: Any?, error: Error?) -> Void in
                                        if error == nil {
                                            // parse response
                                            if let foundObjs = foundObjs {
                                                let foundObjDictionary = foundObjs as! [String : AnyObject]
                                                var monitoredHotspotDictionary: [String : AnyObject] = [String : AnyObject]()
                                                
                                                // pull out distance conditions, expand distance, and under exploit
                                                self.studyDistances = foundObjDictionary["allConditionDistances"] as! [Int]
                                                self.expandNotificationDistance = foundObjDictionary["expandDistance"] as! Double
                                                self.underExploit = foundObjDictionary["underExploit"] as! Bool
                                                
                                                // hold all current valid expand locations
                                                var currentValidRegions: Set<String> = Set<String>()
                                                
                                                let foundObjsArray = foundObjDictionary["locations"] as! [AnyObject]
                                                for object in foundObjsArray {
                                                    if let object = object as? [String : Any?] {
                                                        // get individual variables from queried objects
                                                        let id = object["objectId"] as! String
                                                        let vendorId = object["vendorId"] as! String
                                                        let tag = object["tag"] as! String
                                                        
                                                        let currGeopoint = object["location"] as! PFGeoPoint
                                                        let currLat = currGeopoint.latitude
                                                        let currLong = currGeopoint.longitude
                                                        let beaconId = object["beaconId"] as? String
                                                        
                                                        let locationCommonName = object["locationCommonName"] as? String
                                                        let notificationCategory = object["notificationCategory"] as? String

                                                        let message = object["message"] as? String
                                                        let scaffoldedMessage = object["scaffoldedMessage"] as? String

                                                        let contextualResponses = object["contextualResponses"] as? [String]
                                                        let locationType = object["locationType"] as? String

                                                        // create geofences
                                                        let hasBeacon = beaconId != ""
                                                        self.addLocation(nil, latitude: currLat, longitude: currLong,
                                                                         radius: nil, id: id,
                                                                         expandRadius: self.expandNotificationDistance, locationType: locationType!, hasBeacon: hasBeacon)
                                                        
                                                        // Add data to user defaults
                                                        var unwrappedEntry = [String : AnyObject]()
                                                        unwrappedEntry["id"] = id as AnyObject
                                                        unwrappedEntry["vendorId"] = vendorId as AnyObject
                                                        unwrappedEntry["tag"] = tag as AnyObject
                                                        
                                                        unwrappedEntry["latitude"] = currLat as AnyObject
                                                        unwrappedEntry["longitude"] = currLong as AnyObject
                                                        
                                                        unwrappedEntry["locationCommonName"] = locationCommonName as AnyObject
                                                        unwrappedEntry["beaconId"] = beaconId as AnyObject

                                                        unwrappedEntry["notificationCategory"] = notificationCategory as AnyObject
                                                        unwrappedEntry["message"] = message as AnyObject
                                                        unwrappedEntry["scaffoldedMessage"] = scaffoldedMessage as AnyObject
                                                        unwrappedEntry["contextualResponses"] = contextualResponses as AnyObject
                                                        unwrappedEntry["locationType"] = locationType as AnyObject

                                                        monitoredHotspotDictionary[id] = unwrappedEntry as AnyObject
                                                        
                                                        // create dictionary to hold geofence trips for study conditions
                                                        if (locationType == "expand") && (self.withinDistanceRecorded[id] == nil) {
                                                            var idDistanceDict: [String : Bool] = [:]
                                                            for studyDistance in self.studyDistances {
                                                                idDistanceDict[String(studyDistance)] = false
                                                            }
                                                            
                                                            self.withinDistanceRecorded[id] = idDistanceDict
                                                        }
                                                        
                                                        // add current valid expand and exploit locations to set
                                                        currentValidRegions.insert(id)
                                                    }
                                                }
                                                
                                                // check withinDistanceRecorded and locationDic to make sure all old locations have been removed
                                                for (key, _) in self.withinDistanceRecorded {
                                                    if !currentValidRegions.contains(key) {
                                                        self.withinDistanceRecorded.removeValue(forKey: key)
                                                    }
                                                }
                                                
                                                for (key, _) in self.locationDic {
                                                    if !currentValidRegions.contains(key) {
                                                        self.locationDic.removeValue(forKey: key)
                                                    }
                                                }
                                                
                                                // update user defaults
                                                self.appUserDefaults?.set(monitoredHotspotDictionary, forKey: savedHotspotsRegionKey)
                                                self.appUserDefaults?.synchronize()
                                                
                                                // refresh data every 10 minutes
                                                // invalidate first if push refresh was called before timer could run
                                                if self.parseRefreshTimer != nil {
                                                    self.parseRefreshTimer?.invalidate()
                                                    self.parseRefreshTimer = nil
                                                }
                                                
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
                                            print("Error in querying regions from Parse: \(String(describing: error)). Trying again.")
                                            self.beginMonitoringParseRegions()
                                        }
                                     }))
            }
        }))
    }
    
    // MARK: - Adding/Removing Locations
    public func addLocation(_ distance: Double?, latitude: Double, longitude: Double, radius: Double?,
                            id: String, expandRadius: Double, locationType: String, hasBeacon: Bool) {
        // check if optional distance and radius values are set
        var newLocationDistance: Double = self.distance
        if let unwrappedDistance = distance {
            newLocationDistance = unwrappedDistance
        }
        
        var newLocationRadius: Double = self.radius
        if let unwrappedRadius = radius {
            newLocationRadius = unwrappedRadius
        }

        // create region identifier
        // expand inner: id_expand
        // expand outer: id_expand-outer
        // exploit: id_exploit
        let regionIdentifier: String = id + "_" + locationType

        // check if expand vs exploit region
        // if expand, create 2 geofences (inner and outer)
        // if exploit, create only inner geofence
        let newRegionCenter = CLLocationCoordinate2DMake(latitude, longitude)
        if (locationType == "expand") {
            let outerExpandRegion = CLCircularRegion.init(center: newRegionCenter, radius: expandRadius, identifier: regionIdentifier + "-outer")
            locationManager!.startMonitoring(for: outerExpandRegion)
        }

        if (!hasBeacon) {
            let innerRegion = CLCircularRegion.init(center: newRegionCenter, radius: newLocationRadius, identifier: regionIdentifier)
            locationManager!.startMonitoring(for: innerRegion)
        }

        // add location to locationDic with state variables
        if (self.locationDic[id] != nil) {
            let shouldNotifyBool = self.locationDic[id]?["shouldNotify"] as! Bool
            self.locationDic[id] = ["distance": newLocationDistance, "withinRegion": false, "notifiedForRegion": false,
                                    "shouldNotify": shouldNotifyBool, "locationType": locationType, "askedForExpand": false]
        } else {
            self.locationDic[id] = ["distance": newLocationDistance, "withinRegion": false, "notifiedForRegion": false,
                                    "shouldNotify": false, "locationType": locationType, "askedForExpand": false]
        }
    }
    
    public func removeLocation(_ name: String) {
        if self.locationDic.removeValue(forKey: name) != nil {
            let monitoredRegions = locationManager!.monitoredRegions
            print(locationManager!.monitoredRegions)
            
            for region in monitoredRegions {
                // split region identifier into id and type
                let regionComponents = region.identifier.components(separatedBy: "_")
                let regionId = regionComponents[0]

                if name == regionId {
                    locationManager!.stopMonitoring(for: region)
                    print("stopped monitoring \(name)")
                }
            }
        }
    }
    
    // MARK: - Pre-Tracking Algorithm and Notifications
    func setShouldNotifyExpand(id: String, value: Bool) {
        if self.locationDic[id] != nil {
            self.locationDic[id]!["shouldNotify"] = value
        }

        self.currentlyUnderExpand = value

        // reset timer and set new one if value is true
        if (self.resetExpandExploitConditionsTimer != nil) {
            self.resetExpandExploitConditionsTimer!.invalidate()
            self.resetExpandExploitConditionsTimer = nil
        }

        if value {
            self.resetExpandExploitConditionsTimer = Timer.scheduledTimer(timeInterval: 30.0 * 60.0, // 30 mins
                                                                          target: self,
                                                                          selector: #selector(MyPretracker.resetExpandExploitConditions),
                                                                          userInfo: id,
                                                                          repeats: false)
        }
    }

    func setShouldNotifyExploit(value: Bool) {
        self.shouldPingForExploit = value && self.underExploit // exploit iff yes to expand and user is currently under exploit
    }

    func resetExpandExploitConditions(timer: Timer) {
        print("Pretracker Resetting expand/exploit conditions")
        if let expandId = timer.userInfo {
            self.setShouldNotifyExpand(id: expandId as! String, value: false)
            self.setShouldNotifyExploit(value: false)
        }
    }

    public func notifyIfWithinDistance(_ lastLocation: CLLocation) {
        // check if location update is recent and accurate enough
        let age = -lastLocation.timestamp.timeIntervalSinceNow
        if (lastLocation.horizontalAccuracy < 0 || lastLocation.horizontalAccuracy > 65.0 || age > 20) {
            return
        }
        
        for region in locationManager!.monitoredRegions {
            if !(region is CLBeaconRegion) {
                // split region identifier into id and type 
                let regionComponents = region.identifier.components(separatedBy: "_")
                let regionId = regionComponents[0]
                let regionType = regionComponents[1]

                // Get NSUserDefaults
                var monitoredHotspotDictionary = appUserDefaults!.dictionary(forKey: savedHotspotsRegionKey) ?? [:]
                
                // check if monitoredHotspotDictionary is currently being refreshed, if so quit
                if let currentRegion = monitoredHotspotDictionary[regionId] as? [String : AnyObject], let beaconId = currentRegion["beaconId"] as? String {
                    if let monitorRegion = region as? CLCircularRegion {
                        let monitorLocation = CLLocation(latitude: monitorRegion.center.latitude, longitude: monitorRegion.center.longitude)
                        let distanceToLocation = lastLocation.distance(from: monitorLocation)

                        // make sure not a expand-outer region before looking to ping or not
                        if regionType == "expand-outer" {
                            // store if within each condition distance
                            if self.withinDistanceRecorded[regionId] != nil {
                                // condition distances should be increasing, find whichever they are furthest out from
                                for condition in self.studyDistances {
                                    // check if less than condition distance
                                    if distanceToLocation <= Double(condition) {
                                        if !self.withinDistanceRecorded[regionId]![String(condition)]! {
                                            // save condition trip
                                            let epochTimestamp = Int(Date().timeIntervalSince1970)
                                            let gmtOffset = NSTimeZone.local.secondsFromGMT()

                                            let bearing = getBearingBetweenTwoPoints(point1: lastLocation, point2: monitorLocation)
                                            let course = getBearingBetweenTwoPoints(point1: self.previousLocation!, point2: self.currentLocation!)
                                            let angle = angleCourseBearing(course: course, bearing: bearing)

                                            let newResponse = PFObject(className: "expandGeofenceTrips")
                                            newResponse["vendorId"] = vendorId
                                            newResponse["hotspotId"] = regionId
                                            newResponse["distanceCondition"] = condition
                                            newResponse["tripLocation"] = PFGeoPoint.init(location: lastLocation)
                                            newResponse["timestamp"] = epochTimestamp
                                            newResponse["gmtOffset"] = gmtOffset
                                            newResponse["bearingToLocation"] = angle
                                            newResponse.saveInBackground()

                                            // update withinDistanceRecorded
                                            self.withinDistanceRecorded[regionId]![String(condition)]! = true
                                        }

                                        break // stop searching once a condition trip is found
                                    }
                                }
                            }
                        } else {
                            // check if beacon region before notifying
                            if beaconId == "" {
                                // print("Pretracker found a Geofence Region w/o beacon (\(regionId))...beginning pretracking.")
                                if let currentLocationInfo = self.locationDic[regionId] {
                                    // check if expand location and if shouldNotify for expand
                                    if ((regionType == "expand") && (currentLocationInfo["shouldNotify"] as! Bool)) ||
                                        ((regionType == "exploit") && (self.shouldPingForExploit)) {
                                        // notify for expand or exploit location
                                        let distance = currentLocationInfo["distance"] as! Double
                                        let hasBeenNotifiedForRegion = currentLocationInfo["notifiedForRegion"] as! Bool

                                        if (distanceToLocation <= distance && !hasBeenNotifiedForRegion) {
                                            self.locationDic[regionId]?["notifiedForRegion"] = true
                                            self.locationDic[regionId]?["withinRegion"] = true

                                            notifyPeople(monitorRegion, locationWhenNotified: lastLocation)
                                        }
                                    }
                                }
                            } else {
                                // print("Pretracker found a Geofence Region w/CLBeacon (\(regionId))...will not pretrack.")
                            }
                        }
                    }
                } else {
                    print("notifyIfWithinDistance: Data currently being refreshed...waiting until finished.")
                }
            } else {
                // print("Pretracker found a CLBeacon Region (\(regionId))...will not pretrack.")
            }
        }
    }
    
    public func notifyPeople(_ region: CLRegion, locationWhenNotified: CLLocation) {
        if !(region is CLBeaconRegion) {
            // split region identifier into id and type
            let regionComponents = region.identifier.components(separatedBy: "_")
            let regionId = regionComponents[0]
            let regionType = regionComponents[1]

            // make sure not a expand-outer region
            if regionType == "expand-outer" {
                return
            }

            print("notify for region id \(regionId)")

            // Get NSUserDefaults
            var monitoredHotspotDictionary = appUserDefaults!.dictionary(forKey: savedHotspotsRegionKey) ?? [:]
            if let currentRegion = monitoredHotspotDictionary[regionId] as? [String : AnyObject] {
                let message = regionId

                // Log notification to parse
                let epochTimestamp = Int(Date().timeIntervalSince1970)
                let gmtOffset = NSTimeZone.local.secondsFromGMT()

                var distanceToLocation: Double = 0.0
                var notificationString: String = ""
                if let monitorRegion = region as? CLCircularRegion {
                    let monitorLocation = CLLocation(latitude: monitorRegion.center.latitude, longitude: monitorRegion.center.longitude)
                    distanceToLocation = locationWhenNotified.distance(from: monitorLocation)
                    notificationString = "Notified for \(regionId) (\(monitorLocation.coordinate.latitude), \(monitorLocation.coordinate.longitude)) when at location (\(locationWhenNotified.coordinate.latitude), \(locationWhenNotified.coordinate.longitude)) at distance \(distanceToLocation)"
                } else {
                    notificationString = "Notified for \(regionId) (nil, nil) when at location (\(locationWhenNotified.coordinate.latitude), \(locationWhenNotified.coordinate.longitude)) at distance nil"
                }

                if regionType != "exploit" {
                    // expand notifications
                    let newResponse = PFObject(className: "notificationSent")
                    newResponse["vendorId"] = vendorId
                    newResponse["hotspotId"] = currentRegion["id"] as! String
                    newResponse["timestamp"] = epochTimestamp
                    newResponse["gmtOffset"] = gmtOffset
                    newResponse["notificationString"] = notificationString
                    newResponse.saveInBackground()
                } else {
                    // exploit notifications
                    let newResponse = PFObject(className: "exploitNotification")
                    newResponse["vendorId"] = vendorId
                    newResponse["exploitId"] = currentRegion["id"] as! String
                    newResponse["timestamp"] = epochTimestamp
                    newResponse["gmtOffset"] = gmtOffset
                    newResponse.saveInBackground()
                }

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
                    // create contextual responses
                    var currNotificationSet = Set<UNNotificationCategory>()
                    let currCategory = UNNotificationCategory(identifier: currentRegion["notificationCategory"] as! String,
                                                              actions: createActionsForAnswers(currentRegion["contextualResponses"] as! [String],
                                                                                               includeIdk: true),
                                                              intentIdentifiers: [],
                                                              options: [.customDismissAction])
                    currNotificationSet.insert(currCategory)
                    UNUserNotificationCenter.current().setNotificationCategories(currNotificationSet)

                    // Display notification with context
                    let content = UNMutableNotificationContent()
                    content.body = currentRegion["message"] as! String
                    content.sound = UNNotificationSound.default()
                    content.categoryIdentifier = currentRegion["notificationCategory"] as! String
                    content.userInfo = currentRegion

                    let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 1, repeats: false)
                    let notificationRequest = UNNotificationRequest(identifier: currentRegion["id"]! as! String, content: content, trigger: trigger)

                    UNUserNotificationCenter.current().add(notificationRequest, withCompletionHandler: { (error) in
                        if let error = error {
                            print("Error in notifying from Pre-Tracker: \(error)")
                        }
                    })
                }
            }  else {
                print("Notify People: Data currently being refreshed...waiting until finished.")
            }
        }
    }
    
    func createActionsForAnswers(_ answers: [String], includeIdk: Bool) -> [UNNotificationAction] {
        // create UNNotificationAction objects for each answer
        var actionsForAnswers = [UNNotificationAction]()
        for answer in answers {
            let currentAction = UNNotificationAction(identifier: answer, title: answer, options: [])
            actionsForAnswers.append(currentAction)
        }
        
        // add i dont know option
        if includeIdk {
            let idkAction = UNNotificationAction(identifier: "I don't know", title: "I don't know", options: [])
            actionsForAnswers.append(idkAction)
        }
        
        return actionsForAnswers
    }

    //MARK: - Background Task Functions
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
    
    //MARK: - Tracking Location Updates
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // check if locations should be notified for and notify if applicable
        let lastLocation = locations.last!
        self.previousLocation = currentLocation
        self.currentLocation = lastLocation
        notifyIfWithinDistance(lastLocation)
        
        // reset timer
        // do any actual work before this step as it may not execute depending on timer state
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
    
    func saveCurrentLocationToParse() {
        let lastLocation = (locationManager?.location)!
        
        // store location updates if greater than threshold
        if (lastLocation.horizontalAccuracy > 0 && lastLocation.horizontalAccuracy < 65.0) {
            let distance = calculateDistance(currentLocation: lastLocation)
            
            if (distance >= distanceUpdate) {
                let epochTimestamp = Int(Date().timeIntervalSince1970)
                let gmtOffset = NSTimeZone.local.secondsFromGMT()
                
                let newLocationUpdate = PFObject(className: "locationUpdates")
                newLocationUpdate["latitude"] = lastLocation.coordinate.latitude
                newLocationUpdate["longitude"] = lastLocation.coordinate.longitude
                newLocationUpdate["heading"] = lastLocation.course
                newLocationUpdate["speed"] = lastLocation.speed
                newLocationUpdate["horizontalAccuracy"] = lastLocation.horizontalAccuracy
                newLocationUpdate["vendorId"] = vendorId
                newLocationUpdate["timestamp"] = epochTimestamp
                newLocationUpdate["gmtOffset"] = gmtOffset
                
                newLocationUpdate.saveInBackground()
            }
        }
    }
    
    func calculateDistance(currentLocation: CLLocation) -> Double{
        if self.previousLocation == nil {
            self.previousLocation = currentLocation
        }
        
        let locationDistance = currentLocation.distance(from: self.previousLocation!)
        self.previousLocation = currentLocation
        return locationDistance
    }
    
    func degreesToRadians(degrees: Double) -> Double { return degrees * Double.pi / 180.0 }
    
    func radiansToDegrees(radians: Double) -> Double { return radians * 180.0 / Double.pi }
    
    func getBearingBetweenTwoPoints(point1 : CLLocation, point2 : CLLocation) -> Double {
        // compute degree bearing between two points
        let lat1 = degreesToRadians(degrees: point1.coordinate.latitude)
        let lon1 = degreesToRadians(degrees: point1.coordinate.longitude)
        
        let lat2 = degreesToRadians(degrees: point2.coordinate.latitude)
        let lon2 = degreesToRadians(degrees: point2.coordinate.longitude)
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        
        // return as 0-360 rather than +- 180
        let initalBearing = radiansToDegrees(radians: radiansBearing)
        let compassBearing = (initalBearing + 360.0).truncatingRemainder(dividingBy: 360.0)
        
        return compassBearing
    }

    func angleCourseBearing(course: Double, bearing: Double) -> Double{
        return abs(course - bearing)
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
    
    // TODO: check here if location is eXpand location. if so, send expand ping. if yes response, save response to locationDic
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if !(region is CLBeaconRegion) {
            // check if major GPS bounce has occured, if so don't go any further
            if manager.location == nil || self.previousLocation == nil || self.currentLocation == nil{
                return
            }

            let lastlocation = manager.location!
            let age = -lastlocation.timestamp.timeIntervalSinceNow

            if (lastlocation.horizontalAccuracy < 0 || lastlocation.horizontalAccuracy > 65.0 || age > 20) {
                return
            }

            print("did enter region \(region.identifier)")

            // compute distance to region from current location
            let monitorRegion = region as! CLCircularRegion
            let monitorRegionLocation = CLLocation(latitude: monitorRegion.center.latitude, longitude: monitorRegion.center.longitude)
            let distanceToRegion = lastlocation.distance(from: monitorRegionLocation)

            // split region identifier into id and type
            let regionComponents = region.identifier.components(separatedBy: "_")
            let regionId = regionComponents[0]
            let regionType = regionComponents[1]

            // if outer expand region, notify asking if user wants to go
            if (regionType == "expand-outer" ) {
                // check if already under expand before seeing to ping
                if self.currentlyUnderExpand {
                    return
                }

                // don't ask for expand again until data refresh to prevent geofence bouncing
                if let alreadyAskedForExpand = self.locationDic[regionId]?["askedForExpand"] {
                    if alreadyAskedForExpand as! Bool {
                        return
                    }
                }
                self.locationDic[regionId]?["askedForExpand"] = true

                // check if heading is between 285 and 75
                let bearing = getBearingBetweenTwoPoints(point1: lastlocation, point2: monitorRegionLocation)
                let course = getBearingBetweenTwoPoints(point1: self.previousLocation!, point2: self.currentLocation!)
                let angle = angleCourseBearing(course: course, bearing: bearing)

                if (angle > 75) && (angle < 285) {
                    return
                }

                // Get NSUserDefaults
                var monitoredHotspotDictionary = appUserDefaults!.dictionary(forKey: savedHotspotsRegionKey) ?? [:]
                if let currentRegion = monitoredHotspotDictionary[regionId] as? [String : AnyObject] {
                    let message = regionId

                    // Log notification to parse
                    let epochTimestamp = Int(Date().timeIntervalSince1970)
                    let gmtOffset = NSTimeZone.local.secondsFromGMT()

                    // Log notification sent event to parse
                    let newResponse = PFObject(className: "expandNotifications")
                    newResponse["vendorId"] = vendorId
                    newResponse["hotspotId"] = currentRegion["id"] as! String
                    newResponse["tag"] = currentRegion["tag"] as! String
                    newResponse["distanceCondition"] = self.expandNotificationDistance
                    newResponse["timestamp"] = epochTimestamp
                    newResponse["gmtOffset"] = gmtOffset
                    newResponse["distanceToRegion"] = distanceToRegion
                    newResponse["bearingToLocation"] = angle
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
                        // create contextual responses
                        var currNotificationSet = Set<UNNotificationCategory>()
                        let expandEMAResponses = ["Yes! Great to know, I'm going to go now!",
                                                  "Yes, but I was already going there.",
                                                  "No, I have somewhere that I need to be.",
                                                  "No, I'm not interested.",
                                                  "No, other reason."]
                        let currCategory = UNNotificationCategory(identifier: "expand",
                                                                  actions: createActionsForAnswers(expandEMAResponses, includeIdk: false),
                                                                  intentIdentifiers: [],
                                                                  options: [.customDismissAction])
                        currNotificationSet.insert(currCategory)
                        UNUserNotificationCenter.current().setNotificationCategories(currNotificationSet)

                        // Display notification with context
                        let content = UNMutableNotificationContent()
                        content.body = currentRegion["message"] as! String + " Would you like to go?"
                        content.sound = UNNotificationSound.default()
                        content.categoryIdentifier = "expand"
                        content.userInfo = currentRegion

                        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 1, repeats: false)
                        let notificationRequest = UNNotificationRequest(identifier: currentRegion["id"]! as! String, content: content, trigger: trigger)

                        UNUserNotificationCenter.current().add(notificationRequest, withCompletionHandler: { (error) in
                            if let error = error {
                                print("Error in notifying from Pre-Tracker: \(error)")
                            }
                        })

                        print("asking expand for region \(region.identifier)")
                    }
                } else {
                    print("Did enter region: Data currently being refreshed...waiting until finished.")
                }
            } else {
                locationManager!.desiredAccuracy = kCLLocationAccuracyBestForNavigation
                locationManager!.distanceFilter = kCLDistanceFilterNone
            }
            self.locationDic[regionId]?["withinRegion"] = true
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if !(region is CLBeaconRegion) {
            print("did exit region \(region.identifier)")

            // split region identifier into id and type
            let regionComponents = region.identifier.components(separatedBy: "_")
            let regionId = regionComponents[0]

            self.locationDic[regionId]?["withinRegion"] = false
            self.locationDic[regionId]?["notifiedForRegion"] = false
            
            if outOfAllRegions() {
                locationManager!.desiredAccuracy = self.accuracy
                locationManager!.distanceFilter = self.distanceFilter
            }
        }
    }
    
    //MARK: - Location Manager Delegate Error Functions
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
    
    public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Error monitoring failed for geofence region: \(String(describing: region)) with error \(error)")
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
}
