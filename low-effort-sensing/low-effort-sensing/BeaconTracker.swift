//
//  BeaconTracker.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 11/29/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import Foundation
import CoreLocation
import Parse

public class BeaconTracker: NSObject, ESTBeaconManagerDelegate {
    // tracker parameters and storage variables
    var beaconManager: ESTBeaconManager?
    let appUserDefaults = UserDefaults(suiteName: appGroup)
    var vendorId = ""
    
    required public override init() {
        super.init()
        
        if let uuid = UIDevice.current.identifierForVendor?.uuidString {
            self.vendorId = uuid
        }
        
        appUserDefaults?.set(nil, forKey: "currentBeaconRegion")
        
        self.beaconManager = ESTBeaconManager()
        guard let beaconManager = self.beaconManager else {
            return
        }
        
        beaconManager.delegate = self
    }
    
    public static let sharedBeaconManager = BeaconTracker()
    
    public func clearAllMonitoredRegions() {
        print("Monitored regions: \(beaconManager!.monitoredRegions)")
        for region in beaconManager!.monitoredRegions {
            if (region is CLBeaconRegion) {
                beaconManager!.stopMonitoring(for: region as! CLBeaconRegion)
            }
        }
    }
    
    public func getAuthorizationForLocationManager() {
        print("Requesting authorization for always-on location")
        if !(beaconManager?.isAuthorizedForMonitoring())! {
            self.beaconManager?.requestAlwaysAuthorization()
        }
    }
    
    public func initBeaconManager() {
        self.getAuthorizationForLocationManager()
    }
    
    public func beaconManager(_ manager: Any, didChange status: CLAuthorizationStatus) {
        print("Status changed")
        self.clearAllMonitoredRegions()
        self.beginMonitoringParseRegions()
    }
    
    // MARK: - Location Functions
    func beginMonitoringParseRegions() {
        print("getting tracked beacon regions")
        let query = PFQuery(className: "beacons")
        query.findObjectsInBackground(block: ({ (foundObjs: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let foundObjs = foundObjs {
                    for object in foundObjs {
                        // TODO: CHANGE IDENTIFIER TO OBJECT ID
                        let currentRegion = CLBeaconRegion(proximityUUID: UUID(uuidString: object["uuid"] as! String)!,
                                                           major: object["major"] as! UInt16,
                                                           minor: object["minor"] as! UInt16,
                                                           identifier: object.objectId! as String)
                        self.beaconManager?.startMonitoring(for: currentRegion)
                    }
                }
            } else {
                print("Error in querying regions from Parse: \(error). Trying again.")
                self.beginMonitoringParseRegions()
            }
        }))
    }
    
    public func notifyPeople(_ currentRegion: [String : AnyObject], regionId: String) {
            //        print("notify for region id \(region.identifier)")
            // Log notification to parse
            let epochTimestamp = Int(Date().timeIntervalSince1970)
            let gmtOffset = NSTimeZone.local.secondsFromGMT()
        
            // Log notification sent event to parse
            let newResponse = PFObject(className: "notificationSent")
            newResponse["vendorId"] = vendorId
            newResponse["hotspotId"] = currentRegion["id"] as! String
            newResponse["timestamp"] = epochTimestamp
            newResponse["gmtOffset"] = gmtOffset
            newResponse["notificationString"] = "Notified for beacon region \(regionId)"
            newResponse.saveInBackground()
            
            // Show alert if app active, else local notification
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
    
    public func beaconManager(_ manager: Any, didEnter region: CLBeaconRegion) {
        // set current beacon value
        appUserDefaults?.set(region.identifier, forKey: "currentBeaconRegion")
        
        // iterate through all monitored regions and find any that match the beaconId
        let monitoredHotspotDictionary = appUserDefaults?.dictionary(forKey: savedHotspotsRegionKey) as [String : AnyObject]? ?? [:]
        
        for (_, info) in monitoredHotspotDictionary {
            let parsedInfo = info as! [String : AnyObject]
            let beaconId = parsedInfo["beaconId"] as! String
            if beaconId == region.identifier {
                self.notifyPeople(parsedInfo, regionId: region.identifier)
            }
        }
        
//        let notification = UILocalNotification()
//        notification.alertBody = "Entered region: \(region.identifier)"
//        UIApplication.shared.presentLocalNotificationNow(notification)
    }
    
    public func beaconManager(_ manager: Any, didExitRegion region: CLBeaconRegion) {
        print("Exited Region \(region.identifier)")
        
        if let currBeaconRegion = appUserDefaults?.object(forKey: "currentBeaconRegion") {
            if currBeaconRegion as? String == region.identifier {
                appUserDefaults?.set(nil, forKey: "currentBeaconRegion")
            }
        }
    }
    
    public func beaconManager(_ manager: Any, didDetermineState state: CLRegionState, for region: CLBeaconRegion) {
        switch state {
        case CLRegionState.unknown:
            print("Unknown beacon state")
        case CLRegionState.inside:
            print("inside region: \(region.identifier)")
            appUserDefaults?.set(region.identifier, forKey: "currentBeaconRegion")
        case CLRegionState.outside:
            print("outside region: \(region.identifier)")
            if let currBeaconRegion = appUserDefaults?.object(forKey: "currentBeaconRegion") {
                if currBeaconRegion as? String == region.identifier {
                    appUserDefaults?.set(nil, forKey: "currentBeaconRegion")
                }
            }
        }
    }
    
    public func beaconManager(_ manager: Any, didFailWithError error: Error) {
        print(error)
    }
    
    public func beaconManager(_ manager: Any, monitoringDidFailFor region: CLBeaconRegion?, withError error: Error) {
        print(error)
    }
}
