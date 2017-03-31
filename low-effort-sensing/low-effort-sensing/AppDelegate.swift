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
import UserNotifications
import Parse
import Bolts
import WatchConnectivity

let distanceFromTarget = 20.0
let geofenceRadius = 150.0
let savedHotspotsRegionKey = "savedMonitoredHotspots" // for saving currently monitored locations to NSUserDefaults
let myHotspotsRegionKey = "savedMarkedHotspots" // for saving all hotspots user has marked before
var vendorId: String = ""

// App Group for Sharing Data (dependent on build type)
#if DEBUG
    let appGroup = "group.com.delta.les-debug" // for debug builds
#else
    let appGroup = "group.com.delta.les"       // for enterprise distribution builds
#endif

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

// converts string into ASCII integer array
extension String {
    var asciiArray: [UInt32] {
        return unicodeScalars.filter{$0.isASCII}.map{$0.value}
    }
}

// question ordering
let foodQuestionOrdering = ["isfood", "foodtype", "howmuchfood",
                            "freeorsold", "forstudentgroup", "cost", "sellingreason"]

let queueQuestionOrdering = ["isline", "linetime", "islonger", "isworthwaiting", "npeople"]

let spaceQuestionOrdering = ["isspace", "isavailable", "seatingtype", "seatingnearpower",
                             "iswifi", "manypeople", "loudness", "event"]

let surprisingQuestionOrdering = ["whatshappening", "famefrom", "vehicles", "peopledoing"]

let guestEventQuestionOrdering = ["eventkind", "host", "isfood", "foodkind", "foodleft", "eventlength"]

let windowDrawingQuestionOrdering = ["objectright", "colorright", "valueright", "objectleft", "colorleft", "valueleft"]

let dtrDonutQuestionOrdering = ["room", "boxdrawing", "boxcontent", "markercolor", "plain", "frosted"]

// blank location info
let foodInfo = ["isfood": "", "foodtype": "", "howmuchfood": "",
                "freeorsold": "", "forstudentgroup": "", "cost": "", "sellingreason": ""]

let queueInfo = ["isline": "", "linetime": "", "islonger": "", "isworthwaiting": "", "npeople": ""]

let spaceInfo = ["isspace": "", "isavailable": "", "seatingtype": "", "seatingnearpower": "",
                 "iswifi": "", "manypeople": "", "loudness": "", "event": ""]

let surprisingInfo = ["whatshappening": "", "famefrom": "", "vehicles": "", "peopledoing": ""]

let guestEventInfo = ["eventkind": "", "host": "", "isfood": "", "foodkind": "", "foodleft": "", "eventlength": ""]

let windowDrawingInfo = ["objectright": "", "colorright": "", "valueright": "", "objectleft": "", "colorleft": "", "valueleft": ""]

let dtrDonutInfo = ["room": "", "boxdrawing": "", "boxcontent": "", "markercolor": "", "plain": "", "frosted": ""]

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
                    "seatingnearpower": ["yes", "no"],
                    "iswifi": ["yes", "no"],
                    "manypeople": ["yes", "no"],
                    "loudness": ["loud", "light conversation", "quiet"],
                    "event": ["no", "sports", "music", "gathering", "other"]]

let surprisingAnswers = ["whatshappening": ["no", "celebrity", "emergency vehicles", "lots of people"],
                         "famefrom": ["no longer here", "musician", "actor/actress", "politician", "comedian", "other", "I don't know"],
                         "vehicles": ["no longer here", "just police", "police, firetrucks, and ambulances"],
                         "peopledoing": ["no longer here", "protest/riot", "student gathering for organization", "university or formal event", "other", "I don't know"]]

let guestEventAnswers = ["eventkind": ["lecture", "talk", "workshop", "other", "I don't know"],
                         "host": ["student group", "northwestern organization", "northwestern faculty", "I don't know"],
                         "isfood": ["yes", "no", "I don't know"],
                         "foodkind": ["sandwiches", "pizza", "desserts", "other", "I don't know"],
                         "foodleft": ["still a lot", "less than half", "very little", "I don't know"],
                         "eventlength": ["< 1 hour", "1-2 hours", "> 2 hours", "I don't know"]]

