//
//  AppDelegate.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 1/24/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
// 
//  Images Used
//  Double Tap (icon, splash screen), Web Icon Set from thenounproject.com
//  Location (authorization page), Riccardo Avanzi from thenounproject.com
//  Notification (authorization page), Thomas Helbig from thenounproject.com

import UIKit
import Parse
import Bolts
import WatchConnectivity

let distanceFromTarget = 20.0
let geofenceRadius = 150.0
let savedHotspotsRegionKey = "savedMonitoredHotspots" // for saving currently monitored locations to NSUserDefaults
let myHotspotsRegionKey = "savedMarkedHotspots" // for saving all hotspots user has marked before
var vendorId: String = ""

// App Group for Sharing Data (MUST BE CHANGED DEPENDING ON BUILD)
let appGroup = "group.com.delta.les-debug" // for debug builds
// let appGroup = "group.com.delta.les"       // for enterprise distribution builds

// extension used to dismiss keyboard, from Esqarrouth http://stackoverflow.com/questions/24126678/close-ios-keyboard-by-touching-anywhere-using-swift
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
}

// question ordering
let foodQuestionOrdering = ["isfood", "foodtype", "howmuchfood",
                            "freeorsold", "forstudentgroup", "cost", "sellingreason"]

let queueQuestionOrdering = ["isline", "linetime", "islonger", "isworthwaiting", "npeople"]

let spaceQuestionOrdering = ["isspace", "isavailable", "seatingtype", "seating near power",
                             "iswifi", "manypeople", "loudness", "event"]

let surprisingQuestionOrdering = ["whatshappening", "famefrom", "vehicles", "peopledoing"]

// blank location info
let foodInfo = ["isfood": "", "foodtype": "", "howmuchfood": "",
                "freeorsold": "", "forstudentgroup": "", "cost": "", "sellingreason": ""]

let queueInfo = ["isline": "", "linetime": "", "islonger": "", "isworthwaiting": "", "npeople": ""]

let spaceInfo = ["isspace": "", "isavailable": "", "seatingtype": "", "seating near power": "",
                 "iswifi": "", "manypeople": "", "loudness": "", "event": ""]

let surprisingInfo = ["whatshappening": "", "famefrom": "", "vehicles": "", "peopledoing": ""]

// notification answers
let foodAnswers = ["isfood": ["yes", "no"],
                   "foodtype": ["no food here", "pizza slices", "buns", "pastries", "other"],
                   "howmuchfood": ["none", "very little", "some", "lots"],
                   "freeorsold": ["free", "sold"],
                   "forstudentgroup": ["yes", "no"],
                   "cost": ["< $2", "$2-3", "$3-4", "$5+"],
                   "sellingreason": ["fundraising", "charity", "other"]]

let queueAnswers = ["isline": ["yes", "no"],
                    "linetime": ["< 5 mins", "5-10 mins", "10-20 mins", "20+ mins"],
                    "islonger": ["yes", "no", "I don't come here regularly"],
                    "isworthwaiting": ["yes", "no"],
                    "npeople": ["< 5", "5-10", "10+"]]

let spaceAnswers = ["isspace": ["yes", "no"],
                    "isavailable": ["yes", "no"],
                    "seatingtype": ["small tables", "large tables", "couches/chairs"],
                    "seating near power": ["yes", "no"],
                    "iswifi": ["yes", "no"],
                    "manypeople": ["yes", "no"],
                    "loudness": ["loud", "light conversation", "quiet"],
                    "event": ["no", "sports", "music", "gathering", "other"]]

let surprisingAnswers = ["whatshappening": ["I don't see anything unusual", "celebrity", "emergency vehicles", "lots of people"],
                         "famefrom": ["no longer here", "musician", "actor/actress", "politician", "comedian", "other", "I don't know"],
                         "vehicles": ["no longer here", "just police", "police, firetrucks, and ambulances"],
                         "peopledoing": ["no longer here", "protest/riot", "student gathering for organization", "university or formal event", "other", "I don't know"]]


// key to question dictionary
let foodKeyToQuestion = ["isfood": "Is there food here?",
                         "foodtype": "What kind of food is here?",
                         "howmuchfood": "How much food is left?",
                         "freeorsold": "Is it free or sold?",
                         "forstudentgroup": "Is it for a student group?",
                         "cost": "How much does it cost?",
                         "sellingreason": "Why is it being sold?"]

