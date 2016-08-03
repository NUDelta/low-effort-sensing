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
    // MARK: Class Variables
    
    // session for communicating with iphone
    let watchSession = WCSession.defaultSession()
    
    // MARK: Class Functions
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
    
    // MARK: - UI and Notification Functions
    @IBAction func reportLocation() {
        print("reporting location")
        watchSession.delegate = self
        watchSession.activateSession()
        print(watchSession.reachable)
        
        watchSession.sendMessage(["command": "reportLocation", "value": ""],
            replyHandler: { replyDict in
                guard let responseDictionary = replyDict["response"] as! [String: AnyObject]? else {return}
                self.presentControllerWithName("getInfoController", context: responseDictionary)
            }, errorHandler: { error in
                print("Error in reporting location notification: \(error)")
            })
    }
    
    // handle notification
    override func handleActionWithIdentifier(identifier: String?, forLocalNotification localNotification: UILocalNotification) {
        let watchSession = WCSession.defaultSession()
        watchSession.delegate = self
        watchSession.activateSession()
        print(watchSession.reachable)
        
        switch(identifier!) {
            case "INVESTIGATE_EVENT_IDENTIFIER":
                let locationID = localNotification.userInfo!["id"] as! String
                
                watchSession.sendMessage(["command": "notificationOccured", "value": locationID],
                    replyHandler: { replyDict in
                        guard let responseDictionary = replyDict["response"] as! Dictionary<String, AnyObject>? else {return}
                        self.presentControllerWithName("getInfoController", context: responseDictionary)
                    }, errorHandler: { error in
                        print("Error in handling notification: \(error)")
                })
                break
            default:
                break
        }
    }
    
    @available(watchOSApplicationExtension 2.2, *)
    func session(session: WCSession, activationDidCompleteWithState activationState: WCSessionActivationState, error: NSError?) {
        
    }
}
