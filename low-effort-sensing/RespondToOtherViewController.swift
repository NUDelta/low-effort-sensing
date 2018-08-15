//
//  RespondToOtherViewController.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 5/26/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import Foundation
import UIKit
import Parse

class RespondToOtherViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    // MARK: Class Properties
    @IBOutlet weak var responsePicker: UIPickerView!
    @IBOutlet weak var question: UILabel!

    // MARK: Class Variables
    var window: UIWindow?
    let appUserDefaults = UserDefaults(suiteName: appGroup)

    // variables for picker
    var pickerData: [String] = [""]
    var notificationMessage = ""
    
    // Passed in arguments
    var userInfo: [String : AnyObject] = [:]
    var categoryIdentifier: String = ""
    
    // MARK: Class Variables
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set up response picker
        self.responsePicker.backgroundColor = UIColor.white
        
        self.responsePicker.showsSelectionIndicator = true
        self.responsePicker.delegate = self
        self.responsePicker.dataSource = self
        
        let responseToolBar = UIToolbar()
        responseToolBar.barStyle = UIBarStyle.default
        responseToolBar.isTranslucent = true
        responseToolBar.sizeToFit()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // set question text and populate answer list for question
        self.question.text = self.notificationMessage
        self.question.adjustsFontSizeToFitWidth = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Data Setup
    func setCurrentVariables(_ userInfo: [String : AnyObject], categoryIdentifier: String) {
        // clear out pickerData
        self.pickerData = [""]

        // set class level variables
        self.userInfo = userInfo
        self.categoryIdentifier = categoryIdentifier

        // create data for picker
        switch categoryIdentifier {
        case "atdistance":
            self.notificationMessage = userInfo["atDistanceMessage"] as! String
            self.pickerData += userInfo["atDistanceResponses"] as! [String]
            break
        case "enroute":
            fallthrough
        default:
            self.notificationMessage = userInfo["atLocationMessage"] as! String
            self.pickerData += userInfo["atLocationResponses"] as! [String]
            break
        }
    }

    // MARK: - Setup Picker
    // The number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.pickerData.count
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.pickerData[row]
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 50
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 45));
        label.lineBreakMode = .byWordWrapping;
        label.numberOfLines = 0;
        label.text = self.pickerData[row]
        label.textAlignment = .center
        label.sizeToFit()
        return label;
    }

    // MARK: - Buttons
    @IBAction func submitData(_ sender: AnyObject) {
        let currentData = self.pickerData[self.responsePicker.selectedRow(inComponent: 0)]
        print(currentData)
        if currentData != "" {
            // save response
            self.savePickerResponse(currentData)

            // Inform user data has been saved
            let alertController = UIAlertController(title: "Data Saved Successfully",
                                                    message: "Hooray \u{1F389}, thank you! You will now return to the home screen.",
                                                    preferredStyle: .alert)

            let okAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) in
                // return to mapview
                self.returnToMapView()
            }

            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        } else {
            // Inform user that response cannot be blank
            let alertController = UIAlertController(title: "Response Cannot Be Blank",
                                                    message: "Please fill out a value using the text box or click \"Cancel\" to exit.",
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func cancelResponse(_ sender: AnyObject) {
        // Ask user if they are sure they want to go back to main screen
        let alertController = UIAlertController(title: "Are you sure you want to back?",
                                                message: "You cannot return to this screen and any unsaved data will be lost.",
                                                preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: .default) { (action:UIAlertAction!) in
            // save this as a dismissal
            self.savePickerResponse("com.apple.UNNotificationDismissActionIdentifier")

            // return to mapview
            self.returnToMapView()
        }

        let noAction = UIAlertAction(title: "No", style: .default) { (action:UIAlertAction!) in
            return
        }

        // add actions and present to user
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        self.present(alertController, animated: true, completion: nil)
    }

    private func returnToMapView() {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let homeViewController = mainStoryboard.instantiateViewController(withIdentifier: "HomeScreenViewController")

        self.window?.rootViewController = homeViewController
        self.window?.makeKeyAndVisible()
    }

    private func savePickerResponse(_ responseValue: String) {
        // get UTC timestamp and timezone of notification
        let epochTimestamp = Int(Date().timeIntervalSince1970)
        let gmtOffset = NSTimeZone.local.secondsFromGMT()

        // create object to push
        let newResponse: PFObject
        let notificationId = self.userInfo["id"] as! String

        switch self.categoryIdentifier {
        case "atdistance":
            var didIncludeInfoAtDistance: Bool = false
            if let preferredInfo = self.userInfo["preferredInfo"], let shouldNotifyAtDistance = self.userInfo["shouldNotifyAtDistance"] {
                didIncludeInfoAtDistance = !(preferredInfo as! String == "") && (shouldNotifyAtDistance as! Bool)
            }

            newResponse = PFObject(className: "AtDistanceNotificationResponses")
            newResponse["vendorId"] = vendorId
            newResponse["taskLocationId"] = notificationId
            newResponse["locationType"] = self.userInfo["locationType"] as! String
            newResponse["notificationDistance"] = self.userInfo["atDistanceNotificationDistance"] as! Double
            newResponse["infoIncluded"] = didIncludeInfoAtDistance
            newResponse["timestamp"] = epochTimestamp
            newResponse["gmtOffset"] = gmtOffset
            newResponse["emaResponse"] = responseValue

            // check whether to update Pretracker AtDistance and EnRoute states
            let responseAcceptSet: Set = [
                "Yes! This info is useful, I'm going now.",
                "Yes. This info is useful but I'm already going there.",
                "Sure! I would be happy to go out of my way!",
                "Sure, but I was going to walk past it anyway."
            ]
            if (responseAcceptSet.contains(responseValue)) {
                MyPretracker.sharedManager.setShouldNotifyAtDistance(id: notificationId, value: true)
                MyPretracker.sharedManager.setShouldNotifyEnRoute(value: true)
            }
            break
        case "enroute":
            newResponse = PFObject(className: "EnRouteNotificationResponses")
            newResponse["vendorId"] = vendorId
            newResponse["enRouteLocationId"] = notificationId
            newResponse["timestamp"] = epochTimestamp
            newResponse["gmtOffset"] = gmtOffset
            newResponse["questionResponse"] = responseValue
            break
        default:
            // get scenario and question as separate components
            let notificationCategoryArr = self.categoryIdentifier.components(separatedBy: "_")

            newResponse = PFObject(className: "AtLocationNotificationResponses")
            newResponse["vendorId"] = vendorId
            newResponse["taskLocationId"] = notificationId
            newResponse["locationType"] = notificationCategoryArr[0]
            newResponse["timestamp"] = epochTimestamp
            newResponse["gmtOffset"] = gmtOffset
            newResponse["question"] = notificationCategoryArr[1]
            newResponse["response"] = responseValue


            let currentAtDistanceLocation = MyPretracker.sharedManager.currentAtDistanceLocation
            if (currentAtDistanceLocation != "") && (notificationId == currentAtDistanceLocation) {
                MyPretracker.sharedManager.setShouldNotifyAtDistance(id: notificationId, value: false)
                MyPretracker.sharedManager.setShouldNotifyEnRoute(value: false)
            }
            break
        }

        // add current location data before saving
        var currLocation: PFGeoPoint
        if let managerCurrLocation = MyPretracker.sharedManager.currentLocation {
            currLocation = PFGeoPoint.init(location: managerCurrLocation)
        } else {
            currLocation = PFGeoPoint.init()
        }

        newResponse["location"] = currLocation

        // save logic
        newResponse.saveInBackground(block: { (saved: Bool, error: Error?) -> Void in
            // if save is unsuccessful (due to network issues) saveEventually when network is available
            if !saved {
                print("Error in saveInBackground: \(String(describing: error)). Attempting eventually.")
                newResponse.saveEventually()
            }
        })
    }
}


