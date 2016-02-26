//
//  InterfaceController.swift
//  low-effort-sensing WatchKit Extension
//
//  Created by Kapil Garg on 1/24/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController, WCSessionDelegate {
    
    // session for communicating with iphone
    let watchSession = WCSession.defaultSession()

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        watchSession.delegate = self
        watchSession.activateSession()
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func reportLocation() {
        watchSession.sendMessage(["command": "reportLocation"],
            replyHandler: {replyDict in
                guard let responseDictionary = replyDict["response"] as! [String: AnyObject]? else {return}
                self.presentControllerWithName("getInfoController", context: responseDictionary)
            }, errorHandler: {error in
                print("error")
            })
    }
    
    // handle notification
    override func handleActionWithIdentifier(identifier: String?, forLocalNotification localNotification: UILocalNotification) {
        print(localNotification)
        switch(identifier!) {
            case "INVESTIGATE_EVENT_IDENTIFIER":
                let locationID = localNotification.userInfo!["id"] as! String
                print(locationID)
                break
            default:
                break
        }
    }
}