let queueKeyToQuestion = ["isline": "Is there a line here?",
                          "linetime": "How much time do you think it would take to go through the line right now?",
                          "islonger": "If you come here regularly, is the line longer than normal?",
                          "isworthwaiting": "Is it worth waiting in line?",
                          "npeople": "How many people are in line right now?"]

let spaceKeyToQuestion = ["isspace": "Is there a communal space to track here?",
                          "isavailable": "Is there seating/space available?",
                          "seatingtype": "What kind of seating?",
                          "seating near power": "Is there seating near power outlets?",
                          "iswifi": "Is there Wifi?",
                          "manypeople": "Are there a lot of people here?",
                          "loudness": "How loud is the place?",
                          "event": "Is there an event, like a sports game on TV or live music, going on here?"]

let surprisingKeyToQuestion = ["whatshappening": "What’s happening here?",
                               "famefrom": "What are they known for?",
                               "vehicles": "What vehicles are there?",
                               "peopledoing": "What are they doing there?"]


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate {
    // MARK: Class Variables
    var window: UIWindow?
    let watchSession = WCSession.defaultSession()
    var shortcutItem: UIApplicationShortcutItem?
    
    let appUserDefaults = NSUserDefaults.init(suiteName: appGroup)
    var notificationCategories = Set<UIUserNotificationCategory>()
    
    // MARK: - AppDelegate Functions
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Check active state for 3D Touch Home actions
        var performShortcutDelegate = true
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsShortcutItemKey] as? UIApplicationShortcutItem {
            print("Application launched via shortcut")
            self.shortcutItem = shortcutItem
            
            performShortcutDelegate = false
        }
        
        // Capture device's unique vendor id
        if let uuid = UIDevice.currentDevice().identifierForVendor?.UUIDString {
            vendorId = uuid
        }
        
        // Initalize WatchSession
        watchSession.delegate = self
        watchSession.activateSession()
        
        // Initialize Parse.
        Parse.enableDataSharingWithApplicationGroupIdentifier(appGroup)
        Parse.setApplicationId("PkngqKtJygU9WiQ1GXM9eC0a17tKmioKKmpWftYr",
            clientKey: "vsA30VpFQlGFKhhjYdrPttTvbcg1JxkbSSNeGCr7")
        
        // location manager and setting up monitored locations
        MyPretracker.sharedManager.setupParameters(distanceFromTarget,
                                                     radius: geofenceRadius,
                                                     accuracy: kCLLocationAccuracyNearestTenMeters,
                                                     distanceFilter: nil)
        
        // setup local notifications
        let option1HotspotAction = UIMutableUserNotificationAction()
        option1HotspotAction.title = NSLocalizedString("Option 1", comment: "click for option 1")
        option1HotspotAction.identifier = "OPTION1_EVENT_IDENTIFIER"
        option1HotspotAction.activationMode = UIUserNotificationActivationMode.Background
        option1HotspotAction.authenticationRequired = false
        
        let option2HotspotAction = UIMutableUserNotificationAction()
        option2HotspotAction.title = NSLocalizedString("Option 2", comment: "click for option 2")
        option2HotspotAction.identifier = "OPTION2_EVENT_IDENTIFIER"
        option2HotspotAction.activationMode = UIUserNotificationActivationMode.Background
        option2HotspotAction.authenticationRequired = false
        
        let investigateCategory = UIMutableUserNotificationCategory()
        investigateCategory.setActions([option2HotspotAction, option1HotspotAction],
                                       forContext: UIUserNotificationActionContext.Default)
        investigateCategory.identifier = "INVESTIGATE_CATEGORY"
        
        notificationCategories.insert(investigateCategory)
        
        createFoodNotifications()
        
        // check if user has already opened app before, if not show welcome screen
        let launchedBefore = NSUserDefaults.standardUserDefaults().boolForKey("launchedBefore")
        if launchedBefore  {
            // register categories for notifications
            registerForNotifications()
            
            // open map view
            self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let homeViewController: HomeScreenViewController = mainStoryboard.instantiateViewControllerWithIdentifier("HomeScreenViewController") as! HomeScreenViewController
            
            self.window?.rootViewController = homeViewController
            self.window?.makeKeyAndVisible()
            
            NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: #selector(AppDelegate.sendNotification), userInfo: nil, repeats: false)
        }
        else {
            print("First launch, going to welcome screen")
            let userInfo: [String : String] = ["firstName": "",
                                               "lastName": "",
                                               "vendorId": vendorId,
                                               "firstPreference": "",
                                               "secondPreference": "",
                                               "thirdPreference": "",
                                               "fourthPreference": ""]
            
            self.appUserDefaults?.setObject(userInfo, forKey: "welcomeData")
            self.appUserDefaults?.synchronize()
        }
        
        // hide status bar on all pages
        application.statusBarHidden = true
        
        return performShortcutDelegate
    }
    
    func sendNotification() {
        print("Preparing notification")
        // Get NSUserDefaults
        var monitoredHotspotDictionary = NSUserDefaults.init(suiteName: appGroup)?.dictionaryForKey(savedHotspotsRegionKey) ?? [:]
        
        // Get first region in monitored regions to use
        if  monitoredHotspotDictionary.keys.count > 0 {
            let currentRegion = monitoredHotspotDictionary["hIQZFSju33"] as! [String : AnyObject]
            let newNotification = NotificationCreator(scenario: currentRegion["tag"] as! String, hotspotInfo: currentRegion["info"] as! [String : String], currentHotspot: currentRegion)
            let notificationContent = newNotification.createNotificationForTag()
            
            print(notificationContent)
            print("food_" + notificationContent["notificationCategory"]!)
            
            
            // Display notification after short time
            let notification = UILocalNotification()
            notification.alertBody = notificationContent["message"]
            notification.soundName = "Default"
            notification.category = notificationContent["notificationCategory"]
            notification.userInfo = currentRegion
            notification.fireDate = NSDate().dateByAddingTimeInterval(3)
            
            UIApplication.sharedApplication().scheduleLocalNotification(notification)
        }
    }
    

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        print("App will resign active")
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("App will enter background")
        
        // Log app going into background
        let date = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDateString = dateFormatter.stringFromDate(date)

        let newLog = PFObject(className: "pretracking_debug")
        newLog["vendor_id"] = vendorId
        newLog["timestamp_epoch"] = Int(date.timeIntervalSince1970)
        newLog["timestamp_string"] = currentDateString
        newLog["console_string"] = "App entering background"
        newLog.saveInBackground()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        print("App will enter foreground")
        
        // Log app going into foreground
        let date = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDateString = dateFormatter.stringFromDate(date)
        
        let newLog = PFObject(className: "pretracking_debug")
        newLog["vendor_id"] = vendorId
        newLog["timestamp_epoch"] = Int(date.timeIntervalSince1970)
        newLog["timestamp_string"] = currentDateString
        newLog["console_string"] = "App entering foreground"
        newLog.saveInBackground()

    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("Application did become active")
        
        guard let shortcut = shortcutItem else { return }
        print("- Shortcut property has been set")
        handleShortcut(shortcut)
        self.shortcutItem = nil
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("App will terminate")
        
        // Log app about to terminate
        let date = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDateString = dateFormatter.stringFromDate(date)
        
        let newLog = PFObject(className: "pretracking_debug")
        newLog["vendor_id"] = vendorId
        newLog["timestamp_epoch"] = Int(date.timeIntervalSince1970)
        newLog["timestamp_string"] = currentDateString
        newLog["console_string"] = "App about to terminate"
        do {
            try newLog.save()
        } catch _ {
            print("Error")
        }
    }
    
    func registerForNotifications() {
        print("Requesting authorization for local notifications")
        UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Sound, .Alert, .Badge], categories: notificationCategories))
        UIApplication.sharedApplication().cancelAllLocalNotifications()
    }
    
    // MARK: - Create Custom Notifications for each question
    func createFoodNotifications() {
        notificationCategories.insert(createNotificationCategory("yes", option2Title: "no", categoryIdentifier: "food_isfood", option2InForeground: false))
        notificationCategories.insert(createNotificationCategory("no food here", option2Title: "report food type", categoryIdentifier: "food_foodtype", option2InForeground: true))
        notificationCategories.insert(createNotificationCategory("none", option2Title: "report food amount", categoryIdentifier: "food_howmuchfood", option2InForeground: true))
        notificationCategories.insert(createNotificationCategory("free", option2Title: "sold", categoryIdentifier: "food_freeorsold", option2InForeground: false))
        notificationCategories.insert(createNotificationCategory("yes", option2Title: "no", categoryIdentifier: "food_forstudentgroup", option2InForeground: false))
        notificationCategories.insert(createNotificationCategory("< $2", option2Title: "other", categoryIdentifier: "food_cost", option2InForeground: true))
        notificationCategories.insert(createNotificationCategory("fundraising", option2Title: "other", categoryIdentifier: "food_sellingreason", option2InForeground: true))
    }
    
    func createNotificationCategory(option1Title: String, option2Title: String, categoryIdentifier: String, option2InForeground: Bool) -> UIMutableUserNotificationCategory {
        let option1HotspotAction = UIMutableUserNotificationAction()
        let option2HotspotAction = UIMutableUserNotificationAction()
        let notificationCategory = UIMutableUserNotificationCategory()
        
        option1HotspotAction.title = NSLocalizedString(option1Title, comment: "click for option 1")
        option1HotspotAction.identifier = "OPTION1_EVENT_IDENTIFIER"
        option1HotspotAction.activationMode = UIUserNotificationActivationMode.Background
        option1HotspotAction.authenticationRequired = false
        
        option2HotspotAction.title = NSLocalizedString(option2Title, comment: "click for option 2")
        option2HotspotAction.identifier = "OPTION2_EVENT_IDENTIFIER"
        if option2InForeground {
            option2HotspotAction.activationMode = UIUserNotificationActivationMode.Foreground
        } else {
            option2HotspotAction.activationMode = UIUserNotificationActivationMode.Background
        }
        option2HotspotAction.authenticationRequired = false
        
        notificationCategory.setActions([option2HotspotAction, option1HotspotAction], forContext: UIUserNotificationActionContext.Default)
        notificationCategory.identifier = categoryIdentifier
        
        return notificationCategory
    }
    
    //MARK: - Contextual Notification Handler
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void) {
        // get UTC timestamp and timezone of notification
        let epochTimestamp = Int(NSDate().timeIntervalSince1970)
        let gmtOffset = NSTimeZone.localTimeZone().secondsFromGMT
        
        // get scenario and question as separate components
        let notificationCategoryArr = notification.category?.componentsSeparatedByString("_")
        
        // Setup response object to push to parse
        var notificationId = ""
        if let unwrappedNotificationId = notification.userInfo!["id"] {
            notificationId = unwrappedNotificationId as! String
        }
        
        let newResponse = PFObject(className: "pingResponse")
        newResponse["vendorId"] = vendorId
        newResponse["hotspotId"] = notificationId
        newResponse["question"] = notificationCategoryArr![1]
        newResponse["response"] = ""
        newResponse["tag"] = notificationCategoryArr![0]
        newResponse["timestamp"] = epochTimestamp
        newResponse["gmtOffset"] = gmtOffset
        
        if (notificationCategoryArr![0] == "food") {
            // check for binary responses
            if ["isfood", "freeorsold", "forstudentgroup"].contains(notificationCategoryArr![1]) {
                newResponse["response"] = getResponseForCategoryAndIdentifier("food", category: notificationCategoryArr![1], identifier: identifier!)
            }
            // check if first answer of non-binary responses
            else if identifier == "OPTION1_EVENT_IDENTIFIER" {
                switch notificationCategoryArr![1] {
                case "foodtype":
                    newResponse["response"] = "no food here"
                case "howmuchfood":
                    newResponse["response"] = "none"
                case "cost":
                    newResponse["response"] = "< $2"
                case "sellingreason":
                    newResponse["response"] = "fundraising"
                default:
                    newResponse["response"] = ""
                }
            }
            // if option 2, launch app and show picker
            else {
                let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let otherResponseVC : RespondToOtherViewController = mainStoryboard.instantiateViewControllerWithIdentifier("RespondToOtherViewController") as! RespondToOtherViewController
                let notificationUserInfo = notification.userInfo as? [String : AnyObject]
                
                otherResponseVC.setCurrentVariables(notificationUserInfo!["id"] as! String, scenario: notificationCategoryArr![0], question: notificationCategoryArr![1], notification: notification.alertBody!)
                
                let rootViewController = self.window!.rootViewController
                rootViewController?.presentViewController(otherResponseVC, animated: true, completion: nil)
            }
        } else if (notificationCategoryArr![0] == "queue") {
            // TODO: Implement logic based on notification
        } else if (notificationCategoryArr![0] == "space") {
            // TODO: Implement logic based on notification
        } else if (notificationCategoryArr![0] == "surprising") {
            // TODO: Implement logic based on notification
        }
        
        // if response field is not blank, save to parse
        if newResponse["response"] as! String != "" {
            newResponse.saveInBackground()
        }
        completionHandler()
    }
    
    func getResponseForCategoryAndIdentifier(scenario: String, category: String, identifier: String) -> String {
        // get answer index for binary answers
        var index = 0
        if identifier == "OPTION1_EVENT_IDENTIFIER" {
            index = 0
        } else {
            index = 1
        }
        
        // find and return answer
        switch scenario {
            case "food":
                return foodAnswers[category]![index]
            case "queue":
                return queueAnswers[category]![index]
            case "space":
                return spaceAnswers[category]![index]
            case "surprising":
                return surprisingAnswers[category]![index]
            default:
                return ""
        }
    }
    
    // MARK: 3D Touch shortcut handler
    // TODO: use the contextual notification code above to ensure no weird errors with views existing affect transitioning
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        completionHandler(handleShortcut(shortcutItem))
    }
    
    func handleShortcut( shortcutItem:UIApplicationShortcutItem ) -> Bool {
        print("Handling \(shortcutItem.type)")
        
        PFGeoPoint.geoPointForCurrentLocationInBackground {
            (geoPoint: PFGeoPoint?, error: NSError?) -> Void in
            if error == nil {
                // create tag based on shortcut
                var tag = ""
                switch shortcutItem.type {
                    case "com.delta.low-effort-sensing.mark-food-location":
                        tag = "food"
                    case "com.delta.low-effort-sensing.mark-queue-location":
                        tag = "queue"
                    case "com.delta.low-effort-sensing.mark-space-location":
                        tag = "space"
                    case "com.delta.low-effort-sensing.mark-surprising-thing-location":
                        tag = "surprising"
                    default:
                        return
                }
                
                // get UTC timestamp and timezone of notification
                let epochTimestamp = Int(NSDate().timeIntervalSince1970)
                let gmtOffset = NSTimeZone.localTimeZone().secondsFromGMT
                
                // Get location and push to Parse
                let newMonitoredLocation = PFObject(className: "hotspot")
                newMonitoredLocation["vendorId"] = vendorId
                newMonitoredLocation["location"] = geoPoint
                newMonitoredLocation["tag"] = tag
                newMonitoredLocation["archived"] = false
                newMonitoredLocation["timestampCreated"] = epochTimestamp
                newMonitoredLocation["gmtOffset"] = gmtOffset
                newMonitoredLocation["timestampLastUpdate"] = epochTimestamp
                newMonitoredLocation["submissionMethod"] = "3d_touch"
                newMonitoredLocation["locationCommonName"] = ""
                
                // set info dict based on tag
                switch tag {
                case "food":
                    newMonitoredLocation["info"] = foodInfo
                    break
                case "queue":
                    newMonitoredLocation["info"] = queueInfo
                    break
                case "space":
                    newMonitoredLocation["info"] = spaceInfo
                    break
                case "surprising":
                    newMonitoredLocation["info"] = surprisingInfo
                    break
                default:
                    break
                }
                
                // push to parse
                newMonitoredLocation.saveInBackground()
                
                // Show alert confirming location saved
                var tagDescription = ""
                switch(tag) {
                case "food":
                    tagDescription = "Food"
                case "queue":
                    tagDescription = "Queue"
                case "space":
                    tagDescription = "Space"
                case "surprising":
                    tagDescription = "Surprising Things"
                default:
                    return
                }
                
                let title = "Location Marked for \(tagDescription) Tracking"
                let message = "Your current location has been marked for \(tagDescription) tracking. Check back later to see if someone has contributed information to it!"
                
                let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                
                self.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
            }
        }
        return true
    }
    
    // MARK: WatchSession communication handler
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        guard let command = message["command"] as! String! else {return}
        
        // Run command and return data to watch
        switch (command) {
            case "reportLocation":
                PFGeoPoint.geoPointForCurrentLocationInBackground {
                    (geoPoint: PFGeoPoint?, error: NSError?) -> Void in
                    if error == nil {
                        // Get current date to make debug string
                        let dateFormatter = NSDateFormatter()
                        dateFormatter.dateFormat = "dd-MM-YY_HH:mm"
                        let dateString = dateFormatter.stringFromDate(NSDate())
                        
                        // Get location and push to Parse
                        let newMonitoredLocation = PFObject(className: "hotspot")
                        newMonitoredLocation["location"] = geoPoint
                        newMonitoredLocation["tag"] = "free food!"
                        newMonitoredLocation["info"] = ["foodType": "", "foodDuration": "", "stillFood": ""]
                        
                        newMonitoredLocation.saveInBackgroundWithBlock {
                            (success: Bool, error: NSError?) -> Void in
                            if (success) {
                                // add new location to monitored regions
                                let newRegionLat = newMonitoredLocation["location"].latitude
                                let newRegionLong = newMonitoredLocation["location"].longitude
                                let newRegionId = newMonitoredLocation.objectId!
                                MyPretracker.sharedManager.addLocation(distanceFromTarget, latitude: newRegionLat, longitude: newRegionLong, radius: geofenceRadius, name: newRegionId)
                                
                                // Add new region to user defaults
                                var monitoredHotspotDictionary = self.appUserDefaults?.dictionaryForKey(savedHotspotsRegionKey) ?? Dictionary()
                                
                                // Add data to user defaults
                                var unwrappedEntry = [String : AnyObject]()
                                unwrappedEntry["latitude"] = newRegionLat
                                unwrappedEntry["longitude"] = newRegionLong
                                unwrappedEntry["id"] = newMonitoredLocation.objectId
                                unwrappedEntry["tag"] = newMonitoredLocation["tag"]
                                let info : Dictionary<String, AnyObject>? = newMonitoredLocation["info"] as? Dictionary<String, AnyObject>
                                unwrappedEntry["info"] = info
                                
                                monitoredHotspotDictionary[newMonitoredLocation.objectId!] = unwrappedEntry
                                self.appUserDefaults?.setObject(monitoredHotspotDictionary, forKey: savedHotspotsRegionKey)
                                self.appUserDefaults?.synchronize()
                                
                                // return information to apple watch
                                replyHandler(["response": unwrappedEntry])
                            }
                        }
                    }
                }
                break
            case "pushToParse":
                // Get dictionary from Watch app
                guard let watchDict = message["value"] as! [String : AnyObject]? else {return}
                let currentHotspotId = watchDict["id"] as! String
                
                // Get current hotspot from stored hotspots
                var monitoredHotspotDictionary = self.appUserDefaults?.dictionaryForKey(savedHotspotsRegionKey) ?? Dictionary()
                var currentHotspot = monitoredHotspotDictionary[currentHotspotId] as! Dictionary<String, AnyObject>
                
                currentHotspot["info"] = watchDict["info"]
                monitoredHotspotDictionary[currentHotspotId] = currentHotspot
                self.appUserDefaults?.setObject(monitoredHotspotDictionary, forKey: savedHotspotsRegionKey)
                self.appUserDefaults?.synchronize()
                
                // Push data to parse
                let query = PFQuery(className: "hotspot")
                query.getObjectInBackgroundWithId(currentHotspotId) {
                    (hotspot: PFObject?, error: NSError?) -> Void in
                    if error != nil {
                        print("Error in pushing data to Parse: \(error)")
                        
                        // return information to apple watch
                        replyHandler(["response": false])
                    } else if let hotspot = hotspot {
                        hotspot["info"] = watchDict["info"]
                        hotspot.saveInBackground()
                        
                        print("Pushing data to parse")
                        print(hotspot)
                        
                        // return information to apple watch
                        replyHandler(["response": true])
                    }
                }
                break
            case "notificationOccured":
                // Get location id from Watch app
                guard let locationID = message["value"] as! String? else {return}
                
                // Get current hotspot from stored hotspots
                var monitoredHotspotDictionary = self.appUserDefaults?.dictionaryForKey(savedHotspotsRegionKey) ?? Dictionary()
                let currentHotspot = monitoredHotspotDictionary[locationID] as! Dictionary<String, AnyObject>
                
                // return information to apple watch
                replyHandler(["response": currentHotspot])
                break
            default:
                break
        }
    }
}