let windowDrawingAnswers = ["objectright": ["letter", "number", "I don't know"],
                            "colorright": ["pink", "orange", "blue", "I don't know"],
                            "valueright": ["1", "2", "3", "A", "B", "C", "I don't know"],
                            "objectleft": ["letter", "number", "I don't know"],
                            "colorleft": ["pink", "orange", "blue", "I don't know"],
                            "valueleft": ["1", "2", "3", "A", "B", "C", "I don't know"]]

let dtrDonutAnswers = ["room": ["hackerspace", "delta lab", "I don't know"],
                       "boxdrawing": ["yes", "no", "I don't know"],
                       "boxcontent": ["inspirational message", "quote", "I don't know"],
                       "markercolor": ["red", "black", "green", "other", "I don't know"],
                       "plain": ["yes", "no", "I don't know"],
                       "frosted": ["yes", "no", "I don't know"]]

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
                          "seatingnearpower": "Is there seating near power outlets?",
                          "iswifi": "Is there Wifi?",
                          "manypeople": "Are there a lot of people here?",
                          "loudness": "How loud is the place?",
                          "event": "Is there an event, like a sports game on TV or live music, going on here?"]

let surprisingKeyToQuestion = ["whatshappening": "What’s happening here?",
                               "famefrom": "What are they known for?",
                               "vehicles": "What vehicles are there?",
                               "peopledoing": "What are they doing there?"]

let guestEventKeyToQuestion = ["eventkind": "What kind of event is happening?",
                               "host": "Who is hosting the event?",
                               "isfood": "Is there food?",
                               "foodkind": "What kind of food is there?",
                               "foodleft": "How much food is left?",
                               "eventlength": "How much longer will the event be going on?"]

let windowDrawingKeyToQuestion = ["objectright": "What's drawn on the right?",
                                  "colorright": "What color is the right drawing?",
                                  "valueright": "What's the value of the right drawing?",
                                  "objectleft": "What's drawn on the left?",
                                  "colorleft": "What color is the left drawing?",
                                  "valueleft": "What's the value of the left drawing?"]

let dtrDonutKeyToQuestion = ["room": "Are the donuts in the Hackerspace or Delta Lab?",
                             "boxdrawing": "Does the box have anything written on it?",
                             "boxcontent": "What's written on the box?",
                             "markercolor": "What color marker was used to write on the box?",
                             "plain": "Are there any plain donuts?",
                             "frosted": "Are there any frosted donuts?"]

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate, UNUserNotificationCenterDelegate {
    // MARK: Class Variables
    var window: UIWindow?
    let watchSession = WCSession.default()
    var shortcutItem: UIApplicationShortcutItem?
    
    let appUserDefaults = UserDefaults.init(suiteName: appGroup)
    var notificationCategories = Set<UNNotificationCategory>()
    
    // MARK: - AppDelegate Functions
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Check active state for 3D Touch Home actions
        var performShortcutDelegate = true
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            print("Application launched via shortcut")
            self.shortcutItem = shortcutItem
            
            performShortcutDelegate = false
        }
        
        // reset badge, if applicable
        UIApplication.shared.applicationIconBadgeNumber = 0;
        
        // Capture device's unique vendor id
        if let uuid = UIDevice.current.identifierForVendor?.uuidString {
            vendorId = uuid
        }
        
        // Initalize WatchSession
        watchSession.delegate = self
        watchSession.activate()
        
        // Initialize Parse.
        Parse.enableDataSharing(withApplicationGroupIdentifier: appGroup)
        Parse.initialize(with: ParseClientConfiguration(block: { (configuration: ParseMutableClientConfiguration) -> Void in
            configuration.server = "https://dtr-les.herokuapp.com/parse/"
            configuration.applicationId = "PkngqKtJygU9WiQ1GXM9eC0a17tKmioKKmpWftYr"
            configuration.clientKey = "vsA30VpFQlGFKhhjYdrPttTvbcg1JxkbSSNeGCr7"
        }))
        
        // location manager and setting up monitored locations
        MyPretracker.sharedManager.setupParameters(distanceFromTarget,
                                                     radius: geofenceRadius,
                                                     accuracy: kCLLocationAccuracyNearestTenMeters,
                                                     distanceFilter: nil)
        
        // setup beacon manager
        BeaconTracker.sharedBeaconManager.initBeaconManager()
        
        // setup local notifications
        UNUserNotificationCenter.current().delegate = self
        
        // create default category for notification without any questions asked
        notificationCategories.insert(UNNotificationCategory(identifier: "no question", actions: [], intentIdentifiers: [], options: [.customDismissAction]))
        
        // create notifications for all types
        createFoodNotifications()
        createQueueNotifications()
        createSpaceNotifications()
        createSurprisingNotifications()
        createGuestEventNotifications()
        createWindowDrawingNotifications()
        createDtrDonutNotifications()
        
        // check if user has already opened app before, if not show welcome screen
        let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")
        if launchedBefore  {
            // register categories for notifications
            registerForNotifications()
            
            // setup push notifications
            let options: UNAuthorizationOptions = [.alert, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: options) { (granted, error) in
                let generalCategory = UNNotificationCategory(identifier: "general", actions: [], intentIdentifiers: [], options: .customDismissAction)
                UNUserNotificationCenter.current().setNotificationCategories([generalCategory])
            }
            
            if #available(iOS 10, *) {
                UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]){ (granted, error) in }
                application.registerForRemoteNotifications()
            }
                // iOS 9 support
            else if #available(iOS 9, *) {
                UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
                UIApplication.shared.registerForRemoteNotifications()
            }
                // iOS 8 support
            else if #available(iOS 8, *) {
                UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
                UIApplication.shared.registerForRemoteNotifications()
            }
                // iOS 7 support
            else {
                application.registerForRemoteNotifications(matching: [.badge, .sound, .alert])
            }
            
            // open map view
            self.window = UIWindow(frame: UIScreen.main.bounds)
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let homeViewController = mainStoryboard.instantiateViewController(withIdentifier: "HomeScreenViewController")
            
            self.window?.rootViewController = homeViewController
            self.window?.makeKeyAndVisible()
            
