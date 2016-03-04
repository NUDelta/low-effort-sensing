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
        watchSession.delegate = self
        watchSession.activateSession()
        
        watchSession.sendMessage(["command": "reportLocation", "value": ""],
            replyHandler: {replyDict in
                guard let responseDictionary = replyDict["response"] as! [String: AnyObject]? else {return}
                self.presentControllerWithName("getInfoController", context: responseDictionary)
            }, errorHandler: {error in
                print("Error in reporting location notification: \(error)")
            })
    }
    
    // handle notification
    override func handleActionWithIdentifier(identifier: String?, forLocalNotification localNotification: UILocalNotification) {
        switch(identifier!) {
            case "INVESTIGATE_EVENT_IDENTIFIER":
                let locationID = localNotification.userInfo!["id"] as! String
                watchSession.delegate = self
                watchSession.activateSession()
                
                watchSession.sendMessage(["command": "notificationOccured", "value": locationID],
                    replyHandler: {replyDict in
                        print(replyDict)
                        guard let responseDictionary = replyDict["response"] as! Dictionary<String, AnyObject>? else {return}
                        print(responseDictionary)
                        self.presentControllerWithName("getInfoController", context: responseDictionary)
                    }, errorHandler: {error in
                        print("Error in handling notification: \(error)")
                })
                break
            default:
                break
        }
    }
}
