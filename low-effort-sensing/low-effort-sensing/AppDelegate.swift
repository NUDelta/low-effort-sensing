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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var shortcutItem: UIApplicationShortcutItem?
    let locationManager = CLLocationManager()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Check active state for 3D Touch Home actions
        var performShortcutDelegate = true
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsShortcutItemKey] as? UIApplicationShortcutItem {
            
            print("Application launched via shortcut")
            self.shortcutItem = shortcutItem
            
            performShortcutDelegate = false
        }
        
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
        var monitoredHotspotDictionary = NSUserDefaults.init(suiteName: "group.hotspotDictionary")?.dictionaryForKey(savedHotspotsRegionKey) ?? [:]
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
}

