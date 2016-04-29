//
//  ViewController.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 1/24/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import UIKit
import Parse
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    // MARK: Class Variables
    @IBOutlet weak var locationDebugLabel: UILabel!
    
//    let locationManager = CLLocationManager()
    
    let appUserDefaults = NSUserDefaults.init(suiteName: "group.com.delta.low-effort-sensing")
    
    // MARK: Class Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // location manager
//        locationManager.delegate = self
//        locationManager.requestAlwaysAuthorization()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UI and Other Functions
    func answerShortcut() {
        self.performSegueWithIdentifier("addDetailsForLocation", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "addDetailsForLocation") {
            PFGeoPoint.geoPointForCurrentLocationInBackground {
                (geoPoint: PFGeoPoint?, error: NSError?) -> Void in
                if error == nil {
                    // Get current date to make debug string
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.dateFormat = "MM-dd-YY_HH:mm"
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
                            let newRegionId = newMonitoredLocation.objectId!
//                            let newRegion = CLCircularRegion(center: CLLocationCoordinate2D(latitude: newRegionLat, longitude: newRegionLong),
//                                radius: geofenceRadius, identifier: newMonitoredLocation.objectId!)
//                            self.locationManager.startMonitoringForRegion(newRegion)
                            MyPretracker.mySharedManager.addLocation(distanceFromTarget, latitude: newRegionLat, longitude: newRegionLong, radius: geofenceRadius, name: newRegionId)
                            
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
                            
                            // Transition to add detail view
                            let segueToAddDetail = segue.destinationViewController as! InformationAdderView;
                            segueToAddDetail.currentHotspotId = newMonitoredLocation.objectId!
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func debugSendNotification(sender: AnyObject) {
        print("Preparing notification")
        // Get NSUserDefaults
        var monitoredHotspotDictionary = NSUserDefaults.init(suiteName: "group.com.delta.low-effort-sensing")?.dictionaryForKey(savedHotspotsRegionKey) ?? [:]
        
        // Get first region in monitored regions to use
        let region = Array(monitoredHotspotDictionary.keys)[0]
        let currentRegion = monitoredHotspotDictionary[region]
        let message = region
        
        // Display notification after short time
        let notification = UILocalNotification()
        notification.alertBody = "You have entered region \(message)"
        notification.soundName = "Default"
        notification.category = "INVESTIGATE_CATEGORY"
        notification.userInfo = currentRegion as? Dictionary
        notification.fireDate = NSDate().dateByAddingTimeInterval(5)
        
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
}
