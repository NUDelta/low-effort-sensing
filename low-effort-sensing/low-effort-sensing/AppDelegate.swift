//
//  AppDelegate.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 1/24/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import UIKit
import Parse
import Bolts
import CoreLocation
import WatchConnectivity

let geofenceRadius = 50.0
let savedHotspotsRegionKey = "savedMonitoredHotspots" // for saving the fetched locations to NSUserDefaults

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    let watchSession = WCSession.defaultSession()
    var shortcutItem: UIApplicationShortcutItem?
    let locationManager = CLLocationManager()
    
    let appUserDefaults = NSUserDefaults(suiteName: "group.com.delta.low-effort-sensing")

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Check active state for 3D Touch Home actions
        var performShortcutDelegate = true
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsShortcutItemKey] as? UIApplicationShortcutItem {
            
            print("Application launched via shortcut")
            self.shortcutItem = shortcutItem
            
            performShortcutDelegate = false
        }
        
        // Initalize WatchSession
        watchSession.delegate = self
        watchSession.activateSession()
        
        // Initialize Parse.
        Parse.setApplicationId("PkngqKtJygU9WiQ1GXM9eC0a17tKmioKKmpWftYr",
            clientKey: "vsA30VpFQlGFKhhjYdrPttTvbcg1JxkbSSNeGCr7")
        
        // location manager
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        // setup local notifications
        var categories = Set<UIUserNotificationCategory>()
        
        let investigateHotspotAction = UIMutableUserNotificationAction()
        investigateHotspotAction.title = NSLocalizedString("Investigate", comment: "investigate event")
        investigateHotspotAction.identifier = "INVESTIGATE_EVENT_IDENTIFIER"
        investigateHotspotAction.activationMode = UIUserNotificationActivationMode.Foreground
        investigateHotspotAction.authenticationRequired = false
        
        let investigateCategory = UIMutableUserNotificationCategory()
        investigateCategory.setActions([investigateHotspotAction], forContext: UIUserNotificationActionContext.Default)
        investigateCategory.identifier = "INVESTIGATE_CATEGORY"
        
        categories.insert(investigateCategory)
        
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Sound, .Alert, .Badge], categories: categories))
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        
        return performShortcutDelegate
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("Application did become active")
        
        guard let shortcut = shortcutItem else { return }
        print("- Shortcut property has been set")
        handleShortcut(shortcut)
        self.shortcutItem = nil
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func presentNotificationForEnteredRegion(region: CLRegion!) {
        // Get NSUserDefaults
        var monitoredHotspotDictionary = NSUserDefaults.init(suiteName: "group.com.delta.low-effort-sensing")?.dictionaryForKey(savedHotspotsRegionKey) ?? [:]
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
    
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion {
            presentNotificationForEnteredRegion(region)
        }
    }
    
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region is CLCircularRegion {
            print("User exited monitored region \(region.identifier)")
        }
    }
    
    // Contextual notification handler
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification,
        completionHandler: () -> Void) {
            if (notification.category == "INVESTIGATE_CATEGORY") {
                let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let adderVC : InformationAdderView = mainStoryboard.instantiateViewControllerWithIdentifier("InformationAdderController") as! InformationAdderView
                let notificationUserInfo = notification.userInfo as? Dictionary<String, AnyObject>
                adderVC.setCurrentHotspotIdFromView(notificationUserInfo!["id"] as! String)
                
                let rootViewController = self.window!.rootViewController
                rootViewController?.presentViewController(adderVC, animated: true, completion: nil)
            }
            
        completionHandler()
    }
    
    // 3D Touch shortcut handler
    // TO DO: use the contextual notification code above to ensure no weird errors with views existing affect transitioning
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        completionHandler(handleShortcut(shortcutItem))
    }
    
    func handleShortcut( shortcutItem:UIApplicationShortcutItem ) -> Bool {
        print("Handling shortcut")
        
        var succeeded = false
        if(shortcutItem.type == "com.delta.low-effort-sensing.mark-location") {
            print("- Handling \(shortcutItem.type)")
            
            let mainVC = self.window!.rootViewController as! ViewController
            mainVC.performSegueWithIdentifier("addDetailsForLocation", sender: self)
            
            succeeded = true
        }
        
        return succeeded
    }
    
    // WatchSession communication handler
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        guard let command = message["command"] as! String! else {return}
        
        // Run command and return data to watch
        switch (command) {
            case "reportLocation":
                PFGeoPoint.geoPointForCurrentLocationInBackground {
                    (geoPoint: PFGeoPoint?, error: NSError?) -> Void in
                    if error == nil {
                        // Get current date to make debug string
                        let dateFormatter = NSDateFormatter()
                        dateFormatter.dateFormat = "dd-MM-YY_HH:mm"
                        let dateString = dateFormatter.stringFromDate(NSDate())
                        
                        // Get location and push to Parse
                        let newMonitoredLocation = PFObject(className: "hotspot")
                        newMonitoredLocation["location"] = geoPoint
                        newMonitoredLocation["tag"] = "free food!"
                        newMonitoredLocation["debug"] = "tester_" + dateString
                        newMonitoredLocation["info"] = ["foodType": "", "foodDuration": "", "stillFood": ""]
                        
                        newMonitoredLocation.saveInBackgroundWithBlock {
                            (success: Bool, error: NSError?) -> Void in
                            if (success) {
                                // add new location to monitored regions
                                let newRegionLat = newMonitoredLocation["location"].latitude
                                let newRegionLong = newMonitoredLocation["location"].longitude
                                let newRegion = CLCircularRegion(center: CLLocationCoordinate2D(latitude: newRegionLat, longitude: newRegionLong),
                                    radius: geofenceRadius, identifier: newMonitoredLocation.objectId!)
                                self.locationManager.startMonitoringForRegion(newRegion)
                                
                                // Add new region to user defaults
                                var monitoredHotspotDictionary = self.appUserDefaults?.dictionaryForKey(savedHotspotsRegionKey) ?? Dictionary()
                                
                                // Add data to user defaults
                                var unwrappedEntry = [String : AnyObject]()
                                unwrappedEntry["latitude"] = newRegionLat
                                unwrappedEntry["longitude"] = newRegionLong
                                unwrappedEntry["id"] = newMonitoredLocation.objectId
                                unwrappedEntry["tag"] = newMonitoredLocation["tag"]
                                let info : Dictionary<String, AnyObject>? = newMonitoredLocation["info"] as? Dictionary<String, AnyObject>
                                unwrappedEntry["info"] = info
                                
                                monitoredHotspotDictionary[newMonitoredLocation.objectId!] = unwrappedEntry
                                self.appUserDefaults?.setObject(monitoredHotspotDictionary, forKey: savedHotspotsRegionKey)
                                self.appUserDefaults?.synchronize()
                                
                                // return information to apple watch
                                replyHandler(["response": unwrappedEntry])
                            }
                        }
                    }
                }
                break
            case "pushToParse":
                // Get dictionary from Watch app
                guard let watchDict = message["value"] as! [String : AnyObject]? else {return}
                let currentHotspotId = watchDict["id"] as! String
                
                // Get current hotspot from stored hotspots
                var monitoredHotspotDictionary = self.appUserDefaults?.dictionaryForKey(savedHotspotsRegionKey) ?? Dictionary()
                var currentHotspot = monitoredHotspotDictionary[currentHotspotId] as! Dictionary<String, AnyObject>
                
                currentHotspot["info"] = watchDict["info"]
                monitoredHotspotDictionary[currentHotspotId] = currentHotspot
                self.appUserDefaults?.setObject(monitoredHotspotDictionary, forKey: savedHotspotsRegionKey)
                self.appUserDefaults?.synchronize()
                
                // Push data to parse
                let query = PFQuery(className:"hotspot")
                query.getObjectInBackgroundWithId(currentHotspotId) {
                    (hotspot: PFObject?, error: NSError?) -> Void in
                    if error != nil {
                        print(error)
                        
                        // return information to apple watch
                        replyHandler(["response": false])
                    } else if let hotspot = hotspot {
                        hotspot["info"] = watchDict["info"]
                        hotspot.saveInBackground()
                        
                        print("Pushing data to parse")
                        print(hotspot)
                        
                        // return information to apple watch
                        replyHandler(["response": true])
                    }
                }
                break
            default:
                break
        }
    }
}

