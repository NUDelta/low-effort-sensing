//
//  NotificationCreator.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 5/26/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import Foundation

class NotificationCreator {
    let tag: String
    let currentInfo: [String : String]
    
    init(scenario: String, hotspotInfo: [String : String]) {
        self.tag = scenario
        self.currentInfo = hotspotInfo
    }
    
    func createNotificationForTag() -> [String : String] {
        switch tag {
        case "food":
            return createNotificationForFood()
        case "queue":
            return createNotificationForQueue()
        case "space":
            return createNotificationForSpace()
        case "surprising":
            return createNotificationForSurprising()
        default:
            return ["notificationCategory": "", "message": ""]
        }
    }
    
    func createNotificationForFood() -> [String : String] {
        var output = ["notificationCategory": "", "message": ""]
        
        if currentInfo["isfood"] == "yes" {
            // ask for food type
            if currentInfo["foodtype"] == "" {
                output["notificationCategory"] = "food_foodtype"
                output["message"] = "Someone reported food here. What is it?"
            } else {
                // ask for how much food is left
                if currentInfo["howmuchfood"] == "" {
                    if currentInfo["foodtype"] != "other" &&  currentInfo["foodtype"] != "" {
                        output["notificationCategory"] = "food_howmuchfood"
                        output["message"] = "There are \(currentInfo["foodtype"]!) here. How much is left?"
                    } else {
                        output["notificationCategory"] = "food_howmuchfood"
                        output["message"] = "There is some food here. How much is left?"
                    }
                } else {
                    // ask for price
                    if currentInfo["freeorsold"] == "" {
                        if currentInfo["foodtype"] != "other" &&  currentInfo["foodtype"] != "" {
                            output["notificationCategory"] = "food_freeorsold"
                            output["message"] = "There are \(currentInfo["foodtype"]!) here and \(currentInfo["howmuchfood"]!) of it left. Is it free or being sold?"
                        } else {
                            output["notificationCategory"] = "food_freeorsold"
                            output["message"] = "There is some food here and there is \(currentInfo["howmuchfood"]!) of it left. Is it free or being sold?"
                        }
                    } else if currentInfo["freeorsold"] == "free" {
                        // if free, ask if for specific student group only
                        if currentInfo["forstudentgroup"] == "" {
                            if currentInfo["foodtype"] != "other" &&  currentInfo["foodtype"] != "" {
                                output["notificationCategory"] = "food_forstudentgroup"
                                output["message"] = "There are free \(currentInfo["foodtype"]!) here and there is \(currentInfo["howmuchfood"]!) of it left. Is it for a specific student group only?"
                            } else {
                                output["notificationCategory"] = "food_forstudentgroup"
                                output["message"] = "There is free food here and there is \(currentInfo["howmuchfood"]!) of it left. Is it for a specific student group only?"
                            }
                        } else if currentInfo["forstudentgroup"] == "yes" {
                            // if free and for specific group, data filled --> ask if still food
                            if currentInfo["foodtype"] != "other" &&  currentInfo["foodtype"] != "" {
                                output["notificationCategory"] = "food_isfood"
                                output["message"] = "There are free \(currentInfo["foodtype"]!) here and there is \(currentInfo["howmuchfood"]!) of it left, but it looks like it's for a specific student group. If you check it out, can you tell us if there is still food there?"
                            } else {
                                output["notificationCategory"] = "food_isfood"
                                output["message"] = "There is free food here and there is \(currentInfo["howmuchfood"]!) of it left, but it looks like it's for a specific student group. If you check it out, can you tell us if there is still food there?"
                            }
                        }  else if currentInfo["forstudentgroup"] == "no" {
                            // if free and not for specific group, data filled --> ask if still food
                            if currentInfo["foodtype"] != "other" &&  currentInfo["foodtype"] != "" {
                                output["notificationCategory"] = "food_isfood"
                                output["message"] = "There are free \(currentInfo["foodtype"]!) here and there is \(currentInfo["howmuchfood"]!) of it left. Looks like it's for everyone. If you check it out, can you tell us if there is still food there?"
                            } else {
                                output["notificationCategory"] = "food_isfood"
                                output["message"] = "There is free food here and there is \(currentInfo["howmuchfood"]!) of it left. Looks like it's for everyone. If you check it out, can you tell us if there is still food there?"
                            }
                        }
                    } else if currentInfo["freeorsold"] == "sold" {
                        // if sold, ask for cost
                        if currentInfo["cost"] == "" {
                            if currentInfo["foodtype"] != "other" &&  currentInfo["foodtype"] != "" {
                                output["notificationCategory"] = "food_cost"
                                output["message"] = "There are \(currentInfo["foodtype"]!) being sold here and there is \(currentInfo["howmuchfood"]!) of it left. About how much do they cost?"
                            } else {
                                output["notificationCategory"] = "food_cost"
                                output["message"] = "There is food being sold here and there is \(currentInfo["howmuchfood"]!) of it left. About how much does it cost?"
                            }
                        } else {
                            // if sold and know cost, ask for reason
                            if currentInfo["sellingreason"] == "" {
                                if currentInfo["foodtype"] != "other" &&  currentInfo["foodtype"] != "" {
                                    output["notificationCategory"] = "food_sellingreason"
                                    output["message"] = "There are \(currentInfo["foodtype"]!) being sold here for \(currentInfo["cost"]!) and there is \(currentInfo["howmuchfood"]!) of it left. Why is it being sold?"
                                } else {
                                    output["notificationCategory"] = "food_sellingreason"
                                    output["message"] = "There is food being sold here for \(currentInfo["cost"]!) and there is \(currentInfo["howmuchfood"]!) of it left. Why is it being sold?"
                                }
                            } else {
                                // if sold, know cost, and know reason data filled --> ask if still food
                                if currentInfo["foodtype"] != "other" &&  currentInfo["foodtype"] != "" {
                                    if currentInfo["sellingreason"] != "other" {
                                        output["notificationCategory"] = "food_isfood"
                                        output["message"] = "There are \(currentInfo["foodtype"]!) being sold here for \(currentInfo["cost"]!) to support \(currentInfo["sellingreason"]!) and there is \(currentInfo["howmuchfood"]!) of it left. If you check it out, can you tell us if there is still food there?"
                                    } else {
                                        output["notificationCategory"] = "food_isfood"
                                        output["message"] = "There are \(currentInfo["foodtype"]!) being sold here for \(currentInfo["cost"]!) and there is \(currentInfo["howmuchfood"]!) of it left. If you check it out, can you tell us if there is still food there?"
                                    }
                                } else {
                                    if currentInfo["sellingreason"] != "other" {
                                        output["notificationCategory"] = "food_isfood"
                                        output["message"] = "There is food being sold here for \(currentInfo["cost"]!) to support \(currentInfo["sellingreason"]!) and there is \(currentInfo["howmuchfood"]!) of it left. If you check it out, can you tell us if there is still food there?"
                                    } else {
                                        output["notificationCategory"] = "food_isfood"
                                        output["message"] = "There is food being sold here for \(currentInfo["cost"]!) and there is \(currentInfo["howmuchfood"]!) of it left. If you check it out, can you tell us if there is still food there?"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            output["notificationCategory"] = "food_isfood"
            output["message"] = "Someone reported food here. Is it still there?"
        }
        
        return output
    }
    
    func createNotificationForQueue() -> [String : String] {
        var output = ["notificationCategory": "", "message": ""]
        return output
    }
    
    func createNotificationForSpace() -> [String : String] {
        var output = ["notificationCategory": "", "message": ""]
        return output
    }
    
    func createNotificationForSurprising() -> [String : String] {
        var output = ["notificationCategory": "", "message": ""]
        return output
    }
}