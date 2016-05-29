//
//  AuthorizationViewController.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 5/22/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import Foundation

class AuthorizationViewController: UIViewController {
    @IBOutlet weak var authLabel: UILabel!
    
    let appUserDefaults = NSUserDefaults.init(suiteName: appGroup)
    
    // MARK: Class Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        
        self.authLabel.adjustsFontSizeToFitWidth = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "AuthSegue") {
            // request for notification authorization
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.registerForNotifications()
            
            // request location authorization
            MyPretracker.sharedManager.getAuthorizationForLocationManager()
        }
    }
}