//            // DEBUG NOTIFICATION
//            Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(AppDelegate.sendNotification), userInfo: nil, repeats: true)
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
            
            self.appUserDefaults?.set(userInfo, forKey: "welcomeData")
            self.appUserDefaults?.synchronize()
        }
        
        // show light-colored status bar on each page
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .lightContent
  
        return performShortcutDelegate
    }
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        if notificationSettings.types != .none {
            application.registerForRemoteNotifications()
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        print(deviceTokenString)
        //defaults.set(deviceTokenString, forKey: "tokenId")
        //        sendUserToken(deviceTokenString)
    }
    //
    //    func application(_ application: UIApplication, didReceiveRemoteNotification data: [AnyHashable : Any]) {
    //        print("Push notification received: \(data)")
    //        Pretracker.sharedManager.locationManager!.startUpdatingLocation()
    //        if let currentLocation = Pretracker.sharedManager.currentLocation {
    //            let lat = currentLocation.coordinate.latitude
    //            let lon = currentLocation.coordinate.longitude
    //            sendCurrentLocation(lat: Float(lat),lon: Float(lon))
    //        }
    //    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Print the error to console (you should alert the user that registration failed)
        print("APNs registration failed: \(error)")
    }

    
//    // USED FOR DEBUGGING
//    func sendNotification() {
//        print("Preparing notification")
//        // Get NSUserDefaults
//        var monitoredHotspotDictionary = UserDefaults.init(suiteName: appGroup)?.dictionary(forKey: savedHotspotsRegionKey) ?? [:]
//        print(monitoredHotspotDictionary)
//        
//        // Get first region in mo nitored regions to use
//        if  monitoredHotspotDictionary.keys.count > 0 {
//            let currentRegion = monitoredHotspotDictionary["ob333ez7Ij"] as! [String : AnyObject]
//            let newNotification = NotificationCreator(scenario: currentRegion["tag"] as! String, hotspotInfo: currentRegion["info"] as! [String : String], currentHotspot: currentRegion)
//            let notificationContent = newNotification.createNotificationForTag()
//            
//            print(notificationContent)
//            
//            // Display notification with context
//            let content = UNMutableNotificationContent()
//            content.body = notificationContent["message"]!
//            content.sound = UNNotificationSound.default()
//            content.categoryIdentifier = notificationContent["notificationCategory"]!
//            content.userInfo = currentRegion
//            
//            let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 3, repeats: false)
//            let notificationRequest = UNNotificationRequest(identifier: currentRegion["id"]! as! String, content: content, trigger: trigger)
//            
//            UNUserNotificationCenter.current().add(notificationRequest, withCompletionHandler: { (error) in
//                if let error = error {
//                    print("Error in notifying from Pre-Tracker: \(error)")
//                }
//            })
//        }
//    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        print("App will resign active")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("App will enter background")
        
        // Log app going into background
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDateString = dateFormatter.string(from: date)

        let newLog = PFObject(className: "pretracking_debug")
        newLog["vendor_id"] = vendorId
        newLog["timestamp_epoch"] = Int(date.timeIntervalSince1970)
        newLog["timestamp_string"] = currentDateString
        newLog["console_string"] = "App entering background"
        newLog.saveInBackground()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        print("App will enter foreground")
        
        // Log app going into foreground
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDateString = dateFormatter.string(from: date)
        
        let newLog = PFObject(className: "pretracking_debug")
        newLog["vendor_id"] = vendorId
        newLog["timestamp_epoch"] = Int(date.timeIntervalSince1970)
        newLog["timestamp_string"] = currentDateString
        newLog["console_string"] = "App entering foreground"
        newLog.saveInBackground()

    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("Application did become active")
        
        guard let shortcut = shortcutItem else { return }
        print("- Shortcut property has been set")
        let _ = handleShortcut(shortcut)
        self.shortcutItem = nil
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("App will terminate")
        
        // Log app about to terminate
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDateString = dateFormatter.string(from: date)
        
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
        print("Registering categories for local notifications")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: { (granted, error) in
            if (granted) {
                UNUserNotificationCenter.current().setNotificationCategories(self.notificationCategories)
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                print("Notification setup complete")
            } else {
                print("Error when registering for notifications: \(error)")
            }
        })
    }
    
    // MARK: - Create Custom Notifications for each question
    func createFoodNotifications() {
        notificationCategories.insert(UNNotificationCategory(identifier: "food_isfood", actions: createActionsForAnswers(foodAnswers["isfood"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "food_foodtype", actions: createActionsForAnswers(foodAnswers["foodtype"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "food_howmuchfood", actions: createActionsForAnswers(foodAnswers["howmuchfood"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "food_freeorsold", actions: createActionsForAnswers(foodAnswers["freeorsold"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "food_forstudentgroup", actions: createActionsForAnswers(foodAnswers["forstudentgroup"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "food_cost", actions: createActionsForAnswers(foodAnswers["cost"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "food_sellingreason", actions: createActionsForAnswers(foodAnswers["sellingreason"]!), intentIdentifiers: [], options: [.customDismissAction]))
    }
    
    func createQueueNotifications() {
        notificationCategories.insert(UNNotificationCategory(identifier: "queue_isline", actions: createActionsForAnswers(queueAnswers["isline"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "queue_linetime", actions: createActionsForAnswers(queueAnswers["linetime"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "queue_islonger", actions: createActionsForAnswers(queueAnswers["islonger"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "queue_isworthwaiting", actions: createActionsForAnswers(queueAnswers["isworthwaiting"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "queue_npeople", actions: createActionsForAnswers(queueAnswers["npeople"]!), intentIdentifiers: [], options: [.customDismissAction]))
    }
    
    func createSpaceNotifications() {
        notificationCategories.insert(UNNotificationCategory(identifier: "space_isspace", actions: createActionsForAnswers(spaceAnswers["isspace"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "space_isavailable", actions: createActionsForAnswers(spaceAnswers["isavailable"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "space_seatingtype", actions: createActionsForAnswers(spaceAnswers["seatingtype"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "space_seatingnearpower", actions: createActionsForAnswers(spaceAnswers["seatingnearpower"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "space_iswifi", actions: createActionsForAnswers(spaceAnswers["iswifi"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "space_manypeople", actions: createActionsForAnswers(spaceAnswers["manypeople"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "space_loudness", actions: createActionsForAnswers(spaceAnswers["loudness"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "space_event", actions: createActionsForAnswers(spaceAnswers["event"]!), intentIdentifiers: [], options: [.customDismissAction]))
    }
    
    func createSurprisingNotifications() {
        notificationCategories.insert(UNNotificationCategory(identifier: "surprising_whatshappening", actions: createActionsForAnswers(surprisingAnswers["whatshappening"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "surprising_famefrom", actions: createActionsForAnswers(surprisingAnswers["famefrom"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "surprising_vehicles", actions: createActionsForAnswers(surprisingAnswers["vehicles"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "surprising_peopledoing", actions: createActionsForAnswers(surprisingAnswers["peopledoing"]!), intentIdentifiers: [], options: [.customDismissAction]))
    }
    
    func createGuestEventNotifications() {
        notificationCategories.insert(UNNotificationCategory(identifier: "guestevent_eventkind", actions: createActionsForAnswers(guestEventAnswers["eventkind"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "guestevent_host", actions: createActionsForAnswers(guestEventAnswers["host"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "guestevent_isfood", actions: createActionsForAnswers(guestEventAnswers["isfood"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "guestevent_foodkind", actions: createActionsForAnswers(guestEventAnswers["foodkind"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "guestevent_foodleft", actions: createActionsForAnswers(guestEventAnswers["foodleft"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "guestevent_eventlength", actions: createActionsForAnswers(guestEventAnswers["eventlength"]!), intentIdentifiers: [], options: [.customDismissAction]))
    }
    
    func createWindowDrawingNotifications() {
        notificationCategories.insert(UNNotificationCategory(identifier: "windowdrawing_objectright", actions: createActionsForAnswers(windowDrawingAnswers["objectright"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "windowdrawing_colorright", actions: createActionsForAnswers(windowDrawingAnswers["colorright"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "windowdrawing_valueright", actions: createActionsForAnswers(windowDrawingAnswers["valueright"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "windowdrawing_objectleft", actions: createActionsForAnswers(windowDrawingAnswers["objectleft"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "windowdrawing_colorleft", actions: createActionsForAnswers(windowDrawingAnswers["colorleft"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "windowdrawing_valueleft", actions: createActionsForAnswers(windowDrawingAnswers["valueleft"]!), intentIdentifiers: [], options: [.customDismissAction]))
    }
    
    func createDtrDonutNotifications() {
        notificationCategories.insert(UNNotificationCategory(identifier: "dtrdonut_room", actions: createActionsForAnswers(dtrDonutAnswers["room"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "dtrdonut_boxdrawing", actions: createActionsForAnswers(dtrDonutAnswers["boxdrawing"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "dtrdonut_boxcontent", actions: createActionsForAnswers(dtrDonutAnswers["boxcontent"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "dtrdonut_markercolor", actions: createActionsForAnswers(dtrDonutAnswers["markercolor"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "dtrdonut_plain", actions: createActionsForAnswers(dtrDonutAnswers["plain"]!), intentIdentifiers: [], options: [.customDismissAction]))
        notificationCategories.insert(UNNotificationCategory(identifier: "dtrdonut_frosted", actions: createActionsForAnswers(dtrDonutAnswers["frosted"]!), intentIdentifiers: [], options: [.customDismissAction]))
    }
    
    func createActionsForAnswers(_ answers: [String]) -> [UNNotificationAction] {
        var actionsForAnswers = [UNNotificationAction]()
        for answer in answers {
            let currentAction = UNNotificationAction(identifier: answer, title: answer, options: [])
            actionsForAnswers.append(currentAction)
        }
        
        return actionsForAnswers
    }
    
    //MARK: - Contextual Notification Handler
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // get UTC timestamp and timezone of notification
        let epochTimestamp = Int(Date().timeIntervalSince1970)
        let gmtOffset = NSTimeZone.local.secondsFromGMT()
        
        // get scenario and question as separate components
        let notificationCategoryArr = response.notification.request.content.categoryIdentifier.components(separatedBy: "_")
        
        // setup response object to push to parse
        var notificationId = ""
        if let unwrappedNotificationId = response.notification.request.content.userInfo["id"] {
            notificationId = unwrappedNotificationId as! String
        }
        
        let newResponse = PFObject(className: "pingResponse")
        newResponse["vendorId"] = vendorId
        newResponse["hotspotId"] = notificationId
        newResponse["question"] = notificationCategoryArr[1]
        newResponse["response"] = ""
        newResponse["tag"] = notificationCategoryArr[0]
        newResponse["timestamp"] = epochTimestamp
        newResponse["gmtOffset"] = gmtOffset
        newResponse["response"] = response.actionIdentifier

        // if response field is not blank, save to parse
        if newResponse["response"] as! String != "" {
            newResponse.saveInBackground()
        }
        completionHandler()
    }
    
    // MARK: 3D Touch shortcut handler
    // TODO: use the contextual notification code above to ensure no weird errors with views existing affect transitioning
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void){
        completionHandler(handleShortcut(shortcutItem))
    }
    
    func handleShortcut( _ shortcutItem:UIApplicationShortcutItem ) -> Bool {
        print("Handling \(shortcutItem.type)")
        PFGeoPoint.geoPointForCurrentLocation(inBackground: ({
            (geoPoint: PFGeoPoint?, error: Error?) -> Void in
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
                let epochTimestamp = Int(Date().timeIntervalSince1970)
                let gmtOffset = NSTimeZone.local.secondsFromGMT()
                
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
                
                if let currBeaconRegion = self.appUserDefaults?.object(forKey: "currentBeaconRegion") {
                    if currBeaconRegion as? String != nil {
                        newMonitoredLocation["beaconId"] = currBeaconRegion as? String
                    } else {
                        newMonitoredLocation["beaconId"] = ""
                    }
                } else {
                    newMonitoredLocation["beaconId"] = ""
                }
                
                // set info dict and saveTimeForQuestion based on tag
                switch tag {
                case "food":
                    newMonitoredLocation["info"] = foodInfo
                    newMonitoredLocation["saveTimeForQuestion"] = ["isfood": epochTimestamp, "foodtype": epochTimestamp, "howmuchfood": epochTimestamp, "freeorsold": epochTimestamp,
                                                                   "forstudentgroup": epochTimestamp, "cost": epochTimestamp, "sellingreason": epochTimestamp]
                    break
                case "queue":
                    newMonitoredLocation["info"] = queueInfo
                    newMonitoredLocation["saveTimeForQuestion"] = ["isline": epochTimestamp, "linetime": epochTimestamp, "islonger": epochTimestamp, "isworthwaiting": epochTimestamp, "npeople": epochTimestamp]
                    break
                case "space":
                    newMonitoredLocation["info"] = spaceInfo
                    newMonitoredLocation["saveTimeForQuestion"] = ["isspace": epochTimestamp, "isavailable": epochTimestamp, "seatingtype": epochTimestamp, "seatingnearpower": epochTimestamp,
                                                                   "iswifi": epochTimestamp, "manypeople": epochTimestamp, "loudness": epochTimestamp, "event": epochTimestamp]
                    break
                case "surprising":
                    newMonitoredLocation["info"] = surprisingInfo
                    newMonitoredLocation["saveTimeForQuestion"] = ["whatshappening": epochTimestamp, "famefrom": epochTimestamp, "vehicles": epochTimestamp, "peopledoing": epochTimestamp]
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
                
                let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                
                self.window?.rootViewController?.present(alert, animated: true, completion: nil)
            }
        }))
        
        return true
    }
    
    // MARK: WatchSession communication handler
    private func session(_ session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: @escaping ([String : AnyObject]) -> Void) {
        guard let command = message["command"] as! String! else {return}
        
        // Run command and return data to watch
        switch (command) {
            case "reportLocation":
                PFGeoPoint.geoPointForCurrentLocation(inBackground: ({
                    (geoPoint: PFGeoPoint?, error: Error?) -> Void in
                    if error == nil {
                        // Get current date to make debug string
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "dd-MM-YY_HH:mm"
                        
                        // Get location and push to Parse
                        let newMonitoredLocation = PFObject(className: "hotspot")
                        newMonitoredLocation["location"] = geoPoint
                        newMonitoredLocation["tag"] = "free food!"
                        newMonitoredLocation["info"] = ["foodType": "", "foodDuration": "", "stillFood": ""]
                        
                        newMonitoredLocation.saveInBackground(block: ({
                            (success: Bool, error: Error?) -> Void in
                            if (success) {
                                // add new location to monitored regions
                                let newRegionLat = (newMonitoredLocation["location"] as! PFGeoPoint).latitude
                                let newRegionLong = (newMonitoredLocation["location"] as! PFGeoPoint).longitude
                                let newRegionId = newMonitoredLocation.objectId!
                                MyPretracker.sharedManager.addLocation(distanceFromTarget, latitude: newRegionLat, longitude: newRegionLong, radius: geofenceRadius, name: newRegionId)
                                
                                // Add new region to user defaults
                                var monitoredHotspotDictionary = self.appUserDefaults?.dictionary(forKey: savedHotspotsRegionKey) ?? Dictionary()
                                
                                // Add data to user defaults
                                var unwrappedEntry = [String : AnyObject]()
                                unwrappedEntry["latitude"] = newRegionLat as AnyObject
                                unwrappedEntry["longitude"] = newRegionLong as AnyObject
                                unwrappedEntry["id"] = newMonitoredLocation.objectId as AnyObject
                                unwrappedEntry["tag"] = newMonitoredLocation["tag"] as AnyObject
                                let info : [String : AnyObject]? = newMonitoredLocation["info"] as? [String : AnyObject]
                                unwrappedEntry["info"] = info as AnyObject
                                
                                monitoredHotspotDictionary[newMonitoredLocation.objectId!] = unwrappedEntry
                                self.appUserDefaults?.set(monitoredHotspotDictionary, forKey: savedHotspotsRegionKey)
                                self.appUserDefaults?.synchronize()
                                
                                // return information to apple watch
                                replyHandler(["response": unwrappedEntry as AnyObject])
                            }
                        }))
                    }
                }))
                break
            case "pushToParse":
                // Get dictionary from Watch app
                guard let watchDict = message["value"] as! [String : AnyObject]? else {return}
                let currentHotspotId = watchDict["id"] as! String
                
                // Get current hotspot from stored hotspots
                var monitoredHotspotDictionary = self.appUserDefaults?.dictionary(forKey: savedHotspotsRegionKey) ?? Dictionary()
                var currentHotspot = monitoredHotspotDictionary[currentHotspotId] as! Dictionary<String, AnyObject>
                
                currentHotspot["info"] = watchDict["info"]
                monitoredHotspotDictionary[currentHotspotId] = currentHotspot
                self.appUserDefaults?.set(monitoredHotspotDictionary, forKey: savedHotspotsRegionKey)
                self.appUserDefaults?.synchronize()
                
                // Push data to parse
                let query = PFQuery(className: "hotspot")
                query.getObjectInBackground(withId: currentHotspotId, block: ({
                    (hotspot: PFObject?, error: Error?) -> Void in
                    if error != nil {
                        print("Error in pushing data to Parse: \(error)")
                        
                        // return information to apple watch
                        replyHandler(["response": false as AnyObject])
                    } else if let hotspot = hotspot {
                        hotspot["info"] = watchDict["info"]
                        hotspot.saveInBackground()
                        
                        print("Pushing data to parse")
                        print(hotspot)
                        
                        // return information to apple watch
                        replyHandler(["response": true as AnyObject])
                    }
                }))
                break
            case "notificationOccured":
                // Get location id from Watch app
                guard let locationID = message["value"] as! String? else {return}
                
                // Get current hotspot from stored hotspots
                var monitoredHotspotDictionary = self.appUserDefaults?.dictionary(forKey: savedHotspotsRegionKey) ?? Dictionary()
                let currentHotspot = monitoredHotspotDictionary[locationID] as! Dictionary<String, AnyObject>
                
                // return information to apple watch
                replyHandler(["response": currentHotspot as AnyObject])
                break
            default:
                break
        }
    }
    
    @available(iOS 9.3, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: NSError?) {
        
    }
    
    @available(iOS 9.3, *)
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    @available(iOS 9.3, *)
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    @available(iOS 9.3, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
}
