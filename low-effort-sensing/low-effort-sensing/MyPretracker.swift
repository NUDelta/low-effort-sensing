//
//  MyPretracker.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 4/29/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import Foundation
import Pretracking

class MyPretracker: Tracker {
    static let mySharedManager = MyPretracker()
    
    override func notifyPeople() {
        print("overriding defauly notify")
    }
    
}