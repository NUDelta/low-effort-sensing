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

let savedHotspotsRegionKey = "savedMonitoredHotspots" // for saving currently monitored locations to NSUserDefaults
let myHotspotsRegionKey = "savedMarkedHotspots" // for saving all hotspots user has marked before

// blank location info
let foodInfo = ["isfood": "", "foodtype": "", "howmuchfood": "",
                "freeorsold": "", "forstudentgroup": "", "cost": "", "sellingreason": ""]

let queueInfo = ["isline": "", "linetime": "", "islonger": "", "isworthwaiting": "", "npeople": ""]

let spaceInfo = ["isspace": "", "isavailable": "", "seatingtype": "", "seatingnearpower": "",
                 "iswifi": "", "manypeople": "", "loudness": "", "event": ""]

let surprisingInfo = ["whatshappening": "", "famefrom": "", "vehicles": "", "peopledoing": ""]

let guestEventInfo = ["eventkind": "", "host": "", "isfood": "", "foodkind": "", "foodleft": "", "eventlength": ""]

let windowDrawingInfo = ["objectright": "", "colorright": "", "valueright": "", "objectleft": "", "colorleft": "", "valueleft": ""]

let dtrDonutInfo = ["room": "", "boxdrawing": "", "boxcontent": "", "markercolor": "", "plain": "", "frosted": ""]

let appUserDefaults = UserDefaults(suiteName: appGroup)

class TodayViewController: UIViewController, NCWidgetProviding {
        
    @IBOutlet weak var foodButton: UIButton!
    @IBOutlet weak var queueButton: UIButton!
    @IBOutlet weak var spaceButton: UIButton!
//    @IBOutlet weak var surprisingButton: UIButton!
    
    @IBOutlet weak var submittedLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    
    var guestEventSelected: Bool = false
    var windowDrawingSelected: Bool = false
    var dtrDonutSelected: Bool = false
//    var surprisingSelected: Bool = false
    
    let brightGreenColor: UIColor = UIColor.init(red: 83.0 / 255.0, green: 215.0 / 255.0, blue: 105.0 / 255.0, alpha: 1.0)
    let defaultAlpha: CGFloat = 0.4
    
    var vendorId: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.extensionContext?.widgetLargestAvailableDisplayMode = NCWidgetDisplayMode.expanded
        
        // Do any additional setup after loading the view from its nib.
        if (Parse.isLocalDatastoreEnabled() == false) {
            Parse.enableLocalDatastore()
            Parse.enableDataSharing(withApplicationGroupIdentifier: appGroup,
                                                                  containingApplication: containingApplication)
            Parse.initialize(with: ParseClientConfiguration(block: { (configuration: ParseMutableClientConfiguration) -> Void in
                configuration.server = "https://dtr-les.herokuapp.com/parse/"
                configuration.applicationId = "PkngqKtJygU9WiQ1GXM9eC0a17tKmioKKmpWftYr"
                configuration.clientKey = "vsA30VpFQlGFKhhjYdrPttTvbcg1JxkbSSNeGCr7"
            }))
        }
        
        // Capture device's unique vendor id
        if let uuid = UIDevice.current.identifierForVendor?.uuidString {
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
        foodButton.titleLabel!.lineBreakMode = NSLineBreakMode.byClipping
        foodButton.titleLabel!.minimumScaleFactor = 0.5
        
        queueButton.titleLabel!.numberOfLines = 0
        queueButton.titleLabel!.adjustsFontSizeToFitWidth = true
        queueButton.titleLabel!.lineBreakMode = NSLineBreakMode.byClipping
        queueButton.titleLabel!.minimumScaleFactor = 0.5
        
        spaceButton.titleLabel!.numberOfLines = 0
        spaceButton.titleLabel!.adjustsFontSizeToFitWidth = true
        spaceButton.titleLabel!.lineBreakMode = NSLineBreakMode.byClipping
        spaceButton.titleLabel!.minimumScaleFactor = 0.5
        
//        surprisingButton.titleLabel!.numberOfLines = 0
//        surprisingButton.titleLabel!.adjustsFontSizeToFitWidth = true
//        surprisingButton.titleLabel!.lineBreakMode = NSLineBreakMode.byClipping
//        surprisingButton.titleLabel!.minimumScaleFactor = 0.5
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == NCWidgetDisplayMode.compact {
            self.preferredContentSize = CGSize(width: 0.0, height: 200.0)
        }
        else if activeDisplayMode == NCWidgetDisplayMode.expanded {
            self.preferredContentSize = CGSize(width: 0.0, height: 400.0)
        }
    }
    
