//
//  NotificationCreator.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 5/26/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import Foundation

class NotificationCreator {
    let currentHotspot: [String : AnyObject]
    let tag: String
    let currentInfo: [String : String]
    
    var locationCommonName: String
    
    init(scenario: String, hotspotInfo: [String : String], currentHotspot: [String : AnyObject]) {
        self.tag = scenario
        self.currentInfo = hotspotInfo
        self.currentHotspot = currentHotspot
        
        self.locationCommonName = ""
        if let currentHotspotLocationCommonName = currentHotspot["locationCommonName"] as? String {
           self.locationCommonName = currentHotspotLocationCommonName
        }
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
        case "guestevent":
            return createNotificationForGuestEvent()
        case "dtrdonut":
            return createNotificationForDtrDonut()
        case "windowdrawing":
            return createNotificationForWindowDrawing()
        default:
            return ["notificationCategory": "", "message": ""]
        }
    }
    
    func createNotificationForFood() -> [String : String] {
        var output = ["notificationCategory": "", "message": ""]
        
        // generate notification
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
        
        // generate location phrase
        var locationPhrase = ""
        if self.locationCommonName == "" {
            locationPhrase = "here"
        } else {
            locationPhrase = "at \(self.locationCommonName)"
        }
        
        // generate notification
        // check if there is a line to track here
        if currentInfo["isline"] == "yes" {
            // ask for line time
            if currentInfo["linetime"] == "" {
                output["notificationCategory"] = "queue_linetime"
                output["message"] = "How long do you think it will take to get through the line \(locationPhrase)?"
            } else if currentInfo["linetime"] == "< 5 mins" || currentInfo["linetime"] == "5-10 mins" {
                // ask how many people if line is short
                if currentInfo["npeople"] == "" {
                    output["notificationCategory"] = "queue_npeople"
                    output["message"] = "The line \(locationPhrase) is short (\(currentInfo["linetime"]!)). About how many people are in line?"
                }
                else {
                    // ask if longer than normal
                    if currentInfo["islonger"] == "" {
                        output["notificationCategory"] = "queue_islonger"
                        output["message"] = "The line \(locationPhrase) is short and has about \(currentInfo["npeople"]!) people in it. If you come here regularly, is this longer than normal?"
                    } else if currentInfo["islonger"] == "yes" {
                        // ask if line is worth waiting in
                        if currentInfo["isworthwaiting"] == "" {
                            output["notificationCategory"] = "queue_isworthwaiting"
                            output["message"] = "The line \(locationPhrase) is longer than normal, but still short. Do you think it's worth waiting?"
                        } else if currentInfo["isworthwaiting"] == "yes" {
                            output["notificationCategory"] = "queue_isline"
                            output["message"] = "The line \(locationPhrase) is suppose to be longer than normal, but worth waiting for. Do you still see a line here?"
                        } else {
                            output["notificationCategory"] = "queue_isline"
                            output["message"] = "The line \(locationPhrase) is suppose to be longer than normal, but still short. Do you still see a line here?"
                        }
                    } else {
                        // ask if line is worth waiting in
                        if currentInfo["isworthwaiting"] == "" {
                            output["notificationCategory"] = "queue_isworthwaiting"
                            output["message"] = "The line \(locationPhrase) is short. Do you think it's worth waiting?"
                        } else if currentInfo["isworthwaiting"] == "yes" {
                            output["notificationCategory"] = "queue_isline"
                            output["message"] = "The line \(locationPhrase) is short, but worth waiting for. Do you still see a line here?"
                        } else {
                            output["notificationCategory"] = "queue_isline"
                            output["message"] = "The line \(locationPhrase) is short. Do you still see a line here?"
                        }
                    }
                }
            } else {
                // ask how many people if line is long
                if currentInfo["npeople"] == "" {
                    output["notificationCategory"] = "queue_npeople"
                    output["message"] = "The line \(locationPhrase) is long (\(currentInfo["linetime"]!)). About how many people are in line?"
                }
                else {
                    // ask if longer than normal
                    if currentInfo["islonger"] == "" {
                        output["notificationCategory"] = "queue_islonger"
                        output["message"] = "The line \(locationPhrase) is long and has about \(currentInfo["npeople"]!) people in it. If you come here regularly, is this longer than normal?"
                    } else if currentInfo["islonger"] == "yes" {
                        // ask if line is worth waiting in
                        if currentInfo["isworthwaiting"] == "" {
                            output["notificationCategory"] = "queue_isworthwaiting"
                            output["message"] = "The line \(locationPhrase) is longer than normal. Do you think it's worth waiting?"
                        } else if currentInfo["isworthwaiting"] == "yes" {
                            output["notificationCategory"] = "queue_isline"
                            output["message"] = "The line \(locationPhrase) is suppose to be longer than normal, but worth waiting for. Do you still see a line here?"
                        } else {
                            output["notificationCategory"] = "queue_isline"
                            output["message"] = "The line \(locationPhrase) is suppose to be longer than normal. Do you still see a line here?"
                        }
                    } else {
                        // ask if line is worth waiting in
                        if currentInfo["isworthwaiting"] == "" {
                            output["notificationCategory"] = "queue_isworthwaiting"
                            output["message"] = "The line \(locationPhrase) is long. Do you think it's worth waiting?"
                        } else if currentInfo["isworthwaiting"] == "yes" {
                            output["notificationCategory"] = "queue_isline"
                            output["message"] = "The line \(locationPhrase) is suppose to be long, but worth waiting for. Do you still see a line here?"
                        } else {
                            output["notificationCategory"] = "queue_isline"
                            output["message"] = "The line \(locationPhrase) is suppose to be long. Do you still see a line here?"
                        }
                    }
                }
                
            }
        } else {
            output["notificationCategory"] = "queue_isline"
            output["message"] = "Someone reported a line to track \(locationPhrase). Do you see one here?"
        }
        
        return output
    }
    
    func createNotificationForSpace() -> [String : String] {
        var output = ["notificationCategory": "", "message": ""]
        
        // generate location phrase
        var locationPhrase = ""
        if self.locationCommonName == "" {
            locationPhrase = "here"
        } else {
            locationPhrase = "at \(self.locationCommonName)"
        }
        
        // generate notification
        // check if valid space to track
        if currentInfo["isspace"] == "yes" {
            // check if there is seating available in the space
            if currentInfo["isavailable"]  == "yes"{
                // ask for seating type
                if currentInfo["seatingtype"] == "" {
                    output["notificationCategory"] = "space_seatingtype"
                    output["message"] = "There's space available \(locationPhrase). What kind of seating is available here currently?"
                } else {
                    // ask if seating near power
                    if currentInfo["seatingnearpower"] == "" {
                        output["notificationCategory"] = "space_seatingnearpower"
                        output["message"] = "There's a communal space \(locationPhrase) with \(currentInfo["seatingtype"]!) available. Are there any seats near power outlets?"
                    } else {
                        // ask about wifi connection
                        if currentInfo["iswifi"] == "" {
                            output["notificationCategory"] = "space_iswifi"
                            output["message"] = "There's a communal space \(locationPhrase) with \(currentInfo["seatingtype"]!) available. Does the place have wifi?"
                        } else {
                            // check for noise level
                            if currentInfo["loudness"] == "" {
                                output["notificationCategory"] = "space_loudness"
                                output["message"] = "There's a communal space \(locationPhrase) with \(currentInfo["seatingtype"]!) available. How loud is it here?"
                            } else if currentInfo["loudness"] == "loud" {
                                // check if space is still the same
                                output["notificationCategory"] = "space_isspace"
                                output["message"] = "There's a communal space \(locationPhrase) with \(currentInfo["seatingtype"]!) available, but it's on the louder side. Might not be a great place to work. Is it still like this?"
                            } else {
                                // check if space is still the same
                                if currentInfo["iswifi"] == "yes" {
                                    output["notificationCategory"] = "space_isspace"
                                    output["message"] = "There's a communal space \(locationPhrase) with \(currentInfo["seatingtype"]!) and WiFi available. It's quiet, so might be a good place to work! Is it still like this?"
                                }
                            }
                        }
                    }
                }
            } else if currentInfo["isavailable"] == "no" {
                // check if lots of people
                if currentInfo["manypeople"] == "" {
                    output["notificationCategory"] = "space_manypeople"
                    output["message"] = "There space here \(locationPhrase) seems to be very busy. Are there a lot of people there?"
                } else if currentInfo["manypeople"] == "yes" {
                    // check how loud the place is
                    if currentInfo["loudness"] == "" {
                        output["notificationCategory"] = "space_loudness"
                        output["message"] = "There seems to be a lot of people \(locationPhrase). How loud is it here?"
                    } else {
                        // check if event going on
                        if currentInfo["event"] == "" {
                            output["notificationCategory"] = "space_event"
                            output["message"] = "The space \(locationPhrase) seems to be busy. Is there an event going on here?"
                        } else if currentInfo["event"] == "no" {
                            // check is space is still the same
                            output["notificationCategory"] = "space_isspace"
                            output["message"] = "The space \(locationPhrase) seems to be busy with \(currentInfo["loudness"]!) noise level. Is it still like this?"
                        } else {
                            // check is space is still the same
                            output["notificationCategory"] = "space_isspace"
                            output["message"] = "The space \(locationPhrase) seems to be busy with an event (\(currentInfo["event"]!)) going on. Is it still like this?"
                        }
                    }
                } else {
                    // check how loud the place is
                    if currentInfo["loudness"] == "" {
                        output["notificationCategory"] = "space_loudness"
                        output["message"] = "The space here \(locationPhrase) seems to be busy. How loud is it here?"
                    } else {
                        // check if event going on
                        if currentInfo["event"] == "" {
                            output["notificationCategory"] = "space_event"
                            output["message"] = "The space \(locationPhrase) seems to be busy. Is there an event going on here?"
                        } else if currentInfo["event"] == "no" {
                            // check is space is still the same
                            output["notificationCategory"] = "space_isspace"
                            output["message"] = "The space \(locationPhrase) seems to be busy with \(currentInfo["loudness"]!) noise level. Is it still like this?"
                        } else {
                            // check is space is still the same
                            output["notificationCategory"] = "space_isspace"
                            output["message"] = "The space \(locationPhrase) seems to be busy with an event (\(currentInfo["event"]!)) going on. Is it still like this?"
                        }
                    }
                }
            } else {
                output["notificationCategory"] = "space_isavailable"
                output["message"] = "Someone reported a communal space to track \(locationPhrase). Is there seating or space available here?"
            }
        } else {
            output["notificationCategory"] = "space_isspace"
            output["message"] = "Someone reported a communal space to track \(locationPhrase). Do you see one here?"
        }
        return output
    }
    
    func createNotificationForSurprising() -> [String : String] {
        var output = ["notificationCategory": "", "message": ""]
        
        // generate notification
        // check what is happeneing at location
        if currentInfo["whatshappening"] == "" {
            output["notificationCategory"] = "surprising_whatshappening"
            output["message"] = "Someone said there was something unexpected happening here! Do you see anything unsusual?"
        } else if currentInfo["whatshappening"] == "celebrity" {
            // ask how celebrity got their fame
            if currentInfo["famefrom"] == "" {
                output["notificationCategory"] = "surprising_famefrom"
                output["message"] = "There's a celebrity here! If they are still there, do you know what they are famous for?"
            } else {
                if currentInfo["famefrom"] != "other" || currentInfo["famefrom"] != "I don't know" {
                    output["notificationCategory"] = "surprising_whatshappening"
                    output["message"] = "There was a celebrity who's famous for being a \(currentInfo["famefrom"]!) here! Is he/she still there?"
                } else {
                    output["notificationCategory"] = "surprising_whatshappening"
                    output["message"] = "There was a celebrity here! Is he/she still there?"
                }
            }
        } else if currentInfo["whatshappening"] == "emergency vehicles" {
            // ask what kind of emergency vehicles are here for
            if currentInfo["vehicles"] == "" {
                output["notificationCategory"] = "surprising_vehicles"
                output["message"] = "Someone said there were emergency vehicles here. If they are still there, what kind of vehicles do you see?"
            } else {
                output["notificationCategory"] = "surprising_whatshappening"
                output["message"] = "There were emergency vehicles (\(currentInfo["vehicles"]!)) here. Are they still there?"
            }
        } else if currentInfo["whatshappening"] == "lots of people" {
            // ask why there are so many people here
            if currentInfo["peopledoing"] == "" {
                output["notificationCategory"] = "surprising_peopledoing"
                output["message"] = "Someone said there was a large gathering of people here. If they are still there, any idea what they are there for?"
            } else {
                output["notificationCategory"] = "surprising_whatshappening"
                output["message"] = "There were a lot of people here for an event (\(currentInfo["peopledoing"]!)). Are they still there?"
            }
        }
        return output
    }
    
    func createNotificationForGuestEvent() -> [String : String] {
        var output = ["notificationCategory": "", "message": ""]
        
        // generate notification
        if currentInfo["eventkind"] == "" {
            output["notificationCategory"] = "guestevent_eventkind"
            output["message"] = "Someone reported a guest event going on here. Can you tell us what's happening?"
        } else {
            if currentInfo["host"] == "" {
                output["notificationCategory"] = "guestevent_host"
                output["message"] = "There's a guest event (\(currentInfo["eventkind"]!)) going on here. Can you tell us who's hosting it?"
            } else {
                if currentInfo["eventlength"] == "" {
                    output["notificationCategory"] = "guestevent_eventlength"
                    output["message"] = "A guest event (\(currentInfo["eventkind"]!)) hosted by a \(currentInfo["host"]!) is happening here. Do you know how much longer it will last?"
                } else {
                    if currentInfo["isfood"] == "" {
                        output["notificationCategory"] = "guestevent_isfood"
                        output["message"] = "A guest event (\(currentInfo["eventkind"]!)) hosted by a \(currentInfo["host"]!) is happening here. Do they have food?"
                    } else if currentInfo["isfood"] == "yes" {
                        if currentInfo["foodkind"] == "" {
                            output["notificationCategory"] = "guestevent_foodkind"
                            output["message"] = "There's a guest event going on here with food. What kind of food do they have?"
                        } else {
                            if currentInfo["foodleft"] == "" {
                                output["notificationCategory"] = "guestevent_foodleft"
                                output["message"] = "There's a guest event with food (\(currentInfo["foodkind"]!)) here! How much food is left?"
                            } else {
                                output["notificationCategory"] = "no question"
                                output["message"] = "A guest event (\(currentInfo["host"]!)) hosted by a \(currentInfo["host"]!) is happening here, and they have food (\(currentInfo["foodkind"]!))!"
                            }
                        }
                    } else {
                        output["notificationCategory"] = "no question"
                        output["message"] = "A guest event (\(currentInfo["host"]!)) hosted by a \(currentInfo["host"]!) is happening here. Check it out!"
                    }
                }
            }
        }
        
        return output
    }
    
    func createNotificationForDtrDonut() -> [String : String] {
        var output = ["notificationCategory": "", "message": ""]
        return output
    }
    
    func createNotificationForWindowDrawing() -> [String : String] {
        var output = ["notificationCategory": "", "message": ""]
        return output
    }
}
