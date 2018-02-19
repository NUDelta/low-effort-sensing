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
    let parseServer = "http://10.0.129.102:5000/parse/"
#else
    let parseServer = "https://les-expand.herokuapp.com/parse/"
#endif

// extension used to dismiss keyboard, from Esqarrouth http://stackoverflow.com/questions/24126678/close-ios-keyboard-by-touching-anywhere-using-swift
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

//            // DEBUG NOTIFICATION
//            Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(AppDelegate.sendNotification), userInfo: nil, repeats: true)
        }
        
        // show light-colored status bar on each page
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .lightContent
  
        return performShortcutDelegate
    }

    
//    // USED FOR DEBUGGING
//    func sendNotification() {
//        print("Preparing notification")
//        // Get NSUserDefaults
//        var monitoredHotspotDictionary = UserDefaults.init(suiteName: appGroup)?.dictionary(forKey: savedHotspotsRegionKey) ?? [:]
//        print(monitoredHotspotDictionary)
//        
//        // Get first region in mo nitored regions to use
//        if  monitoredHotspotDictionary.keys.count > 0 {
//            let currentRegion = monitoredHotspotDictionary["8C9gvBLjIR"] as! [String : AnyObject]
//            let newNotification = NotificationCreator(scenario: currentRegion["tag"] as! String, hotspotInfo: currentRegion["info"] as! [String : String], currentHotspot: currentRegion)
//            let notificationContent = newNotification.createNotificationForTag()
//            
//            print(notificationContent)
//            
//            // Display notification with context
//            let content = UNMutableNotificationContent()
//            content.body = notificationContent["message"]!
//            content.sound = UNNotificationSound.default()
//            content.categoryIdentifier = notificationContent["notificationCategory"]!
//            content.userInfo = currentRegion
//            
//            let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 3, repeats: false)
//            let notificationRequest = UNNotificationRequest(identifier: currentRegion["id"]! as! String, content: content, trigger: trigger)
//            
//            UNUserNotificationCenter.current().add(notificationRequest, withCompletionHandler: { (error) in
//                if let error = error {
//                    print("Error in notifying from Pre-Tracker: \(error)")
//                }
//            })
//        }
//    }
    
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
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDateString = dateFormatter.string(from: date)

        let newLog = PFObject(className: "pretracking_debug")
        newLog["vendor_id"] = vendorId
        newLog["timestamp_epoch"] = Int(date.timeIntervalSince1970)
        newLog["timestamp_string"] = currentDateString
        newLog["console_string"] = "App entering background"
        newLog.saveInBackground()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        print("App will enter foreground")
        
        // Log app going into foreground
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDateString = dateFormatter.string(from: date)
        
        let newLog = PFObject(className: "pretracking_debug")
        newLog["vendor_id"] = vendorId
        newLog["timestamp_epoch"] = Int(date.timeIntervalSince1970)
        newLog["timestamp_string"] = currentDateString
        newLog["console_string"] = "App entering foreground"
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
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDateString = dateFormatter.string(from: date)
        
        let newLog = PFObject(className: "pretracking_debug")
        newLog["vendor_id"] = vendorId
        newLog["timestamp_epoch"] = Int(date.timeIntervalSince1970)
        newLog["timestamp_string"] = currentDateString
        newLog["console_string"] = "App about to terminate"
        do {
            try newLog.save()
        } catch _ {
            print("Error")
        }
    }

    // save transitions from power state
    @objc func didChangePowerState() {
        print("Phone power state toggled")
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDateString = dateFormatter.string(from: date)

        let newLog = PFObject(className: "pretracking_debug")
        newLog["vendor_id"] = vendorId
        newLog["timestamp_epoch"] = Int(date.timeIntervalSince1970)
        newLog["timestamp_string"] = currentDateString

        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            newLog["console_string"] = "Low-power mode enabled"
        } else {
            newLog["console_string"] = "Low-power mode disabled"
        }

        do {
            try newLog.save()
        } catch _ {
            print("Error")
        }
    }
    
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
            currentUser.saveInBackground()

            // print token for debugging
            print("updating push token for current user: \(deviceTokenString)")
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("\(userInfo)")
        
        // refresh data when notification is received
        if (userInfo.index(forKey: "updateType") != nil) {
            if let updateType = userInfo["updateType"] as? String {
                if (updateType == "beacon") {
                    BeaconTracker.sharedBeaconManager.clearAllMonitoredRegions()
                    BeaconTracker.sharedBeaconManager.beginMonitoringParseRegions()
                } else if (updateType == "hotspot") {
                    MyPretracker.sharedManager.refreshLocationsFromParse()
                } else if (updateType == "heartbeat") {
                    // Log application heartbeat
                    let date = Date()
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    let currentDateString = dateFormatter.string(from: date)
                    
                    let newLog = PFObject(className: "pretracking_debug")
                    newLog["vendor_id"] = vendorId
                    newLog["timestamp_epoch"] = Int(date.timeIntervalSince1970)
                    newLog["timestamp_string"] = currentDateString
                    newLog["console_string"] = "Application heartbeat"
                    newLog.saveInBackground()
                } else if (updateType == "location") {
                    MyPretracker.sharedManager.locationManager!.requestLocation()
                    MyPretracker.sharedManager.saveCurrentLocationToParse()
                } else if (updateType == "reset-expand") {
                    // reset variables to ping for expand locations only
                    MyPretracker.sharedManager.resetExpandExploitOnly()
                    BeaconTracker.sharedBeaconManager.setShouldNotifyExpand(id: "")
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

    //MARK: - Contextual Notification Handler
    let responseIgnoreSet: Set = ["com.apple.UNNotificationDefaultActionIdentifier", "com.apple.UNNotificationDismissActionIdentifier"]
    // TODO: check if this is eXploit or eXpand. save appropiately to different classes
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // check if expand-outer ping, exploit ping, or ping at expand location
        if (response.notification.request.content.categoryIdentifier == "expand") {
            print("Expand (outer) response")

            // get UTC timestamp and timezone of notification
            let epochTimestamp = Int(Date().timeIntervalSince1970)
            let gmtOffset = NSTimeZone.local.secondsFromGMT()

            // setup response object to push to parse
            var notificationId = ""
            if let unwrappedNotificationId = response.notification.request.content.userInfo["id"] {
                notificationId = unwrappedNotificationId as! String
            }

            var levelOfInformation = ""
            if let unwrappedLevelOfInformation = response.notification.request.content.userInfo["levelOfInformation"] {
                levelOfInformation = unwrappedLevelOfInformation as! String
            }

            let newResponse = PFObject(className: "expandResponses")
            newResponse["vendorId"] = vendorId
            newResponse["hotspotId"] = notificationId
            newResponse["timestamp"] = epochTimestamp
            newResponse["gmtOffset"] = gmtOffset
            newResponse["emaResponse"] = response.actionIdentifier
            newResponse["distanceCondition"] = MyPretracker.sharedManager.expandNotificationDistance
            newResponse["levelOfInformation"] = levelOfInformation

            // if response field is not blank, save to parse
            if newResponse["emaResponse"] as! String != "" {
                newResponse.saveInBackground()
            }

            // make sure action is not default or dismissal for deciding to track location
            if (!responseIgnoreSet.contains(response.actionIdentifier)) {
                // set variables to ping for expand location and exploit locations if user responds yes
                let responseAcceptSet: Set = ["Yes! Great to know, I'm going to go now!", "Yes, but I was already going there."]
                if (responseAcceptSet.contains(response.actionIdentifier)) {
                    MyPretracker.sharedManager.setShouldNotifyExpand(id: notificationId, value: true)
                    MyPretracker.sharedManager.setShouldNotifyExploit(value: true)
                    BeaconTracker.sharedBeaconManager.setShouldNotifyExpand(id: notificationId)
                }
            }
        } else if (response.notification.request.content.categoryIdentifier == "exploit") {
            print("Exploit response")

            // get UTC timestamp and timezone of notification
            let epochTimestamp = Int(Date().timeIntervalSince1970)
            let gmtOffset = NSTimeZone.local.secondsFromGMT()

            // setup response object to push to parse
            var notificationId = ""
            if let unwrappedNotificationId = response.notification.request.content.userInfo["id"] {
                notificationId = unwrappedNotificationId as! String
            }

            let newResponse = PFObject(className: "exploitResponses")
            newResponse["vendorId"] = vendorId
            newResponse["exploitId"] = notificationId
            newResponse["timestamp"] = epochTimestamp
            newResponse["gmtOffset"] = gmtOffset
            newResponse["questionResponse"] = response.actionIdentifier

            // if response field is not blank, save to parse
            if newResponse["questionResponse"] as! String != "" {
                newResponse.saveInBackground()
            }
        } else {
            // setup response object to push to parse
            var notificationId = ""
            if let unwrappedNotificationId = response.notification.request.content.userInfo["id"] {
                notificationId = unwrappedNotificationId as! String
            }

            // save response iff actual response, BUT reset location state anyway
            print("Expand at location response")

            // get UTC timestamp and timezone of notification
            let epochTimestamp = Int(Date().timeIntervalSince1970)
            let gmtOffset = NSTimeZone.local.secondsFromGMT()

            // get scenario and question as separate components
            let notificationCategoryArr = response.notification.request.content.categoryIdentifier.components(separatedBy: "_")

            let newResponse = PFObject(className: "pingResponse")
            newResponse["vendorId"] = vendorId
            newResponse["hotspotId"] = notificationId
            newResponse["question"] = notificationCategoryArr[1]
            newResponse["response"] = response.actionIdentifier
            newResponse["tag"] = notificationCategoryArr[0]
            newResponse["timestamp"] = epochTimestamp
            newResponse["gmtOffset"] = gmtOffset

            // if response field is not blank, save to parse
            if newResponse["response"] as! String != "" {
                newResponse.saveInBackground()
            }

            // reset variables to ping for expand locations only
            MyPretracker.sharedManager.setShouldNotifyExpand(id: notificationId, value: false)
            MyPretracker.sharedManager.setShouldNotifyExploit(value: false)
            BeaconTracker.sharedBeaconManager.setShouldNotifyExpand(id: "")
        }

        completionHandler()
    }

    // MARK: - 3D Touch shortcut handler
    // TODO: use the contextual notification code above to ensure no weird errors with views existing affect transitioning
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void){
        completionHandler(handleShortcut(shortcutItem))
    }
    
    func handleShortcut( _ shortcutItem:UIApplicationShortcutItem ) -> Bool {
        print("Handling \(shortcutItem.type)")
        PFGeoPoint.geoPointForCurrentLocation(inBackground: ({
            (geoPoint: PFGeoPoint?, error: Error?) -> Void in
            if error == nil {
                // create tag based on shortcut
                var tag = ""
                var tagDescription = ""
                switch shortcutItem.type {
                case "com.delta.low-effort-sensing.mark-food-location":
                    tag = "food"
                    tagDescription = "Free/Sold Food"
                default:
                    return
                }
                
                // get UTC timestamp and timezone of notification
                let epochTimestamp = Int(Date().timeIntervalSince1970)
                let gmtOffset = NSTimeZone.local.secondsFromGMT()
                
                // Get location and push to Parse
                let newMonitoredLocation = PFObject(className: "hotspot")
                newMonitoredLocation["vendorId"] = vendorId
                newMonitoredLocation["location"] = geoPoint
                newMonitoredLocation["tag"] = tag
                newMonitoredLocation["archived"] = false
                newMonitoredLocation["timestampCreated"] = epochTimestamp
                newMonitoredLocation["gmtOffset"] = gmtOffset
                newMonitoredLocation["timestampLastUpdate"] = epochTimestamp
                newMonitoredLocation["submissionMethod"] = "3d_touch"
                newMonitoredLocation["locationCommonName"] = ""
                
                if let currBeaconRegion = self.appUserDefaults?.object(forKey: "currentBeaconRegion") {
                    if currBeaconRegion as? String != nil {
                        newMonitoredLocation["beaconId"] = currBeaconRegion as? String
                    } else {
                        newMonitoredLocation["beaconId"] = ""
                    }
                } else {
                    newMonitoredLocation["beaconId"] = ""
                }
                
                // set info dict and saveTimeForQuestion based on tag
                switch tag {
//                case "food":
//                    newMonitoredLocation["info"] = foodInfo
//                    newMonitoredLocation["saveTimeForQuestion"] = ["type": epochTimestamp,
//                                                                   "quantity": epochTimestamp,
//                                                                   "freesold": epochTimestamp,
//                                                                   "cost": epochTimestamp,
//                                                                   "sellingreason": epochTimestamp]
//                    break
                default:
                    break
                }
                
                // push to parse
                newMonitoredLocation.saveInBackground(block: ({ (success: Bool, error: Error?) -> Void in
                    if (!success) {
                        print("Error in saving new location to Parse: \(String(describing: error)).")
                    }
                }))
                
                // present feedback to user letting them know it worked
                let title = "Location Marked for \(tagDescription) Tracking"
                let message = "Your current location has been marked for \(tagDescription) tracking. Check back later to see if someone has contributed information to it!"
                
                let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                
                self.window?.rootViewController?.present(alert, animated: true, completion: nil)
            }
        }))
        
        return true
    }
    
    // MARK: - WatchSession Communication Handler
    private func session(_ session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: @escaping ([String : AnyObject]) -> Void) {
        guard let command = message["command"] as! String! else {return}
        
        // Run command and return data to watch
        switch (command) {
            case "reportLocation":
                PFGeoPoint.geoPointForCurrentLocation(inBackground: ({
                    (geoPoint: PFGeoPoint?, error: Error?) -> Void in
                    if error == nil {
                        // Get current date to make debug string
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "dd-MM-YY_HH:mm"
                        
                        // Get location and push to Parse
                        let newMonitoredLocation = PFObject(className: "hotspot")
                        newMonitoredLocation["location"] = geoPoint
                        newMonitoredLocation["tag"] = "free food!"
                        newMonitoredLocation["info"] = ["foodType": "", "foodDuration": "", "stillFood": ""]

                        newMonitoredLocation.saveInBackground(block: ({
                            (success: Bool, error: Error?) -> Void in
                            if (success) {
                                // add new location to monitored regions
                                let newRegionLat = (newMonitoredLocation["location"] as! PFGeoPoint).latitude
                                let newRegionLong = (newMonitoredLocation["location"] as! PFGeoPoint).longitude
                                let newRegionId = newMonitoredLocation.objectId!
                                MyPretracker.sharedManager.addLocation(distanceFromTarget, latitude: newRegionLat, longitude: newRegionLong,
                                                                       radius: geofenceRadius, id: newRegionId,
                                                                       expandRadius: 0, locationType: "exploit", hasBeacon: false)
                                
                                // Add new region to user defaults
                                var monitoredHotspotDictionary = self.appUserDefaults?.dictionary(forKey: savedHotspotsRegionKey) ?? Dictionary()
                                
                                // Add data to user defaults
                                var unwrappedEntry = [String : AnyObject]()
                                unwrappedEntry["latitude"] = newRegionLat as AnyObject
                                unwrappedEntry["longitude"] = newRegionLong as AnyObject
                                unwrappedEntry["id"] = newMonitoredLocation.objectId as AnyObject
                                unwrappedEntry["tag"] = newMonitoredLocation["tag"] as AnyObject
                                let info : [String : AnyObject]? = newMonitoredLocation["info"] as? [String : AnyObject]
                                unwrappedEntry["info"] = info as AnyObject
                                
                                monitoredHotspotDictionary[newMonitoredLocation.objectId!] = unwrappedEntry
                                self.appUserDefaults?.set(monitoredHotspotDictionary, forKey: savedHotspotsRegionKey)
                                self.appUserDefaults?.synchronize()
                                
                                // return information to apple watch
                                replyHandler(["response": unwrappedEntry as AnyObject])
                            }
                        }))
                    }
                }))
                break
            case "pushToParse":
                // Get dictionary from Watch app
                guard let watchDict = message["value"] as! [String : AnyObject]? else {return}
                let currentHotspotId = watchDict["id"] as! String
                
                // Get current hotspot from stored hotspots
                var monitoredHotspotDictionary = self.appUserDefaults?.dictionary(forKey: savedHotspotsRegionKey) ?? Dictionary()
                var currentHotspot = monitoredHotspotDictionary[currentHotspotId] as! Dictionary<String, AnyObject>
                
                currentHotspot["info"] = watchDict["info"]
                monitoredHotspotDictionary[currentHotspotId] = currentHotspot
                self.appUserDefaults?.set(monitoredHotspotDictionary, forKey: savedHotspotsRegionKey)
                self.appUserDefaults?.synchronize()
                
                // Push data to parse
                let query = PFQuery(className: "hotspot")
                query.getObjectInBackground(withId: currentHotspotId, block: ({
                    (hotspot: PFObject?, error: Error?) -> Void in
                    if error != nil {
                        print("Error in pushing data to Parse: \(String(describing: error))")
                        
                        // return information to apple watch
                        replyHandler(["response": false as AnyObject])
                    } else if let hotspot = hotspot {
                        hotspot["info"] = watchDict["info"]
                        hotspot.saveInBackground()
                        
                        print("Pushing data to parse")
                        print(hotspot)
                        
                        // return information to apple watch
                        replyHandler(["response": true as AnyObject])
                    }
                }))
                break
            case "notificationOccured":
                // Get location id from Watch app
                guard let locationID = message["value"] as! String? else {return}
                
                // Get current hotspot from stored hotspots
                var monitoredHotspotDictionary = self.appUserDefaults?.dictionary(forKey: savedHotspotsRegionKey) ?? Dictionary()
                let currentHotspot = monitoredHotspotDictionary[locationID] as! Dictionary<String, AnyObject>
                
                // return information to apple watch
                replyHandler(["response": currentHotspot as AnyObject])
                break
            default:
                break
        }
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
