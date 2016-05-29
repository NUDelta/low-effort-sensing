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

// App Group for Sharing Data (MUST BE CHANGED DEPENDING ON BUILD)
//let appGroup = "group.com.delta.les-debug" // for debug builds
 let appGroup = "group.com.delta.les"       // for enterprise distribution builds

// Containing Application for Parse (MUST BE CHANGED DEPENDING ON BUILD
//let containingApplication = "edu.northwestern.delta.les-debug.widget" // for debug builds
let containingApplication = "edu.northwestern.delta.les.widget"       // for enterprise distribution builds

// blank location info
let foodInfo = ["isfood": "", "foodtype": "", "howmuchfood": "",
                "freeorsold": "", "forstudentgroup": "", "cost": "", "sellingreason": ""]

let queueInfo = ["isline": "", "linetime": "", "islonger": "", "isworthwaiting": "", "npeople": ""]

let spaceInfo = ["isspace": "", "isavailable": "", "seatingtype": "", "seatingnearpower": "",
                 "iswifi": "", "manypeople": "", "loudness": "", "event": ""]

let surprisingInfo = ["whatshappening": "", "famefrom": "", "vehicles": "", "peopledoing": ""]

class TodayViewController: UIViewController, NCWidgetProviding {
        
    @IBOutlet weak var foodButton: UIButton!
    @IBOutlet weak var queueButton: UIButton!
    @IBOutlet weak var spaceButton: UIButton!
    @IBOutlet weak var surprisingButton: UIButton!
    
    @IBOutlet weak var submittedLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    
    var foodSelected: Bool = false
    var queueSelected: Bool = false
    var spaceSelected: Bool = false
    var surprisingSelected: Bool = false
    
    let brightGreenColor: UIColor = UIColor.init(red: 83.0 / 255.0, green: 215.0 / 255.0, blue: 105.0 / 255.0, alpha: 1.0)
    let defaultAlpha: CGFloat = 0.4
    
    var vendorId: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view from its nib.
        if (Parse.isLocalDatastoreEnabled() == false) {
            Parse.enableLocalDatastore()
            Parse.enableDataSharingWithApplicationGroupIdentifier(appGroup,
                                                                  containingApplication: containingApplication)
            Parse.setApplicationId("PkngqKtJygU9WiQ1GXM9eC0a17tKmioKKmpWftYr",
                                   clientKey: "vsA30VpFQlGFKhhjYdrPttTvbcg1JxkbSSNeGCr7")
        }
        
        // Capture device's unique vendor id
        if let uuid = UIDevice.currentDevice().identifierForVendor?.UUIDString {
            vendorId = uuid
        }
        
        // Set label to be empty until user submits data
        submittedLabel.text = ""
        
        // dyanmic font sizing for labels
        submittedLabel.adjustsFontSizeToFitWidth = true
        infoLabel.adjustsFontSizeToFitWidth = true
        
        // dyanmic font sizing for buttons
        foodButton.titleLabel!.numberOfLines = 0
        foodButton.titleLabel!.adjustsFontSizeToFitWidth = true
        foodButton.titleLabel!.lineBreakMode = NSLineBreakMode.ByClipping
        foodButton.titleLabel!.minimumScaleFactor = 0.5
        
        queueButton.titleLabel!.numberOfLines = 0
        queueButton.titleLabel!.adjustsFontSizeToFitWidth = true
        queueButton.titleLabel!.lineBreakMode = NSLineBreakMode.ByClipping
        queueButton.titleLabel!.minimumScaleFactor = 0.5
        
        spaceButton.titleLabel!.numberOfLines = 0
        spaceButton.titleLabel!.adjustsFontSizeToFitWidth = true
        spaceButton.titleLabel!.lineBreakMode = NSLineBreakMode.ByClipping
        spaceButton.titleLabel!.minimumScaleFactor = 0.5
        
        surprisingButton.titleLabel!.numberOfLines = 0
        surprisingButton.titleLabel!.adjustsFontSizeToFitWidth = true
        surprisingButton.titleLabel!.lineBreakMode = NSLineBreakMode.ByClipping
        surprisingButton.titleLabel!.minimumScaleFactor = 0.5
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
    
    override func viewWillDisappear(animated: Bool) {
        if foodSelected {
            pushDataToParse("food")
            unmarkLocation("food")
            submittedLabel.text = ""
        } else if queueSelected {
            pushDataToParse("queue")
            unmarkLocation("queue")
            submittedLabel.text = ""
        } else if spaceSelected {
            pushDataToParse("space")
            unmarkLocation("space")
            submittedLabel.text = ""
        } else if surprisingSelected {
            pushDataToParse("surprising")
            unmarkLocation("surprising")
        }
    }
    
