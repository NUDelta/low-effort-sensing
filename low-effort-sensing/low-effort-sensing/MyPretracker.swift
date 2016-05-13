//
//  MyPretracker.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 4/29/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import Foundation
import Pretracking
import CoreLocation
import Parse

class MyPretracker: Tracker {
    var currentHeading: Double = 0.0
    var currentElevation: Double = 0.0
    var currentAccuracy: Double = 0.0
    
    let appUserDefaults = NSUserDefaults.init(suiteName: "group.com.delta.les")
    var window: UIWindow?
    
    static let mySharedManager = MyPretracker()
    
    override func notifyPeople(region: CLRegion, locationWhenNotified: CLLocation) {
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
    
    override func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations.last!
        let debugDictionary = notifyIfWithinDistance(lastLocation)

        // save course, elevation, and current accuracy information
        currentHeading = lastLocation.course as Double
        currentElevation = lastLocation.altitude as Double
        currentAccuracy = manager.desiredAccuracy
        
        // push debug log to parse
        // TODO: disable in final release
        saveLocationWithMetaData(debugDictionary)
    }
    
    func saveLocationWithMetaData(data: [String: [String: String]]) {
        let date = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDateString = dateFormatter.stringFromDate(date)
        
        if let unwrappedCurrentLocationParameters = data["currentLocationParameters"] {
            let newLog = PFObject(className: "pretracking_debug")
            newLog["vendor_id"] = vendorId
            newLog["timestamp_epoch"] = Int(Int64(NSDate().timeIntervalSince1970 * 1000))
            newLog["timestamp_string"] = currentDateString
            newLog["console_string"] = "Location has updated"
            
            newLog["location"] = unwrappedCurrentLocationParameters["location"]
            newLog["audio_playing"] = unwrappedCurrentLocationParameters["audioPlaying"]
            newLog["tracking_accuracy"] = unwrappedCurrentLocationParameters["locationManagerAccuracy"]
            newLog["horizontal_accuracy"] = unwrappedCurrentLocationParameters["horizontalAccuracy"]
            newLog["heading"] = unwrappedCurrentLocationParameters["heading"]
            newLog["elevation"] = unwrappedCurrentLocationParameters["elevation"]
            
            if let unwrappedDistanceToRegions =  data["distanceToRegions"] {
                newLog["distance_to_regions"] = String(unwrappedDistanceToRegions)
                
                if unwrappedDistanceToRegions.count > 0 {
                    newLog.saveInBackground()
                }
            }
        }
    }
}