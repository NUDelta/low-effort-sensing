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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
