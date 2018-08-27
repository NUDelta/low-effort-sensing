//
//  AppDelegate.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 1/24/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
// 
//  Images Used
//  Double Tap (icon, splash screen), Web Icon Set from thenounproject.com
//  Location (authorization page), Riccardo Avanzi from thenounproject.com
//  Notification (authorization page), Thomas Helbig from thenounproject.com

import UIKit
import UserNotifications
import Parse
import Bolts
import WatchConnectivity

let distanceFromTarget = 30.0
let geofenceRadius = 100.0
let savedHotspotsRegionKey = "savedMonitoredHotspots" // for saving currently monitored locations to NSUserDefaults
let myHotspotsRegionKey = "savedMarkedHotspots" // for saving all hotspots user has marked before
var vendorId: String = ""

// App Group for Sharing Data (dependent on build type)
#if DEBUG
    let appGroup = "group.com.delta.les-debug" // for debug builds
#else
    let appGroup = "group.com.delta.les"       // for enterprise distribution builds
#endif

// Server to use for local vs. deployed
#if DEBUG
    let parseServer = "http://10.0.129.101:5000/parse/" // home
//    let parseServer = "http://10.105.102.63:5000/parse/" // nu
//    let parseServer = "https://les-expand.herokuapp.com/parse/"
#else
    let parseServer = "https://les-expand.herokuapp.com/parse/"
#endif

// extension used to dismiss keyboard, from Esqarrouth
// http://stackoverflow.com/questions/24126678/close-ios-keyboard-by-touching-anywhere-using-swift
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

// converts string into ASCII integer array
extension String {
    var asciiArray: [UInt32] {
        return unicodeScalars.filter{$0.isASCII}.map{$0.value}
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate, UNUserNotificationCenterDelegate {
    // MARK: Class Variables
    var window: UIWindow?
    let watchSession = WCSession.default
    var shortcutItem: UIApplicationShortcutItem?
    
    let appUserDefaults = UserDefaults.init(suiteName: appGroup)
    var notificationCategories = Set<UNNotificationCategory>()
    
    // MARK: - AppDelegate Functions
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Check active state for 3D Touch Home actions
        var performShortcutDelegate = true
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            print("Application launched via shortcut")
            self.shortcutItem = shortcutItem
            
            performShortcutDelegate = false
        }

        // check for launch from significant location change and restart location tracking
        if let _ = launchOptions?[UIApplicationLaunchOptionsKey.location] {
            MyPretracker.sharedManager.locationManager!.stopUpdatingLocation()
            MyPretracker.sharedManager.locationManager!.startUpdatingLocation()
            MyPretracker.sharedManager.locationManager!.startMonitoringSignificantLocationChanges()
        }
        
        // reset badge, if applicable
        UIApplication.shared.applicationIconBadgeNumber = 0;
        
        // Capture device's unique vendor id
        if let uuid = UIDevice.current.identifierForVendor?.uuidString {
            vendorId = uuid
        }
        
        // Initalize WatchSession
        watchSession.delegate = self
        watchSession.activate()
        
        // Initialize Parse.
        Parse.enableDataSharing(withApplicationGroupIdentifier: appGroup)
        Parse.initialize(with: ParseClientConfiguration(block: { (configuration: ParseMutableClientConfiguration) -> Void in
            configuration.server = parseServer
            configuration.applicationId = "PkngqKtJygU9WiQ1GXM9eC0a17tKmioKKmpWftYr"
            configuration.clientKey = "vsA30VpFQlGFKhhjYdrPttTvbcg1JxkbSSNeGCr7"
        }))
        
        // location manager and setting up monitored locations
        MyPretracker.sharedManager.setupParameters(distanceFromTarget,
                                                   radius: geofenceRadius,
                                                   accuracy: kCLLocationAccuracyHundredMeters,
                                                   distanceFilter: nil)
        
        // setup beacon manager
        BeaconTracker.sharedBeaconManager.initBeaconManager()
        
        // setup local notifications
        UNUserNotificationCenter.current().delegate = self
        
        // create default category for notification without any questions asked
        notificationCategories.insert(UNNotificationCategory(identifier: "no question", actions: [], intentIdentifiers: [], options: [.customDismissAction]))

        // create observer for low-power mode toggling
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(AppDelegate.didChangePowerState),
            name: NSNotification.Name.NSProcessInfoPowerStateDidChange,
            object: nil
        )
        
