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
    
    override func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations.last!
        notifyIfWithinDistance(lastLocation)
        
        // save course, elevation, and current accuracy information
        currentHeading = lastLocation.course as Double
        currentElevation = lastLocation.altitude as Double
        currentAccuracy = manager.desiredAccuracy
        
        // push location data to parse for tracking every minute
        // TODO: disable in final release
        saveLocationWithMetaData(lastLocation)
    }
    
    func saveLocationWithMetaData(location: CLLocation) {
        let newLocationSave = PFObject(className: "location_debug")
        newLocationSave["timestamp"] = Int(Int64(NSDate().timeIntervalSince1970 * 1000))
        newLocationSave["vendorId"] = vendorId
        newLocationSave["trackingAccuracy"] = currentAccuracy
        newLocationSave["location"] = PFGeoPoint.init(location: location)
        newLocationSave["heading"] = currentHeading
        newLocationSave["elevation"] = currentElevation
        
        newLocationSave.saveEventually()
    }
}