//
//  TodayViewController.swift
//  LES Widget
//
//  Created by Kapil Garg on 5/10/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import UIKit
import NotificationCenter
import Parse

class TodayViewController: UIViewController, NCWidgetProviding {
        
    @IBOutlet weak var foodButton: UIButton!
    @IBOutlet weak var queueButton: UIButton!
    @IBOutlet weak var spaceButton: UIButton!
    @IBOutlet weak var infrastructureButton: UIButton!
    @IBOutlet weak var submittedLabel: UILabel!
    
    var vendorId: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view from its nib.
        if (Parse.isLocalDatastoreEnabled() == false) {
            Parse.enableLocalDatastore()
            Parse.enableDataSharingWithApplicationGroupIdentifier("group.com.delta.les",
                                                                  containingApplication: "edu.northwestern.delta.les.widget")
            Parse.setApplicationId("PkngqKtJygU9WiQ1GXM9eC0a17tKmioKKmpWftYr",
                                   clientKey: "vsA30VpFQlGFKhhjYdrPttTvbcg1JxkbSSNeGCr7")
        }
        
        // Capture device's unique vendor id
        if let uuid = UIDevice.currentDevice().identifierForVendor?.UUIDString {
            vendorId = uuid
        }
        
        // Set label to be empty until user submits data
        submittedLabel.text = ""
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        completionHandler(NCUpdateResult.NewData)
    }
    
    @IBAction func markLocationForFood(sender: AnyObject) {
        foodButton.backgroundColor = UIColor.greenColor()
        submittedLabel.text = "Location marked for food tracking"
        
        // send data to parse
        pushDataToParse("food")
        
        // reset color after short delay
        let seconds = 2.0
        let delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        
        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
            self.foodButton.backgroundColor = UIColor.whiteColor()
            self.submittedLabel.text = ""
        })
    }
    
    @IBAction func markLocationForQueue(sender: AnyObject) {
        queueButton.backgroundColor = UIColor.greenColor()
        submittedLabel.text = "Location marked for queue tracking"
        
        // send data to parse
        pushDataToParse("queue")
        
        // reset color after short delay
        let seconds = 2.0
        let delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        
        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
            self.queueButton.backgroundColor = UIColor.whiteColor()
            self.submittedLabel.text = ""
        })
    }
    
    @IBAction func markLocationForSpace(sender: AnyObject) {
        spaceButton.backgroundColor = UIColor.greenColor()
        submittedLabel.text = "Location marked for space tracking"
        
        // send data to parse
        pushDataToParse("space")
        
        // reset color after short delay
        let seconds = 2.0
        let delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        
        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
            self.spaceButton.backgroundColor = UIColor.whiteColor()
            self.submittedLabel.text = ""
        })
    }
    
    @IBAction func markLocationForInfrastructure(sender: AnyObject) {
        infrastructureButton.backgroundColor = UIColor.greenColor()
        submittedLabel.text = "Location marked for city infrastructure"
        
        // send data to parse
        pushDataToParse("infrastructure")
        
        // reset color after short delay
        let seconds = 2.0
        let delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        
        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
            self.infrastructureButton.backgroundColor = UIColor.whiteColor()
            self.submittedLabel.text = ""
        })
    }
    
    func pushDataToParse(tag: String) {
        PFGeoPoint.geoPointForCurrentLocationInBackground {
            (geoPoint: PFGeoPoint?, error: NSError?) -> Void in
            if error == nil {
                // Get current date to make debug string
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "dd-MM-YY_HH:mm"
                let dateString = dateFormatter.stringFromDate(NSDate())
                
                // Get location and push to Parse
                let newMonitoredLocation = PFObject(className: "hotspot")
                newMonitoredLocation["vendorId"] = self.vendorId
                newMonitoredLocation["location"] = geoPoint
                newMonitoredLocation["tag"] = tag
                newMonitoredLocation["debug"] = "tester_" + dateString
                newMonitoredLocation["info"] = ["foodType": "", "foodDuration": "", "stillFood": ""]
                
                newMonitoredLocation.saveInBackgroundWithBlock {
                    (success: Bool, error: NSError?) -> Void in
                    if (success) {
                       // do nothing if succeds
                    }
                }
            }
        }
    }
}