    @IBAction func markLocationForFood(sender: AnyObject) {
        // show user that button has been selected/deselected
        if !foodSelected {
            foodButton.alpha = 1
            foodButton.backgroundColor = brightGreenColor
            foodButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            submittedLabel.text = "Location will be marked for Food tracking when you exit the notification center. \n\nClick Food again to untrack or click another button to change the category"
            
            foodSelected = true
        } else {
            unmarkLocation("food")
            submittedLabel.text = ""
        }
        
        // reset any other buttons selected
        if queueSelected {
            unmarkLocation("queue")
        } else if spaceSelected {
            unmarkLocation("space")
        } else if surprisingSelected {
            unmarkLocation("surprising")
        }
    }
    
    @IBAction func markLocationForQueue(sender: AnyObject) {
        // show user that button has been selected/deselected
        if !queueSelected {
            queueButton.alpha = 1
            queueButton.backgroundColor = brightGreenColor
            queueButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            submittedLabel.text = "Location will be marked for Queue tracking when you exit the notification center \n\nClick Queue again to untrack or click another button to change the category"
            
            queueSelected = true
        } else {
            unmarkLocation("queue")
            submittedLabel.text = ""
        }
        
        // reset any other buttons selected
        if foodSelected {
            unmarkLocation("food")
        } else if spaceSelected {
            unmarkLocation("space")
        } else if surprisingSelected {
            unmarkLocation("surprising")
        }
    }
    
    @IBAction func markLocationForSpace(sender: AnyObject) {
        // show user that button has been selected/deselected
        if !spaceSelected {
            spaceButton.alpha = 1
            spaceButton.backgroundColor = brightGreenColor
            spaceButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            submittedLabel.text = "Location will be marked for Space tracking when you exit the notification center \n\nClick Space again to untrack or click another button to change the category"
            
            spaceSelected = true
        } else {
            unmarkLocation("space")
            submittedLabel.text = ""
        }
        
        // reset any other buttons selected
        if foodSelected {
            unmarkLocation("food")
        } else if queueSelected {
            unmarkLocation("queue")
        } else if surprisingSelected {
            unmarkLocation("surprising")
        }
    }
    
    @IBAction func markLocationForSurprisingThing(sender: AnyObject) {
        // show user that button has been selected/deselected
        if !surprisingSelected {
            surprisingButton.alpha = 1
            surprisingButton.backgroundColor = brightGreenColor
            surprisingButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            submittedLabel.text = "Location will be marked for Surprising Things tracking when you exit the notification center \n\nClick Surprising Things again to untrack or click another button to change the category"
            
            surprisingSelected = true
            print(surprisingSelected)
        } else {
            unmarkLocation("surprising")
            submittedLabel.text = ""
        }
        
        // reset any other buttons selected
        if foodSelected {
            unmarkLocation("food")
        } else if queueSelected {
            unmarkLocation("queue")
        } else if spaceSelected {
            unmarkLocation("space")
        }
    }
    
    func unmarkLocation(location: String) {
        if location == "food" {
            foodButton.alpha = defaultAlpha
            foodButton.backgroundColor = UIColor.whiteColor()
            foodButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
            
            foodSelected = false
        } else if location == "queue" {
            queueButton.alpha = defaultAlpha
            queueButton.backgroundColor = UIColor.whiteColor()
            queueButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
            
            queueSelected = false
        } else if location == "space" {
            spaceButton.alpha = defaultAlpha
            spaceButton.backgroundColor = UIColor.whiteColor()
            spaceButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
            
            spaceSelected = false
        }  else if location == "surprising" {
            surprisingButton.alpha = defaultAlpha
            surprisingButton.backgroundColor = UIColor.whiteColor()
            surprisingButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
            
            surprisingSelected = false
        }
    }
    
    func pushDataToParse(tag: String) {
        PFGeoPoint.geoPointForCurrentLocationInBackground {
            (geoPoint: PFGeoPoint?, error: NSError?) -> Void in
            if error == nil {
                // get UTC timestamp and timezone of notification
                let epochTimestamp = Int(NSDate().timeIntervalSince1970)
                let gmtOffset = NSTimeZone.localTimeZone().secondsFromGMT
                
                // Get location and push to Parse
                let newMonitoredLocation = PFObject(className: "hotspot")
                newMonitoredLocation["vendorId"] = self.vendorId
                newMonitoredLocation["location"] = geoPoint
                newMonitoredLocation["tag"] = tag
                newMonitoredLocation["archived"] = false
                newMonitoredLocation["timestampCreated"] = epochTimestamp
                newMonitoredLocation["gmtOffset"] = gmtOffset
                newMonitoredLocation["timestampLastUpdate"] = epochTimestamp
                newMonitoredLocation["submissionMethod"] = "today_widget"
                newMonitoredLocation["locationCommonName"] = ""
                
                
                // set info dict based on tag
                switch tag {
                    case "food":
                        newMonitoredLocation["info"] = foodInfo
                        break
                    case "queue":
                        newMonitoredLocation["info"] = queueInfo
                        break
                    case "space":
                        newMonitoredLocation["info"] = spaceInfo
                        break
                    case "surprising":
                        newMonitoredLocation["info"] = surprisingInfo
                        break
                    default:
                        break
                }
                
                // push to parse
                newMonitoredLocation.saveInBackground()
            }
        }
    }
}
