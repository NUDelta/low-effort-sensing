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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view from its nib.
        if (Parse.isLocalDatastoreEnabled() == false) {
            Parse.enableLocalDatastore()
            Parse.enableDataSharingWithApplicationGroupIdentifier("group.com.delta.low-effort-sensing",
                                                                  containingApplication: "com.delta.low-effort-sensing.LES-Widget")
            Parse.setApplicationId("PkngqKtJygU9WiQ1GXM9eC0a17tKmioKKmpWftYr",
                                   clientKey: "vsA30VpFQlGFKhhjYdrPttTvbcg1JxkbSSNeGCr7")
        }
        
        let query = PFQuery(className: "hotspot")
        
        query.findObjectsInBackgroundWithBlock {
            (foundObjs: [PFObject]?, error: NSError?) -> Void in
            if error == nil {
                if let foundObjs = foundObjs {
                    print(foundObjs.count)
                }
            } else {
                print("Error in querying regions from Parse: \(error). Trying again.")
            }
        }

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
    }
    
    @IBAction func markLocationForQueue(sender: AnyObject) {
    }
    
    @IBAction func markLocationForSpace(sender: AnyObject) {
    }
    
    @IBAction func markLocationForInfrastructure(sender: AnyObject) {
    }
}
