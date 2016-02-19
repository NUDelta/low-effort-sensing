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
        let query = PFQuery(className: "TestObject")
        
        query.findObjectsInBackgroundWithBlock {
            (foundObjs: [PFObject]?, error: NSError?) -> Void in
            if error == nil {
                if let foundObjs = foundObjs {
                    for object in foundObjs {
                        let curr_geopoint = object["regionLoc"] as! PFGeoPoint
                        let curr_lat = curr_geopoint.latitude
                        let curr_long = curr_geopoint.longitude
                        
                        let curr_region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: curr_lat, longitude: curr_long),
                            radius: 200, identifier: object["foo"] as! String)
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
                let newMonitoredLocation = PFObject(className: "TestObject")
                newMonitoredLocation["regionLoc"] = geoPoint
                newMonitoredLocation["foo"] = "tester_" + dateString
                newMonitoredLocation.saveInBackgroundWithBlock {
                    (success: Bool, error: NSError?) -> Void in
                    if (success) {
                        print("Pushing data to Parse")
                        self.locationDebugLabel.text = "Data pushed to parse!"
                        
                        // Reset text after delay
                        let seconds = 3.0
                        let delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
                        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                        
                        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                            self.locationDebugLabel.text = "Click above to set location"
                        })
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