    func widgetPerformUpdate(completionHandler: @escaping ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        completionHandler(NCUpdateResult.newData)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if guestEventSelected {
            pushDataToParse("guestevent")
            unmarkLocation("guestevent")
            submittedLabel.text = ""
        } else if windowDrawingSelected {
            pushDataToParse("windowdrawing")
            unmarkLocation("windowdrawing")
            submittedLabel.text = ""
        } else if dtrDonutSelected {
            pushDataToParse("dtrdonut")
            unmarkLocation("dtrdonut")
            submittedLabel.text = ""
        }
//        else if surprisingSelected {
//            pushDataToParse("surprising")
//            unmarkLocation("surprising")
//        }
    }
    
    @IBAction func markLocationForFood(_ sender: AnyObject) {
        // show user that button has been selected/deselected
        if !guestEventSelected {
            foodButton.alpha = 1
            foodButton.backgroundColor = brightGreenColor
            foodButton.setTitleColor(UIColor.white, for: UIControlState())
            submittedLabel.text = "Location will be marked for Guest Event tracking when you exit the notification center. \n\nClick Guest Event again to untrack or click another button to change the category"
            
            guestEventSelected = true
        } else {
            unmarkLocation("guestevent")
            submittedLabel.text = ""
        }
        
        // reset any other buttons selected
        if windowDrawingSelected {
            unmarkLocation("windowdrawing")
        } else if dtrDonutSelected {
            unmarkLocation("dtrdonut")
        }
//        else if surprisingSelected {
//            unmarkLocation("surprising")
//        }
    }
    
    @IBAction func markLocationForQueue(_ sender: AnyObject) {
        // show user that button has been selected/deselected
        if !windowDrawingSelected {
            queueButton.alpha = 1
            queueButton.backgroundColor = brightGreenColor
            queueButton.setTitleColor(UIColor.white, for: UIControlState())
            submittedLabel.text = "Location will be marked for Window Drawing tracking when you exit the notification center \n\nClick Window Drawing again to untrack or click another button to change the category"
            
            windowDrawingSelected = true
        } else {
            unmarkLocation("windowdrawing")
            submittedLabel.text = ""
        }
        
        // reset any other buttons selected
        if guestEventSelected {
            unmarkLocation("guestevent")
        } else if dtrDonutSelected {
            unmarkLocation("dtrdonut")
        }
//        else if surprisingSelected {
//            unmarkLocation("surprising")
//        }
    }
    
    @IBAction func markLocationForSpace(_ sender: AnyObject) {
        // show user that button has been selected/deselected
        if !dtrDonutSelected {
            spaceButton.alpha = 1
            spaceButton.backgroundColor = brightGreenColor
            spaceButton.setTitleColor(UIColor.white, for: UIControlState())
            submittedLabel.text = "Location will be marked for DTR Donut tracking when you exit the notification center \n\nClick DTR Donut again to untrack or click another button to change the category"
            
            dtrDonutSelected = true
        } else {
            unmarkLocation("dtrdonut")
            submittedLabel.text = ""
        }
        
        // reset any other buttons selected
        if guestEventSelected {
            unmarkLocation("guestevent")
        } else if windowDrawingSelected {
            unmarkLocation("windowdrawing")
        }
//        else if surprisingSelected {
//            unmarkLocation("surprising")
//        }
    }
    
//    @IBAction func markLocationForSurprisingThing(_ sender: AnyObject) {
//        // show user that button has been selected/deselected
//        if !surprisingSelected {
//            surprisingButton.alpha = 1
//            surprisingButton.backgroundColor = brightGreenColor
//            surprisingButton.setTitleColor(UIColor.white, for: UIControlState())
//            submittedLabel.text = "Location will be marked for Surprising Things tracking when you exit the notification center \n\nClick Surprising Things again to untrack or click another button to change the category"
//            
//            surprisingSelected = true
//        } else {
//            unmarkLocation("surprising")
//            submittedLabel.text = ""
//        }
//        
//        // reset any other buttons selected
//        if foodSelected {
//            unmarkLocation("food")
//        } else if queueSelected {
//            unmarkLocation("queue")
//        } else if spaceSelected {
//            unmarkLocation("space")
//        }
//    }
    
