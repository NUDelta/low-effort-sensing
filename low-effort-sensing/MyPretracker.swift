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

    // date objects holding last time user was notified
    var lastNotifiedAtLocation: Date? = nil
    var lastNotifiedAtDistance: Date? = nil
    var timeThreshold: Double = 60.0 // 60 seconds
    // TODO: switch to this one var timeThreshold: Double = 60.0 * 30.0 // 60 seconds * 30 mins = 1800 seconds

    // used to determine when to notify for AtDistance and EnRoute
    var currentlyUnderAtDistance: Bool = false
    var currentAtDistanceLocation: String = ""
    var resetAtDistanceTimer: Timer?
    var shouldNotifyEnRoute: Bool = false
    
    // refreshing locations being tracked
    var parseRefreshTimer: Timer?

    // misc
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
    
    @objc func refreshLocationsFromParse() {
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
                PFCloud.callFunction(inBackground: "retrieveLocations",
                                     withParameters: ["latitude": (geoPoint?.latitude)!,
                                                      "longitude": (geoPoint?.longitude)!,
                                                      "vendorId": vendorId],
                                     block: ({ (foundObjs: Any?, error: Error?) -> Void in
                                        if error == nil {
                                            // parse response
                                            if let foundObjs = foundObjs as? [AnyObject] {
                                                print(foundObjs);
                                                var monitoredHotspotDictionary: [String : AnyObject] = [String : AnyObject]()

                                                // track all valid locations, both TaskLocations and EnRouteLocations
                                                var currValidLocations: Set<String> = Set<String>()

                                                // add each object to monitoredHotspots
                                                for object in foundObjs {
                                                    if let object = object as? [String : Any?] {
                                                        // get individual variables from queried objects
                                                        let id = object["objectId"] as! String
                                                        let vendorId = object["vendorId"] as! String
                                                        let locationType = object["locationType"] as! String

                                                        let currGeopoint = object["location"] as! PFGeoPoint
                                                        let currLat = currGeopoint.latitude
                                                        let currLong = currGeopoint.longitude
                                                        let beaconId = object["beaconId"] as! String

                                                        let locationName = object["locationName"] as! String
                                                        let notificationCategory = object["notificationCategory"] as! String

                                                        let atLocationMessage = object["atLocationMessage"] as! String
                                                        let atLocationResponses = object["atLocationResponses"] as! [String]

                                                        let atDistanceMessage = object["atDistanceMessage"] as! String
                                                        let atDistanceResponses = object["atDistanceResponses"] as! [String]

                                                        let shouldNotifyAtDistance = object["shouldNotifyAtDistance"] as! Bool
                                                        let atDistanceNotificationDistance = object["atDistanceNotificationDistance"] as! Double

                                                        let preferredInfo = object["preferredInfo"] as? String

                                                        // create geofences
                                                        let hasBeacon = beaconId != ""
                                                        self.addLocation(nil, latitude: currLat, longitude: currLong,
                                                                         radius: nil, id: id, atDistanceRadius: atDistanceNotificationDistance,
                                                                         shouldNotifyAtDistance: shouldNotifyAtDistance, locationType: notificationCategory,
                                                                         hasBeacon: hasBeacon)

                                                        // add data for each TaskLocation to UserDefaults
                                                        var unwrappedEntry = [String : AnyObject]()
                                                        unwrappedEntry["id"] = id as AnyObject
                                                        unwrappedEntry["vendorId"] = vendorId as AnyObject
                                                        unwrappedEntry["locationType"] = locationType as AnyObject
                                                        unwrappedEntry["latitude"] = currLat as AnyObject
                                                        unwrappedEntry["longitude"] = currLong as AnyObject
                                                        unwrappedEntry["beaconId"] = beaconId as AnyObject
                                                        unwrappedEntry["locationName"] = locationName as AnyObject
                                                        unwrappedEntry["notificationCategory"] = notificationCategory as AnyObject
                                                        unwrappedEntry["atLocationMessage"] = atLocationMessage as AnyObject
                                                        unwrappedEntry["atLocationResponses"] = atLocationResponses as AnyObject
                                                        unwrappedEntry["atDistanceMessage"] = atDistanceMessage as AnyObject
                                                        unwrappedEntry["atDistanceResponses"] = atDistanceResponses as AnyObject
                                                        unwrappedEntry["shouldNotifyAtDistance"] = shouldNotifyAtDistance as AnyObject
                                                        unwrappedEntry["atDistanceNotificationDistance"] = atDistanceNotificationDistance as AnyObject
                                                        unwrappedEntry["preferredInfo"] = preferredInfo as AnyObject

                                                        monitoredHotspotDictionary[id] = unwrappedEntry as AnyObject

                                                        // add valid regions to set
                                                        currValidLocations.insert(id)
                                                    }
                                                }

                                                // make sure all old locations have been removed from locationDic
                                                for (key, _) in self.locationDic {
                                                    if !currValidLocations.contains(key) {
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
                            id: String, atDistanceRadius: Double, shouldNotifyAtDistance: Bool, locationType: String, hasBeacon: Bool) {
        // check if optional distance and radius values are set
        var newLocationDistance: Double = self.distance
        if let unwrappedDistance = distance {
            newLocationDistance = unwrappedDistance
        }
        
        var newLocationRadius: Double = self.radius
        if let unwrappedRadius = radius {
            newLocationRadius = unwrappedRadius
        }

        // create geofences based on if shouldNotifyAtDistance is true and if enroute location
        let newRegionCenter = CLLocationCoordinate2DMake(latitude, longitude)

        // if enroute location, only add a geofence for location itself
        let isEnRouteLocation = locationType == "enroute"
        if isEnRouteLocation {
            if (!hasBeacon) {
                let enRouteRegion = CLCircularRegion.init(center: newRegionCenter, radius: newLocationRadius, identifier: id + "_enroute")
                locationManager!.startMonitoring(for: enRouteRegion)
            }
        } else {
            // check if notify at distance, and set atDistance region if so
            if shouldNotifyAtDistance {
                let atDistanceRegion = CLCircularRegion.init(center: newRegionCenter, radius: atDistanceRadius, identifier: id + "_atdistance")
                locationManager!.startMonitoring(for: atDistanceRegion)
            }

            if (!hasBeacon) {
                let atLocationRegion = CLCircularRegion.init(center: newRegionCenter, radius: newLocationRadius, identifier: id + "_atlocation")
                locationManager!.startMonitoring(for: atLocationRegion)
            }
        }

        // add location to locationDic with state variables
        self.locationDic[id] = ["atLocationDistance": newLocationDistance, "atDistanceDistance": atDistanceRadius,
                                "withinAtLocation": false, "withinAtDistance": false,
                                "shouldNotifyAtDistance": shouldNotifyAtDistance, "isEnRouteLocation": isEnRouteLocation,
                                "notifiedAtLocation": false, "notifiedAtDistance": false]
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
    
    // MARK: - State Functions
    func setShouldNotifyAtDistance(id: String, value: Bool) {
        // dont ask AtDistance anymore once user has responded
        if (self.locationDic[id] != nil) && value {
            self.locationDic[id]!["notifiedAtDistance"] = true
        }

        // set whether currently under AtDistance
        self.currentlyUnderAtDistance = value

        // set AtDistance location's id. blank if none/resetting
        if value {
            self.currentAtDistanceLocation = id
        } else {
            self.currentAtDistanceLocation = ""
        }

        // reset timer and set new one if value is true
        if (self.resetAtDistanceTimer != nil) {
            self.resetAtDistanceTimer!.invalidate()
            self.resetAtDistanceTimer = nil
        }

        // reset timer after 30 mins
        if value {
            self.resetAtDistanceTimer = Timer.scheduledTimer(timeInterval: 30.0 * 60.0, target: self,
                                                             selector: #selector(MyPretracker.resetAtDistanceEnRouteTimer),
                                                             userInfo: id, repeats: false)
        }
    }

    func setShouldNotifyEnRoute(value: Bool) {
        self.shouldNotifyEnRoute = value // notify for EnRoute iff yes to AtDistance and user is currently under AtDistance
    }

    @objc func resetAtDistanceEnRouteTimer(timer: Timer) {
        print("Pretracker Resetting expand/exploit conditions")
        if let atDistanceLocationId = timer.userInfo {
            self.setShouldNotifyAtDistance(id: atDistanceLocationId as! String, value: false)
            self.setShouldNotifyEnRoute(value: false)
        }
    }

    func resetAtDistanceEnRoute() {
        self.currentlyUnderAtDistance = false
        self.shouldNotifyEnRoute = false
    }

    // MARK: - Pre-Tracking Algorithm and Notifications
    public func notifyIfWithinDistance(_ lastLocation: CLLocation) {
        // check if location update is recent and accurate enough
        let age = -lastLocation.timestamp.timeIntervalSinceNow
        if (lastLocation.horizontalAccuracy < 0 || lastLocation.horizontalAccuracy > 65.0 || age > 20) {
            return
        }

        // check speed at last location
        // walking = 1.4, running = 3.7 -> set to 5 to only capture biking and driving
        if (lastLocation.speed > 5) {
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

                        // notify if within condition distance but NOT a geofence trip
                        if regionType == "atdistance" {
                            // check if time is correct for notifying
                            if self.lastNotifiedAtDistance != nil {
                                let currentDate = Date()
                                let oldDatePlusThreshold = self.lastNotifiedAtDistance!.addingTimeInterval(self.timeThreshold)

                                // currentDate must be later than lastNotifiedAtDistance + threshold
                                if oldDatePlusThreshold > currentDate {
                                    continue
                                }
                            }

                            // compute angle between heading and location
                            let bearing = getBearingBetweenTwoPoints(point1: lastLocation, point2: monitorLocation)
                            let course = getBearingBetweenTwoPoints(point1: self.previousLocation!, point2: self.currentLocation!)
                            let angle = angleCourseBearing(course: course, bearing: bearing)

                            // don't ask for AtDistance again until data refresh to prevent geofence bouncing
                            // check if already under AtDistance before seeing to ping
                            // check if shouldNotifyAtDistance for the location
                            // check if AtDistance is less than notifyAtDistanceDistance
                            if let notifiedAtDistanceForLocation = self.locationDic[regionId]?["notifiedAtDistance"],
                                let shouldNotifyAtDistance = self.locationDic[regionId]?["shouldNotifyAtDistance"],
                                let atDistanceDistance = self.locationDic[regionId]?["atDistanceDistance"],
                                let atLocationDistance = self.locationDic[regionId]?["atLocationDistance"] {
                                // distance should be between AtLocation and AtDistance distances
                                let validDistance = (distanceToLocation <= (atDistanceDistance as! Double)) &&
                                    (distanceToLocation > (atLocationDistance as! Double))

                                if !self.currentlyUnderAtDistance && !(shouldNotifyAtDistance as! Bool) &&
                                    (!(notifiedAtDistanceForLocation as! Bool) && validDistance) {
                                    // update notification time
                                    self.lastNotifiedAtDistance = Date()

                                    // update location dict
                                    self.locationDic[regionId]?["notifiedAtDistance"] = true

                                    // log notification to parse
                                    let epochTimestamp = Int(Date().timeIntervalSince1970)
                                    let gmtOffset = NSTimeZone.local.secondsFromGMT()
                                    let didIncludeInfoAtDistance: Bool = !(currentRegion["preferredInfo"] as! String == "") &&
                                        (shouldNotifyAtDistance as! Bool)

                                    let newResponse = PFObject(className: "AtDistanceNotificationsSent")
                                    newResponse["vendorId"] = vendorId
                                    newResponse["taskLocationId"] = currentRegion["id"] as! String
                                    newResponse["locationType"] = currentRegion["locationType"] as! String
                                    newResponse["notificationDistance"] = self.locationDic[regionId]?["atDistanceDistance"] as! Double
                                    newResponse["infoIncluded"] = didIncludeInfoAtDistance
                                    newResponse["timestamp"] = epochTimestamp
                                    newResponse["gmtOffset"] = gmtOffset
                                    newResponse["distanceToLocation"] = distanceToLocation
                                    newResponse["bearingToLocation"] = angle
                                    newResponse.saveInBackground()

                                    // Show alert if app active, else local notification
                                    if UIApplication.shared.applicationState == .active {
                                        print("Application is active")
                                        if let viewController = window?.rootViewController {
                                            let alert = UIAlertController(title: "Region Entered", message: "You are near \(regionId).",
                                                preferredStyle: .alert)
                                            let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                                            alert.addAction(action)
                                            viewController.present(alert, animated: true, completion: nil)
                                        }
                                    } else {
                                        // create contextual responses
                                        var currNotificationSet = Set<UNNotificationCategory>()
                                        let currCategory = UNNotificationCategory(identifier: "atdistance",
                                                                                  actions: createActionsForAnswers(currentRegion["atDistanceResponses"] as! [String],
                                                                                                                   includeIdk: false),
                                                                                  intentIdentifiers: [],
                                                                                  options: [.customDismissAction])
                                        currNotificationSet.insert(currCategory)
                                        UNUserNotificationCenter.current().setNotificationCategories(currNotificationSet)

                                        // Display notification with context
                                        let content = UNMutableNotificationContent()
                                        content.body = currentRegion["atDistanceMessage"] as! String
                                        content.sound = UNNotificationSound.default()
                                        content.categoryIdentifier = "atdistance"
                                        content.userInfo = currentRegion

                                        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 1, repeats: false)
                                        let notificationRequest = UNNotificationRequest(identifier: currentRegion["id"]! as! String,
                                                                                        content: content, trigger: trigger)

                                        UNUserNotificationCenter.current().add(notificationRequest, withCompletionHandler: { (error) in
                                            if let error = error {
                                                print("Error in notifying from Pre-Tracker: \(error)")
                                            }
                                        })
                                        
                                        print("asking atDistance for region based on location \(region.identifier)")
                                    }

                                }
                            }
                        } else {
                            // check if beacon region before notifying
                            if beaconId == "" {
                                // print("Pretracker found a Geofence Region w/o beacon (\(regionId))...beginning pretracking.")
                                if let currentLocationInfo = self.locationDic[regionId] {
                                    // notify under two conditions
                                    // EnRoute and user has positively responded to AtDistance
                                    // AtLocation and user has user has not been notifiedAtLocation
                                    let hasBeenNotifiedForRegion = currentLocationInfo["notifiedAtLocation"] as! Bool
                                    if ((regionType == "enroute") && self.shouldNotifyEnRoute) ||
                                        ((regionType == "atlocation") && !hasBeenNotifiedForRegion) {
                                        let notificationDistance = currentLocationInfo["atLocationDistance"] as! Double

                                        if (distanceToLocation <= notificationDistance) {
                                            if (regionType == "atlocation") {
                                                self.locationDic[regionId]?["withinAtLocation"] = true
                                            }
                                            self.locationDic[regionId]?["notifiedAtLocation"] = true

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

            // make sure not a atDistance region
            if regionType == "atdistance" {
                return
            }

            // if atLocation, check if time is correct
            if regionType == "atlocation" {
                if self.lastNotifiedAtLocation != nil {
                    let currentDate = Date()
                    let oldDatePlusThreshold = self.lastNotifiedAtLocation!.addingTimeInterval(self.timeThreshold)

                    // currentDate must be later than lastNotifiedAtLocation + threshold
                    if oldDatePlusThreshold > currentDate {
                        return
                    }
                }
            }

            print("notify for region id \(regionId)")

            // get NSUserDefaults
            var monitoredHotspotDictionary = appUserDefaults!.dictionary(forKey: savedHotspotsRegionKey) ?? [:]
            if let currentRegion = monitoredHotspotDictionary[regionId] as? [String : AnyObject] {
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

                if regionType != "enroute" {
                    // AtLocation Notifications
                    let newResponse = PFObject(className: "AtLocationNotificationsSent")
                    newResponse["vendorId"] = vendorId
                    newResponse["taskLocationId"] = currentRegion["id"] as! String
                    newResponse["timestamp"] = epochTimestamp
                    newResponse["gmtOffset"] = gmtOffset
                    newResponse["notificationString"] = notificationString
                    newResponse["distanceToLocation"] = distanceToLocation
                    newResponse.saveInBackground()

                    // update notification time
                    self.lastNotifiedAtLocation = Date()
                } else {
                    // EnRoute Notifications
                    let newResponse = PFObject(className: "EnRouteNotificationsSent")
                    newResponse["vendorId"] = vendorId
                    newResponse["enRouteLocationId"] = currentRegion["id"] as! String
                    newResponse["timestamp"] = epochTimestamp
                    newResponse["gmtOffset"] = gmtOffset
                    newResponse["notificationString"] = notificationString
                    newResponse["distanceToLocation"] = distanceToLocation
                    newResponse.saveInBackground()
                }

                // Show alert if app active, else local notification
                if UIApplication.shared.applicationState == .active {
                    print("Application is active")
                    if let viewController = window?.rootViewController {
                        let alert = UIAlertController(title: "Region Entered", message: "You are near \(regionId).", preferredStyle: .alert)
                        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                        alert.addAction(action)
                        viewController.present(alert, animated: true, completion: nil)
                    }
                } else {
                    // create contextual responses
                    var currNotificationSet = Set<UNNotificationCategory>()
                    let currCategory = UNNotificationCategory(identifier: currentRegion["notificationCategory"] as! String,
                                                              actions: createActionsForAnswers(currentRegion["atLocationResponses"] as! [String],
                                                                                               includeIdk: false),
                                                              intentIdentifiers: [],
                                                              options: [.customDismissAction])
                    currNotificationSet.insert(currCategory)
                    UNUserNotificationCenter.current().setNotificationCategories(currNotificationSet)

                    // Display notification with context
                    let content = UNMutableNotificationContent()
                    content.body = currentRegion["atLocationMessage"] as! String
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
        
        timer = Timer.scheduledTimer(timeInterval: intervalLength, target: self, selector: #selector(MyPretracker.restartLocationUpdates),
                                     userInfo: nil, repeats: false)
        
        // keep location manager inactive for 10 seconds every minute to save battery
        if (delay10Seconds != nil) {
            delay10Seconds!.invalidate()
            delay10Seconds = nil
        }
        delay10Seconds = Timer.scheduledTimer(timeInterval: delayLength, target: self, selector: #selector(MyPretracker.stopLocationWithDelay),
                                              userInfo: nil, repeats: false)
    }
    
    func saveCurrentLocationToParse() {
        let lastLocation = (locationManager?.location)!
        
        // store location updates if greater than threshold
        if (lastLocation.horizontalAccuracy > 0 && lastLocation.horizontalAccuracy < 65.0) {
            let distance = calculateDistance(currentLocation: lastLocation)
            
            if (distance >= distanceUpdate) {
                let epochTimestamp = Int(Date().timeIntervalSince1970)
                let gmtOffset = NSTimeZone.local.secondsFromGMT()
                
                let newLocationUpdate = PFObject(className: "LocationUpdates")
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
            if (regionInfo["withinAtLocation"] as! Bool) || (regionInfo["withinAtDistance"] as! Bool){
                return false
            }
        }
        return true
    }
    
    // check if user has entered a region. if AtDistance region, notify them if they have not already received a notification. else, pre-track.
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

            // check speed at last location
            // walking = 1.4, running = 3.7 -> set to 5 to only capture biking and driving
            if (lastlocation.speed > 5) {
                return
            }

            print("did enter region \(region.identifier)")

            // compute distance to region from current location
            let monitorRegion = region as! CLCircularRegion
            let monitorRegionLocation = CLLocation(latitude: monitorRegion.center.latitude, longitude: monitorRegion.center.longitude)
            let distanceToLocation = lastlocation.distance(from: monitorRegionLocation)

            // split region identifier into id and type
            let regionComponents = region.identifier.components(separatedBy: "_")
            let regionId = regionComponents[0]
            let regionType = regionComponents[1] // enroute, atdistance, atlocation

            // only notify for geofence if atDistance. all others will be handled through pre-tracking
            if regionType == "atdistance" {
                // check if user has currently been notified for at atDistance location
                if self.currentlyUnderAtDistance {
                    return
                }

                // check if we have already asked the user atDistance
                if let alreadyAskedAtDistance = self.locationDic[regionId]?["notifiedAtDistance"] {
                    if alreadyAskedAtDistance as! Bool {
                        return
                    }
                }

                // check if time is correct for notifying
                if self.lastNotifiedAtDistance != nil {
                    let currentDate = Date()
                    let oldDatePlusThreshold = self.lastNotifiedAtDistance!.addingTimeInterval(self.timeThreshold)

                    // currentDate must be later than lastNotifiedAtDistance + threshold
                    if oldDatePlusThreshold > currentDate {
                        return
                    }
                }

                // update notification time and location dict
                self.lastNotifiedAtDistance = Date()
                self.locationDic[regionId]?["notifiedAtDistance"] = true

                // calculate angle to location
                let bearing = getBearingBetweenTwoPoints(point1: lastlocation, point2: monitorRegionLocation)
                let course = getBearingBetweenTwoPoints(point1: self.previousLocation!, point2: self.currentLocation!)
                let angle = angleCourseBearing(course: course, bearing: bearing)

                // get location object from NSUserDefaults
                var monitoredHotspotDictionary = appUserDefaults!.dictionary(forKey: savedHotspotsRegionKey) ?? [:]
                if let currentRegion = monitoredHotspotDictionary[regionId] as? [String : AnyObject] {
                    // log notification to Parse
                    let epochTimestamp = Int(Date().timeIntervalSince1970)
                    let gmtOffset = NSTimeZone.local.secondsFromGMT()
                    let didIncludeInfoAtDistance: Bool = !(currentRegion["preferredInfo"] as! String == "") &&
                        (currentRegion["shouldNotifyAtDistance"] as! Bool)

                    let newResponse = PFObject(className: "AtDistanceNotificationsSent")
                    newResponse["vendorId"] = vendorId
                    newResponse["taskLocationId"] = currentRegion["id"] as! String
                    newResponse["locationType"] = currentRegion["locationType"] as! String
                    newResponse["notificationDistance"] = self.locationDic[regionId]?["atDistanceDistance"] as! Double
                    newResponse["infoIncluded"] = didIncludeInfoAtDistance
                    newResponse["timestamp"] = epochTimestamp
                    newResponse["gmtOffset"] = gmtOffset
                    newResponse["distanceToLocation"] = distanceToLocation
                    newResponse["bearingToLocation"] = angle
                    newResponse.saveInBackground()

                    // Show alert if app active, else local notification
                    if UIApplication.shared.applicationState == .active {
                        print("Application is active")
                        if let viewController = window?.rootViewController {
                            let alert = UIAlertController(title: "Region Entered", message: "You are near \(regionId).", preferredStyle: .alert)
                            let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                            alert.addAction(action)
                            viewController.present(alert, animated: true, completion: nil)
                        }
                    } else {
                        // create contextual responses
                        var currNotificationSet = Set<UNNotificationCategory>()
                        let currCategory = UNNotificationCategory(identifier: "atdistance",
                                                                  actions: createActionsForAnswers(currentRegion["atDistanceResponses"] as! [String],
                                                                                                   includeIdk: false),
                                                                  intentIdentifiers: [],
                                                                  options: [.customDismissAction])
                        currNotificationSet.insert(currCategory)
                        UNUserNotificationCenter.current().setNotificationCategories(currNotificationSet)

                        // Display notification with context
                        let content = UNMutableNotificationContent()
                        content.body = currentRegion["atDistanceMessage"] as! String
                        content.sound = UNNotificationSound.default()
                        content.categoryIdentifier = "atdistance"
                        content.userInfo = currentRegion

                        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 1, repeats: false)
                        let notificationRequest = UNNotificationRequest(identifier: currentRegion["id"]! as! String,
                                                                        content: content, trigger: trigger)

                        UNUserNotificationCenter.current().add(notificationRequest, withCompletionHandler: { (error) in
                            if let error = error {
                                print("Error in notifying from Pre-Tracker: \(error)")
                            }
                        })

                        print("asking expand for region based on geofence \(region.identifier)")
                    }
                }

                self.locationDic[regionId]?["withinAtDistance"] = true
            } else {
                // pretrack for any locations that are not AtDistance
                locationManager!.desiredAccuracy = kCLLocationAccuracyBestForNavigation
                locationManager!.distanceFilter = kCLDistanceFilterNone
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if !(region is CLBeaconRegion) {
            print("did exit region \(region.identifier)")

            // split region identifier into id and type
            let regionComponents = region.identifier.components(separatedBy: "_")
            let regionId = regionComponents[0]
            let regionType = regionComponents[1] // enroute, atdistance, atlocation

            // reset withinAtDistance or withinAtLocation based on regionType
            if regionType == "atdistance" {
                self.locationDic[regionId]?["withinAtDistance"] = false
            } else {
                self.locationDic[regionId]?["withinAtLocation"] = false
            }
            self.locationDic[regionId]?["notifiedAtLocation"] = false
            
            if outOfAllRegions() {
                locationManager!.desiredAccuracy = self.accuracy
                locationManager!.distanceFilter = self.distanceFilter
            }
        }
    }
    
    //MARK: - Location Manager Delegate Error Functions
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
        let epochTimestamp = Int(Date().timeIntervalSince1970)
        let gmtOffset = NSTimeZone.local.secondsFromGMT()
        
        let newLog = PFObject(className: "DebugLog")
        newLog["vendorId"] = vendorId
        newLog["timestamp"] = epochTimestamp
        newLog["logString"] = "Location manager failed with error: \(error.localizedDescription)"
        newLog["gmtOffset"] = gmtOffset
        newLog.saveInBackground()
    }
    
    public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Error monitoring failed for geofence region: \(String(describing: region)) with error \(error.localizedDescription)")
        let epochTimestamp = Int(Date().timeIntervalSince1970)
        let gmtOffset = NSTimeZone.local.secondsFromGMT()

        let newLog = PFObject(className: "DebugLog")
        newLog["vendorId"] = vendorId
        newLog["timestamp"] = epochTimestamp
        newLog["logString"] = "Error monitoring failed for geofence region: \(String(describing: region)) with error \(error.localizedDescription)"
        newLog["gmtOffset"] = gmtOffset
        newLog.saveInBackground()
    }
    
    public func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        let epochTimestamp = Int(Date().timeIntervalSince1970)
        let gmtOffset = NSTimeZone.local.secondsFromGMT()
        
        let newLog = PFObject(className: "DebugLog")
        newLog["vendorId"] = vendorId
        newLog["timestamp"] = epochTimestamp
        newLog["logString"] = "Location Updates Paused by iOS"
        newLog["gmtOffset"] = gmtOffset
        newLog.saveInBackground()
    }
    
    public func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        let epochTimestamp = Int(Date().timeIntervalSince1970)
        let gmtOffset = NSTimeZone.local.secondsFromGMT()
        
        let newLog = PFObject(className: "DebugLog")
        newLog["vendorId"] = vendorId
        newLog["timestamp"] = epochTimestamp
        newLog["logString"] = "Location Updates Resumed by iOS"
        newLog["gmtOffset"] = gmtOffset
        newLog.saveInBackground()
    }
}
