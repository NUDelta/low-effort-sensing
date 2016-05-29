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
    
    // MARK: Class Variables
    @IBOutlet weak var responseTextField: UITextField!
    @IBOutlet weak var question: UILabel!
    
    var notificationMessage = ""
    var oldSelection = ""
    var pickerData: [String] = [String]()
    var responsePicker: UIPickerView!
    
    let appUserDefaults = NSUserDefaults(suiteName: appGroup)
    
    // Passed in arguments
    var currentHotspotId: String = ""
    var scenario: String = ""
    var currentQuestion: String = ""
    
    // MARK: Class Variables
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Set up food type picker
        responsePicker = UIPickerView(frame: CGRectMake(0, 200, view.frame.width, 300))
        responsePicker.backgroundColor = .whiteColor()
        
        responsePicker.showsSelectionIndicator = true
        responsePicker.delegate = self
        responsePicker.dataSource = self
        
        let responseToolBar = UIToolbar()
        responseToolBar.barStyle = UIBarStyle.Default
        responseToolBar.translucent = true
        responseToolBar.sizeToFit()
        
        let doneResponseButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(RespondToOtherViewController.doneResponsePicker))
        let spaceResponseButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        let cancelResponseButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(RespondToOtherViewController.cancelResponsePicker))
        
        responseToolBar.setItems([cancelResponseButton, spaceResponseButton, doneResponseButton], animated: false)
        responseToolBar.userInteractionEnabled = true
        
        responseTextField.inputView = responsePicker
        responseTextField.inputAccessoryView = responseToolBar
        
        self.responseTextField.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        // set question text and populate answer list for question
        switch self.scenario {
        case "food":
            pickerData = [""] + foodAnswers[self.currentQuestion]!
            break
        case "queue":
            pickerData = [""] + queueAnswers[self.currentQuestion]!
            break
        case "space":
            pickerData = [""] + spaceAnswers[self.currentQuestion]!
            break
        case "surprising":
            pickerData = [""] + surprisingAnswers[self.currentQuestion]!
            break
        default:
            pickerData = [""]
            break
        }
        
        self.question.text = self.notificationMessage
        self.question.adjustsFontSizeToFitWidth = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UI and Other Functions
    func setCurrentVariables(hotspotId: String, scenario: String, question: String, notification: String) {
        self.currentHotspotId = hotspotId
        self.scenario = scenario
        self.currentQuestion = question
        
        self.notificationMessage = notification
    }
    
    // The number of columns of data
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.pickerData.count
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.pickerData[row]
    }
    
    // Catpure the picker view selection
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // This method is triggered whenever the user makes a change to the picker selection.
        // The parameter named row and component represents what was selected.
        responseTextField.text = pickerData[row]
    }
    
    // Response Picker buttons
    func doneResponsePicker() {
        oldSelection = responseTextField.text!
        responseTextField.resignFirstResponder()
    }
    
    func cancelResponsePicker() {
        responseTextField.text =  oldSelection
        responseTextField.resignFirstResponder()
    }
    
    @IBAction func submitData(sender: AnyObject) {
        if responseTextField.text != "" {
            // get UTC timestamp and timezone of notification
            let epochTimestamp = Int(NSDate().timeIntervalSince1970)
            let gmtOffset = NSTimeZone.localTimeZone().secondsFromGMT
            
            // Push data to parse
            let newResponse = PFObject(className: "pingResponse")
            newResponse["vendorId"] = vendorId
            newResponse["hotspotId"] = self.currentHotspotId
            newResponse["question"] = self.currentQuestion
            newResponse["response"] = responseTextField.text
            newResponse["tag"] = self.scenario
            newResponse["timestamp"] = epochTimestamp
            newResponse["gmtOffset"] = gmtOffset
            
            newResponse.saveInBackground()
            
            // Inform user data has been saved
            let alertController = UIAlertController(title: "Data Saved Successfully", message: "You will now return to the home screen.", preferredStyle: .Alert)
            
            let okAction = UIAlertAction(title: "OK", style: .Default) { (action:UIAlertAction!) in
                self.dismissViewControllerAnimated(true, completion: nil)
            }
            alertController.addAction(okAction)
            self.presentViewController(alertController, animated: true, completion: nil)
        } else {
            // Inform user that response cannot be blank
            let alertController = UIAlertController(title: "Response Cannot Be Blank", message: "Please fill out a value using the text box or click \"Cancel\" to exit.", preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func cancelResponse(sender: AnyObject) {
        // Ask user if they are sure they want to go back to main screen
        let alertController = UIAlertController(title: "Are you sure you want to back?", message: "You cannot return to this screen and any unsaved data will be lost.", preferredStyle: .Alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: .Default) { (action:UIAlertAction!) in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        let noAction = UIAlertAction(title: "No", style: .Default) { (action:UIAlertAction!) in
            return
        }
        
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
}


