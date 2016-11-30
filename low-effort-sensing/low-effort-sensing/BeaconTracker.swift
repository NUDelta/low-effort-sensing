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
    var withinCurrentRegion: CLBeaconRegion?
    
    let appUserDefaults = UserDefaults(suiteName: appGroup)
    
    required public override init() {
        super.init()
        self.withinCurrentRegion = nil
        
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
    
    public func beaconManager(_ manager: Any, didEnter region: CLBeaconRegion) {
        self.withinCurrentRegion = region
        
        print("did enter beacon region")
        let notification = UILocalNotification()
        notification.alertBody = "Entered region: \(region.identifier)"
        UIApplication.shared.presentLocalNotificationNow(notification)
    }
    
    public func beaconManager(_ manager: Any, didExitRegion region: CLBeaconRegion) {
        print("Exited Region \(region.identifier)")
        
        if self.withinCurrentRegion == region {
            self.withinCurrentRegion = nil
        }
    }
    
    public func beaconManager(_ manager: Any, didDetermineState state: CLRegionState, for region: CLBeaconRegion) {
        switch state {
        case CLRegionState.unknown:
            print("Unknown beacon state")
        case CLRegionState.inside:
            print("inside region: \(region.identifier)")
        case CLRegionState.outside:
            print("outside region: \(region.identifier)")
        }
    }
    
    public func beaconManager(_ manager: Any, didFailWithError error: Error) {
        print(error)
    }
    
    public func beaconManager(_ manager: Any, monitoringDidFailFor region: CLBeaconRegion?, withError error: Error) {
        print(error)
    }
}
