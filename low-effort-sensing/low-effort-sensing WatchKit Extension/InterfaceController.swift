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
    @available(watchOSApplicationExtension 2.2, *)
    internal func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?){
    }
    
    // MARK: Class Variables
    
    // session for communicating with iphone
    let watchSession = WCSession.default()
    
    // MARK: Class Functions
    override func awake(withContext context: AnyObject?) {
        super.awake(withContext: context)
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
        watchSession.activate()
        print(watchSession.isReachable)
        
        watchSession.sendMessage(["command": "reportLocation", "value": ""],
            replyHandler: { replyDict in
                guard let responseDictionary = replyDict["response"] as! [String: AnyObject]? else {return}
                self.presentController(withName: "getInfoController", context: responseDictionary)
            }, errorHandler: { error in
                print("Error in reporting location notification: \(error)")
            })
    }
    
    // handle notification
    override func handleAction(withIdentifier identifier: String?, for localNotification: UILocalNotification) {
        let watchSession = WCSession.default()
        watchSession.delegate = self
        watchSession.activate()
        print(watchSession.isReachable)
        
        switch(identifier!) {
            case "INVESTIGATE_EVENT_IDENTIFIER":
                let locationID = localNotification.userInfo!["id"] as! String
                
                watchSession.sendMessage(["command": "notificationOccured", "value": locationID],
                    replyHandler: { replyDict in
                        guard let responseDictionary = replyDict["response"] as! Dictionary<String, AnyObject>? else {return}
                        self.presentController(withName: "getInfoController", context: responseDictionary)
                    }, errorHandler: { error in
                        print("Error in handling notification: \(error)")
                })
                break
            default:
                break
        }
    }
    
    @available(watchOSApplicationExtension 2.2, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: NSError?) {
        
    }
}
