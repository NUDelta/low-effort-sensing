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

class ViewController: UIViewController {
    
    // MARK: Class Variables
    @IBOutlet weak var locationDebugLabel: UILabel!
    
    let appUserDefaults = NSUserDefaults.init(suiteName: appGroup)
    
    // MARK: Class Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
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
                            MyPretracker.sharedManager.addLocation(nil, latitude: newRegionLat, longitude: newRegionLong, radius: nil, name: newRegionId)
                            
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
        var monitoredHotspotDictionary = NSUserDefaults.init(suiteName: appGroup)?.dictionaryForKey(savedHotspotsRegionKey) ?? [:]
        
        // Get first region in monitored regions to use
        if  monitoredHotspotDictionary.keys.count > 0 {

            let currentRegion = monitoredHotspotDictionary["aCt8nf7vHW"] as! [String : AnyObject]
            print(currentRegion)
            let newNotification = NotificationCreator(scenario: currentRegion["tag"] as! String, hotspotInfo: currentRegion["info"] as! [String : String], currentHotspot: currentRegion)
            let notificationContent = newNotification.createNotificationForTag()
            
            print(notificationContent)
            print("food_" + notificationContent["notificationCategory"]!)
            
            
            // Display notification after short time
            let notification = UILocalNotification()
            notification.alertBody = notificationContent["message"]
            notification.soundName = "Default"
            notification.category = notificationContent["notificationCategory"]
            notification.userInfo = currentRegion
            notification.fireDate = NSDate().dateByAddingTimeInterval(2)
            
            UIApplication.sharedApplication().scheduleLocalNotification(notification)
        }
    }
}
