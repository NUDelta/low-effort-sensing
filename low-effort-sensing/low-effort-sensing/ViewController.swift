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
import WatchConnectivity

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    // MARK: Properities
    @IBOutlet weak var locationDebugLabel: UILabel!
    
    let locationManager = CLLocationManager()
    let geofenceRadius = 50.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // location manager
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        // clear all current monitored regions
        stopMonitoringAllRegions()
        
        // pull geolocations from parse and begin monitoring regions
        beginMonitoringParseRegions()
    }
    
    func stopMonitoringAllRegions() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoringForRegion(region)
        }
        print(self.locationManager.monitoredRegions)
    }
    
    func beginMonitoringParseRegions() {
        let query = PFQuery(className: "hotspot")
        
        query.findObjectsInBackgroundWithBlock {
            (foundObjs: [PFObject]?, error: NSError?) -> Void in
            if error == nil {
                if let foundObjs = foundObjs {
                    for object in foundObjs {
                        let curr_geopoint = object["location"] as! PFGeoPoint
                        let curr_lat = curr_geopoint.latitude
                        let curr_long = curr_geopoint.longitude
                        let curr_region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: curr_lat, longitude: curr_long),
                            radius: self.geofenceRadius, identifier: object.objectId!)
                        self.locationManager.startMonitoringForRegion(curr_region)
                    }
                    print(self.locationManager.monitoredRegions)
                }
            } else {
                print(error)
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        var currLocation : CLLocation? = nil
        
        currLocation = manager.location
        print(currLocation?.coordinate)
    }
    
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print(region)
    }
    
    func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        print("Monitoring failed for region with identifier: \(region?.identifier)")
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Location Manager failed with the following error: \(error)")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func pushLocation() {
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
                newMonitoredLocation["debug"] = "tester_" + dateString
                newMonitoredLocation.saveInBackgroundWithBlock {
                    (success: Bool, error: NSError?) -> Void in
                    if (success) {
                        // add new location to monitored regions
                        let new_region_lat = newMonitoredLocation["location"].latitude
                        let new_region_long = newMonitoredLocation["location"].longitude
                        let new_region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: new_region_lat, longitude: new_region_long),
                            radius: self.geofenceRadius, identifier: newMonitoredLocation.objectId!)
                        self.locationManager.startMonitoringForRegion(new_region)
                        
                        // notify user data has been pushed
                        print("Pushing data to Parse")
                        let alertController = UIAlertController(title: "New Location Marked", message: "Location marked for tracking and uploaded to Parse!", preferredStyle: .Alert)
                        let okAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                            return true
                        }
                        alertController.addAction(okAction)
                        self.presentViewController(alertController, animated: true) {
                            return true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Actions
    @IBAction func sendNewLocationToParse(sender: AnyObject) {
        pushLocation()
    }
}
