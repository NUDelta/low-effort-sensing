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

let savedHotspotsRegionKey = "savedMonitoredHotspots" // for saving the fetched locations to NSUserDefaults

class InterfaceController: WKInterfaceController, WCSessionDelegate, CLLocationManagerDelegate {

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
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
    }
}