        // check if user is logged in, if not present login screen
        let currentUser = PFUser.current()
        if currentUser != nil {
            // print logged in user
            print(currentUser!)

            // register categories for notifications
            registerForNotifications()

            // open map view
            self.window = UIWindow(frame: UIScreen.main.bounds)
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let homeViewController = mainStoryboard.instantiateViewController(withIdentifier: "HomeScreenViewController")

            self.window?.rootViewController = homeViewController
            self.window?.makeKeyAndVisible()
        }
        
        // show light-colored status bar on each page
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .lightContent

        return performShortcutDelegate
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        print("App will resign active")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("App will enter background")
        
        // Log app going into background
        let epochTimestamp = Int(Date().timeIntervalSince1970)
        let gmtOffset = NSTimeZone.local.secondsFromGMT()

        let newLog = PFObject(className: "DebugLog")
        newLog["vendorId"] = vendorId
        newLog["timestamp"] = epochTimestamp
        newLog["logString"] = "App entering background"
        newLog["gmtOffset"] = gmtOffset
        newLog.saveInBackground()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        print("App will enter foreground")
        
        // Log app going into foreground
        let epochTimestamp = Int(Date().timeIntervalSince1970)
        let gmtOffset = NSTimeZone.local.secondsFromGMT()

        let newLog = PFObject(className: "DebugLog")
        newLog["vendorId"] = vendorId
        newLog["timestamp"] = epochTimestamp
        newLog["logString"] = "App entering foreground"
        newLog["gmtOffset"] = gmtOffset
        newLog.saveInBackground()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("Application did become active")
        
        guard let shortcut = shortcutItem else { return }
        print("- Shortcut property has been set")
        let _ = handleShortcut(shortcut)
        self.shortcutItem = nil
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("App will terminate")
        
        // Log app about to terminate
        let epochTimestamp = Int(Date().timeIntervalSince1970)
        let gmtOffset = NSTimeZone.local.secondsFromGMT()