    func unmarkLocation(_ location: String) {
        if location == "guestevent" {
            foodButton.alpha = defaultAlpha
            foodButton.backgroundColor = UIColor.white
            foodButton.setTitleColor(UIColor.black, for: UIControlState())
            
            guestEventSelected = false
        } else if location == "windowdrawing" {
            queueButton.alpha = defaultAlpha
            queueButton.backgroundColor = UIColor.white
            queueButton.setTitleColor(UIColor.black, for: UIControlState())
            
            windowDrawingSelected = false
        } else if location == "dtrdonut" {
            spaceButton.alpha = defaultAlpha
            spaceButton.backgroundColor = UIColor.white
            spaceButton.setTitleColor(UIColor.black, for: UIControlState())
            
            dtrDonutSelected = false
        }
//        else if location == "surprising" {
//            surprisingButton.alpha = defaultAlpha
//            surprisingButton.backgroundColor = UIColor.white
//            surprisingButton.setTitleColor(UIColor.black, for: UIControlState())
//            
//            surprisingSelected = false
//        }
    }
    
    func pushDataToParse(_ tag: String) {
        PFGeoPoint.geoPointForCurrentLocation(inBackground: ({
            (geoPoint: PFGeoPoint?, error: Error?) -> Void in
            if error == nil {
                // get UTC timestamp and timezone of notification
                let epochTimestamp = Int(Date().timeIntervalSince1970)
                let gmtOffset = NSTimeZone.local.secondsFromGMT()
                
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
                
                if let currBeaconRegion = appUserDefaults?.object(forKey: "currentBeaconRegion") {
                    if currBeaconRegion as? String != nil {
                        newMonitoredLocation["beaconId"] = currBeaconRegion as? String
                    } else {
                        newMonitoredLocation["beaconId"] = ""
                    }
                } else {
                    newMonitoredLocation["beaconId"] = ""
                }

                // set info dict and saveTimeForQuestion based on tag
                switch tag {
                case "food":
                    newMonitoredLocation["info"] = foodInfo
                    newMonitoredLocation["saveTimeForQuestion"] = ["isfood": epochTimestamp, "foodtype": epochTimestamp, "howmuchfood": epochTimestamp, "freeorsold": epochTimestamp,
                                                                   "forstudentgroup": epochTimestamp, "cost": epochTimestamp, "sellingreason": epochTimestamp]
                    break
                case "queue":
                    newMonitoredLocation["info"] = queueInfo
                    newMonitoredLocation["saveTimeForQuestion"] = ["isline": epochTimestamp, "linetime": epochTimestamp, "islonger": epochTimestamp, "isworthwaiting": epochTimestamp, "npeople": epochTimestamp]
                    break
                case "space":
                    newMonitoredLocation["info"] = spaceInfo
                    newMonitoredLocation["saveTimeForQuestion"] = ["isspace": epochTimestamp, "isavailable": epochTimestamp, "seatingtype": epochTimestamp, "seatingnearpower": epochTimestamp,
                                                                   "iswifi": epochTimestamp, "manypeople": epochTimestamp, "loudness": epochTimestamp, "event": epochTimestamp]
                    break
                case "surprising":
                    newMonitoredLocation["info"] = surprisingInfo
                    newMonitoredLocation["saveTimeForQuestion"] = ["whatshappening": epochTimestamp, "famefrom": epochTimestamp, "vehicles": epochTimestamp, "peopledoing": epochTimestamp]
                    break
                case "guestevent":
                    newMonitoredLocation["info"] = guestEventInfo
                    newMonitoredLocation["saveTimeForQuestion"] = ["eventkind": epochTimestamp, "host": epochTimestamp, "isfood": epochTimestamp, "foodkind": epochTimestamp, "foodleft": epochTimestamp, "eventlength": epochTimestamp]
                    break
                case "windowdrawing":
                    newMonitoredLocation["info"] = windowDrawingInfo
                    newMonitoredLocation["saveTimeForQuestion"] = ["objectright": epochTimestamp, "colorright": epochTimestamp, "valueright": epochTimestamp, "objectleft": epochTimestamp, "colorleft": epochTimestamp, "valueleft": epochTimestamp]
                    break
                case "dtrdonut":
                    newMonitoredLocation["info"] = dtrDonutInfo
                    newMonitoredLocation["saveTimeForQuestion"] = ["room": epochTimestamp, "boxdrawing": epochTimestamp, "boxcontent": epochTimestamp, "markercolor": epochTimestamp, "plain": epochTimestamp, "frosted": epochTimestamp]
                    break
                default:
                    break
                }
                
                // push to parse
                newMonitoredLocation.saveInBackground(block: ({ (success: Bool, error: Error?) -> Void in
                    if (!success) {
                        print("Error in saving new location to Parse: \(error). Trying Again.")
                        self.pushDataToParse(tag)
                    }
                }))
            }
        }))
    }
}