        let newLog = PFObject(className: "DebugLog")
        newLog["vendorId"] = vendorId
        newLog["timestamp"] = epochTimestamp
        newLog["logString"] = "App about to terminate"
        newLog["gmtOffset"] = gmtOffset
        newLog.saveInBackground()
        do {
            try newLog.save()
        } catch _ {
            print("Error")
        }
    }

    // save transitions from power state
    @objc func didChangePowerState() {
        print("Phone power state toggled")
        let epochTimestamp = Int(Date().timeIntervalSince1970)
        let gmtOffset = NSTimeZone.local.secondsFromGMT()

        let newLog = PFObject(className: "DebugLog")
        newLog["vendorId"] = vendorId
        newLog["timestamp"] = epochTimestamp
        newLog["gmtOffset"] = gmtOffset

        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            newLog["logString"] = "Low-power mode enabled"
        } else {
            newLog["logString"] = "Low-power mode disabled"
        }

        do {
            try newLog.save()
        } catch _ {
            print("Error")
        }
    }

    // MARK: - Notification Setup Functions
    func registerForNotifications() {
        print("Registering categories for local notifications")

        let currentUser = PFUser.current()
        if currentUser != nil {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: { (granted, error) in
                if (granted) {
                    // setup notification categories
                    UNUserNotificationCenter.current().setNotificationCategories(self.notificationCategories)
                    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

                    // setup remote notifications
                    DispatchQueue.main.async(execute: {
                        UIApplication.shared.registerForRemoteNotifications()
                    })

                    print("Notification setup complete")
                } else {
                    print("Error when registering for notifications: \(String(describing: error))")
                }
            })
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // create hashed remote notification token
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})

        // save new push token
        let currentUser = PFUser.current()
        if let currentUser = currentUser {
            currentUser["vendorId"] = vendorId
            currentUser["pushToken"] = deviceTokenString
            currentUser.saveInBackground(block: ({ (success: Bool, error: Error?) -> Void in
                if (!success) {
                    print("Error in saving new location to Parse: \(String(describing: error)). Attempting eventually.")
                    currentUser.saveEventually()
                }
            }))

            // print token for debugging
            print("updating push token for current user: \(deviceTokenString)")
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("\(userInfo)")
        
        // refresh data when notification is received
        if (userInfo.index(forKey: "updateType") != nil) {
            if let updateType = userInfo["updateType"] as? String {
                if (updateType == "beacon") {
                    BeaconTracker.sharedBeaconManager.clearAllMonitoredRegions()
                    BeaconTracker.sharedBeaconManager.beginMonitoringParseRegions()
                } else if (updateType == "trackedlocations") {
                    MyPretracker.sharedManager.refreshLocationsFromParse()
                } else if (updateType == "heartbeat") {
                    // Log application heartbeat
                    let epochTimestamp = Int(Date().timeIntervalSince1970)
                    let gmtOffset = NSTimeZone.local.secondsFromGMT()
                    
                    let newLog = PFObject(className: "ApplicationHeartbeat")
                    newLog["vendorId"] = vendorId
                    newLog["timestamp"] = epochTimestamp
                    newLog["logString"] = "Application heartbeat"
                    newLog["gmtOffset"] = gmtOffset
                    newLog.saveInBackground()
                } else if (updateType == "location") {
                    MyPretracker.sharedManager.locationManager!.stopUpdatingLocation()
                    MyPretracker.sharedManager.locationManager!.startUpdatingLocation()
                } else if (updateType == "resetatdistance") {
                    // reset variables to ping for expand locations only
                    MyPretracker.sharedManager.resetAtDistanceEnRoute()
                }
                
                completionHandler(UIBackgroundFetchResult.newData)
            }
        } else {
            completionHandler(UIBackgroundFetchResult.noData)
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Print the error to console (you should alert the user that registration failed)
        print("APNs registration failed: \(error)")
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }

    //MARK: - Contextual Notification Handler
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // check if user has tapped on notification and open response view if so
        // else, handle contextual response
        if response.actionIdentifier == "com.apple.UNNotificationDefaultActionIdentifier" &&
            response.notification.request.content.categoryIdentifier != "" {
            print("opening Respond To Other view")
            // create view controller
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let respondToOtherViewController = storyboard.instantiateViewController(withIdentifier:
                "RespondToOtherViewController") as! RespondToOtherViewController

            // setup data
            respondToOtherViewController.setCurrentVariables((response.notification.request.content.userInfo as? [String : AnyObject])!,
                                                             categoryIdentifier: response.notification.request.content.categoryIdentifier)

            // open view
            self.window?.rootViewController = respondToOtherViewController
            self.window?.makeKeyAndVisible()
        } else if (response.notification.request.content.categoryIdentifier == "atdistance") {
            print("AtDistance Response")

            // get UTC timestamp and timezone of notification
            let epochTimestamp = Int(Date().timeIntervalSince1970)
            let gmtOffset = NSTimeZone.local.secondsFromGMT()

            // create values needed to push to DB
            let currentRegion = response.notification.request.content.userInfo as? [String : AnyObject]
            var notificationId = ""
            var didIncludeInfoAtDistance: Bool = false
            var notificationDistance: Double = 0.0
            var locationTypeString: String = ""

            if let unwrappedNotificationId = currentRegion!["id"] {
                notificationId = unwrappedNotificationId as! String
            }

            if let preferredInfo = currentRegion!["preferredInfo"], let shouldNotifyAtDistance = currentRegion!["shouldNotifyAtDistance"] {
                didIncludeInfoAtDistance = !(preferredInfo as! String == "") && (shouldNotifyAtDistance as! Bool)
            }

            if let locationType = currentRegion!["locationType"] {
                locationTypeString = locationType as! String
            }

            if let atDistanceNotificationDistance = currentRegion!["atDistanceNotificationDistance"] {
                notificationDistance = atDistanceNotificationDistance as! Double
            }

            // setup response object and push to parse
            let newResponse = PFObject(className: "AtDistanceNotificationResponses")
            newResponse["vendorId"] = vendorId
            newResponse["taskLocationId"] = notificationId
            newResponse["locationType"] = locationTypeString
            newResponse["notificationDistance"] = notificationDistance
            newResponse["infoIncluded"] = didIncludeInfoAtDistance
            newResponse["timestamp"] = epochTimestamp
            newResponse["gmtOffset"] = gmtOffset
            newResponse["emaResponse"] = response.actionIdentifier

            // if response field is not blank, save to parse
            if newResponse["emaResponse"] as! String != "" {
                // add current location data before saving
                var currLocation: PFGeoPoint
                if let managerCurrLocation = MyPretracker.sharedManager.currentLocation {
                    currLocation = PFGeoPoint.init(location: managerCurrLocation)
                } else {
                    currLocation = PFGeoPoint.init()
                }

                newResponse["location"] = currLocation

                // save logic
                newResponse.saveInBackground(block: { (saved: Bool, error: Error?) -> Void in
                    // if save is unsuccessful (due to network issues) saveEventually when network is available
                    if !saved {
                        print("Error in saveInBackground: \(String(describing: error)). Attempting eventually.")
                        newResponse.saveEventually()
                    }
                })
            }

            // set variables to notify for EnRoute and AtDistance
            let responseAcceptSet: Set = [
                "Yes! This info is useful. I'm going to go there.",
                "Yes. This info is useful but I'm already going there.",
                "Sure! I would be happy to go out of my way!",
                "Sure, but I was going to walk past it anyway."
            ]
            if (responseAcceptSet.contains(response.actionIdentifier)) {
                MyPretracker.sharedManager.setShouldNotifyAtDistance(id: notificationId, value: true)
                MyPretracker.sharedManager.setShouldNotifyEnRoute(value: true)
            }
        } else if (response.notification.request.content.categoryIdentifier == "enroute") {
            print("En Route response")

            // get UTC timestamp and timezone of notification
            let epochTimestamp = Int(Date().timeIntervalSince1970)
            let gmtOffset = NSTimeZone.local.secondsFromGMT()

            // setup response object to push to parse
            var notificationId = ""
            if let unwrappedNotificationId = response.notification.request.content.userInfo["id"] {
                notificationId = unwrappedNotificationId as! String
            }

            let newResponse = PFObject(className: "EnRouteNotificationResponses")
            newResponse["vendorId"] = vendorId
            newResponse["enRouteLocationId"] = notificationId
            newResponse["timestamp"] = epochTimestamp
            newResponse["gmtOffset"] = gmtOffset
            newResponse["questionResponse"] = response.actionIdentifier

            // if response field is not blank, save to parse
            if newResponse["questionResponse"] as! String != "" {
                // add current location data before saving
                var currLocation: PFGeoPoint
                if let managerCurrLocation = MyPretracker.sharedManager.currentLocation {
                    currLocation = PFGeoPoint.init(location: managerCurrLocation)
                } else {
                    currLocation = PFGeoPoint.init()
                }

                newResponse["location"] = currLocation

                // save logic
                newResponse.saveInBackground(block: { (saved: Bool, error: Error?) -> Void in
                    // if save is unsuccessful (due to network issues) saveEventually when network is available
                    if !saved {
                        print("Error in saveInBackground: \(String(describing: error)). Attempting eventually.")
                        newResponse.saveEventually()
                    }
                })
            }
        } else if (response.notification.request.content.categoryIdentifier != "") {
            // setup response object to push to parse
            var notificationId = ""
            if let unwrappedNotificationId = response.notification.request.content.userInfo["id"] {
                notificationId = unwrappedNotificationId as! String
            }

            // save response iff actual response, BUT reset location state anyway
            print("At location response")

            // get UTC timestamp and timezone of notification
            let epochTimestamp = Int(Date().timeIntervalSince1970)
            let gmtOffset = NSTimeZone.local.secondsFromGMT()

            // get scenario and question as separate components
            let notificationCategoryArr = response.notification.request.content.categoryIdentifier.components(separatedBy: "_")

            let newResponse = PFObject(className: "AtLocationNotificationResponses")
            newResponse["vendorId"] = vendorId
            newResponse["taskLocationId"] = notificationId
            newResponse["locationType"] = notificationCategoryArr[0]
            newResponse["question"] = notificationCategoryArr[1]
            newResponse["response"] = response.actionIdentifier
            newResponse["timestamp"] = epochTimestamp
            newResponse["gmtOffset"] = gmtOffset

            // if response field is not blank, save to parse
            if newResponse["response"] as! String != "" {
                // add current location data before saving
                var currLocation: PFGeoPoint
                if let managerCurrLocation = MyPretracker.sharedManager.currentLocation {
                    currLocation = PFGeoPoint.init(location: managerCurrLocation)
                } else {
                    currLocation = PFGeoPoint.init()
                }

                newResponse["location"] = currLocation

                // save logic
                newResponse.saveInBackground(block: { (saved: Bool, error: Error?) -> Void in
                    // if save is unsuccessful (due to network issues) saveEventually when network is available
                    if !saved {
                        print("Error in saveInBackground: \(String(describing: error)). Attempting eventually.")
                        newResponse.saveEventually()
                    }
                })
            }

            // reset EnRoute and UnderAtDistance if the id of the current response matches last AtDistance
            let currentAtDistanceLocation = MyPretracker.sharedManager.currentAtDistanceLocation
            if (currentAtDistanceLocation != "") && (notificationId == currentAtDistanceLocation) {
                MyPretracker.sharedManager.setShouldNotifyAtDistance(id: notificationId, value: false)
                MyPretracker.sharedManager.setShouldNotifyEnRoute(value: false)
            }
        }

        // if code gets to here, just open the app and do nothing with the contextual response
        completionHandler()
    }

    // MARK: - 3D Touch shortcut handler
    // TODO: use the contextual notification code above to ensure no weird errors with views existing affect transitioning
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void){
        completionHandler(handleShortcut(shortcutItem))
    }
    
    func handleShortcut( _ shortcutItem:UIApplicationShortcutItem ) -> Bool {
        print("Handling \(shortcutItem.type)")
        //        PFGeoPoint.geoPointForCurrentLocation(inBackground: ({
        //            (geoPoint: PFGeoPoint?, error: Error?) -> Void in
        //            if error == nil {
        //                // create tag based on shortcut
        //                var tag = ""
        //                var tagDescription = ""
        //                switch shortcutItem.type {
        //                case "com.delta.low-effort-sensing.mark-food-location":
        //                    tag = "food"
        //                    tagDescription = "Free/Sold Food"
        //                default:
        //                    return
        //                }
        //
        //                // get UTC timestamp and timezone of notification
        //                let epochTimestamp = Int(Date().timeIntervalSince1970)
        //                let gmtOffset = NSTimeZone.local.secondsFromGMT()
        //
        //                // Get location and push to Parse
        //                let newMonitoredLocation = PFObject(className: "hotspot")
        //                newMonitoredLocation["vendorId"] = vendorId
        //                newMonitoredLocation["location"] = geoPoint
        //                newMonitoredLocation["tag"] = tag
        //                newMonitoredLocation["archived"] = false
        //                newMonitoredLocation["timestampCreated"] = epochTimestamp
        //                newMonitoredLocation["gmtOffset"] = gmtOffset
        //                newMonitoredLocation["timestampLastUpdate"] = epochTimestamp
        //                newMonitoredLocation["submissionMethod"] = "3d_touch"
        //                newMonitoredLocation["locationCommonName"] = ""
        //
        //                if let currBeaconRegion = self.appUserDefaults?.object(forKey: "currentBeaconRegion") {
        //                    if currBeaconRegion as? String != nil {
        //                        newMonitoredLocation["beaconId"] = currBeaconRegion as? String
        //                    } else {
        //                        newMonitoredLocation["beaconId"] = ""
        //                    }
        //                } else {
        //                    newMonitoredLocation["beaconId"] = ""
        //                }
        //
        //                // set info dict and saveTimeForQuestion based on tag
        //                switch tag {
        ////                case "food":
        ////                    newMonitoredLocation["info"] = foodInfo
        ////                    newMonitoredLocation["saveTimeForQuestion"] = ["type": epochTimestamp,
        ////                                                                   "quantity": epochTimestamp,
        ////                                                                   "freesold": epochTimestamp,
        ////                                                                   "cost": epochTimestamp,
        ////                                                                   "sellingreason": epochTimestamp]
        ////                    break
        //                default:
        //                    break
        //                }
        //
        //                // push to parse
        //                newMonitoredLocation.saveInBackground(block: ({ (success: Bool, error: Error?) -> Void in
        //                    if (!success) {
        //                        print("Error in saving new location to Parse: \(String(describing: error)).")
        //                    }
        //                }))
        //
        //                // present feedback to user letting them know it worked
        //                let title = "Location Marked for \(tagDescription) Tracking"
        //                let message = "Your current location has been marked for \(tagDescription) tracking. Check back later to see if someone has contributed information to it!"
        //
        //                let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        //                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        //
        //                self.window?.rootViewController?.present(alert, animated: true, completion: nil)
        //            }
        //        }))

        return true
    }
    
    // MARK: - WatchSession Communication Handler
    private func session(_ session: WCSession, didReceiveMessage message: [String : AnyObject],
                         replyHandler: @escaping ([String : AnyObject]) -> Void) {
        //        guard let command = message["command"] as! String! else {return}

        //        // Run command and return data to watch
        //        switch (command) {
        //            case "reportLocation":
        //                PFGeoPoint.geoPointForCurrentLocation(inBackground: ({
        //                    (geoPoint: PFGeoPoint?, error: Error?) -> Void in
        //                    if error == nil {
        //                        // Get current date to make debug string
        //                        let dateFormatter = DateFormatter()
        //                        dateFormatter.dateFormat = "dd-MM-YY_HH:mm"
        //
        //                        // Get location and push to Parse
        //                        let newMonitoredLocation = PFObject(className: "hotspot")
        //                        newMonitoredLocation["location"] = geoPoint
        //                        newMonitoredLocation["tag"] = "free food!"
        //                        newMonitoredLocation["info"] = ["foodType": "", "foodDuration": "", "stillFood": ""]
        //
        //                        newMonitoredLocation.saveInBackground(block: ({
        //                            (success: Bool, error: Error?) -> Void in
        //                            if (success) {
        //                                // add new location to monitored regions
        //                                let newRegionLat = (newMonitoredLocation["location"] as! PFGeoPoint).latitude
        //                                let newRegionLong = (newMonitoredLocation["location"] as! PFGeoPoint).longitude
        //                                let newRegionId = newMonitoredLocation.objectId!
        //                                MyPretracker.sharedManager.addLocation(distanceFromTarget, latitude: newRegionLat, longitude: newRegionLong,
        //                                                                       radius: geofenceRadius, id: newRegionId,
        //                                                                       expandRadius: 0, locationType: "exploit", hasBeacon: false)
        //
        //                                // Add new region to user defaults
        //                                var monitoredHotspotDictionary = self.appUserDefaults?.dictionary(forKey: savedHotspotsRegionKey) ?? Dictionary()
        //
        //                                // Add data to user defaults
        //                                var unwrappedEntry = [String : AnyObject]()
        //                                unwrappedEntry["latitude"] = newRegionLat as AnyObject
        //                                unwrappedEntry["longitude"] = newRegionLong as AnyObject
        //                                unwrappedEntry["id"] = newMonitoredLocation.objectId as AnyObject
        //                                unwrappedEntry["tag"] = newMonitoredLocation["tag"] as AnyObject
        //                                let info : [String : AnyObject]? = newMonitoredLocation["info"] as? [String : AnyObject]
        //                                unwrappedEntry["info"] = info as AnyObject
        //
        //                                monitoredHotspotDictionary[newMonitoredLocation.objectId!] = unwrappedEntry
        //                                self.appUserDefaults?.set(monitoredHotspotDictionary, forKey: savedHotspotsRegionKey)
        //                                self.appUserDefaults?.synchronize()
        //
        //                                // return information to apple watch
        //                                replyHandler(["response": unwrappedEntry as AnyObject])
        //                            }
        //                        }))
        //                    }
        //                }))
        //                break
        //            case "pushToParse":
        //                // Get dictionary from Watch app
        //                guard let watchDict = message["value"] as! [String : AnyObject]? else {return}
        //                let currentHotspotId = watchDict["id"] as! String
        //
        //                // Get current hotspot from stored hotspots
        //                var monitoredHotspotDictionary = self.appUserDefaults?.dictionary(forKey: savedHotspotsRegionKey) ?? Dictionary()
        //                var currentHotspot = monitoredHotspotDictionary[currentHotspotId] as! Dictionary<String, AnyObject>
        //
        //                currentHotspot["info"] = watchDict["info"]
        //                monitoredHotspotDictionary[currentHotspotId] = currentHotspot
        //                self.appUserDefaults?.set(monitoredHotspotDictionary, forKey: savedHotspotsRegionKey)
        //                self.appUserDefaults?.synchronize()
        //
        //                // Push data to parse
        //                let query = PFQuery(className: "hotspot")
        //                query.getObjectInBackground(withId: currentHotspotId, block: ({
        //                    (hotspot: PFObject?, error: Error?) -> Void in
        //                    if error != nil {
        //                        print("Error in pushing data to Parse: \(String(describing: error))")
        //
        //                        // return information to apple watch
        //                        replyHandler(["response": false as AnyObject])
        //                    } else if let hotspot = hotspot {
        //                        hotspot["info"] = watchDict["info"]
        //                        hotspot.saveInBackground()
        //
        //                        print("Pushing data to parse")
        //                        print(hotspot)
        //
        //                        // return information to apple watch
        //                        replyHandler(["response": true as AnyObject])
        //                    }
        //                }))
        //                break
        //            case "notificationOccured":
        //                // Get location id from Watch app
        //                guard let locationID = message["value"] as! String? else {return}
        //
        //                // Get current hotspot from stored hotspots
        //                var monitoredHotspotDictionary = self.appUserDefaults?.dictionary(forKey: savedHotspotsRegionKey) ?? Dictionary()
        //                let currentHotspot = monitoredHotspotDictionary[locationID] as! Dictionary<String, AnyObject>
        //
        //                // return information to apple watch
        //                replyHandler(["response": currentHotspot as AnyObject])
        //                break
        //            default:
        //                break
        //        }
    }
    
    @available(iOS 9.3, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: NSError?) {
        
    }
    
    @available(iOS 9.3, *)
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    @available(iOS 9.3, *)
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    @available(iOS 9.3, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
}
