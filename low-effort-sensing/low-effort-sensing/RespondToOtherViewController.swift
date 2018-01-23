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
    
    let appUserDefaults = UserDefaults(suiteName: appGroup)
    
    // Passed in arguments
    var currentHotspotId: String = ""
    var scenario: String = ""
    var currentQuestion: String = ""
    
    // MARK: Class Variables
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Set up food type picker
        responsePicker = UIPickerView(frame: CGRect(x: 0, y: 200, width: view.frame.width, height: 300))
        responsePicker.backgroundColor = UIColor.white
        
        responsePicker.showsSelectionIndicator = true
        responsePicker.delegate = self
        responsePicker.dataSource = self
        
        let responseToolBar = UIToolbar()
        responseToolBar.barStyle = UIBarStyle.default
        responseToolBar.isTranslucent = true
        responseToolBar.sizeToFit()
        
        let doneResponseButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(RespondToOtherViewController.doneResponsePicker))
        let spaceResponseButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let cancelResponseButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.plain, target: self, action: #selector(RespondToOtherViewController.cancelResponsePicker))
        
        responseToolBar.setItems([cancelResponseButton, spaceResponseButton, doneResponseButton], animated: false)
        responseToolBar.isUserInteractionEnabled = true
        
        responseTextField.inputView = responsePicker
        responseTextField.inputAccessoryView = responseToolBar
        
        self.responseTextField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
    func setCurrentVariables(_ hotspotId: String, scenario: String, question: String, notification: String) {
        self.currentHotspotId = hotspotId
        self.scenario = scenario
        self.currentQuestion = question
        
        self.notificationMessage = notification
    }
    
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
    
    // Catpure the picker view selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // This method is triggered whenever the user makes a change to the picker selection.
        // The parameter named row and component represents what was selected.
        responseTextField.text = pickerData[row]
    }
    
    // Response Picker buttons
    @objc func doneResponsePicker() {
        oldSelection = responseTextField.text!
        responseTextField.resignFirstResponder()
    }
    
    @objc func cancelResponsePicker() {
        responseTextField.text =  oldSelection
        responseTextField.resignFirstResponder()
    }
    
    @IBAction func submitData(_ sender: AnyObject) {
        if responseTextField.text != "" {
            // get UTC timestamp and timezone of notification
            let epochTimestamp = Int(Date().timeIntervalSince1970)
            let gmtOffset = NSTimeZone.local.secondsFromGMT()
            
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
            let alertController = UIAlertController(title: "Data Saved Successfully", message: "You will now return to the home screen.", preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) in
                self.dismiss(animated: true, completion: nil)
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        } else {
            // Inform user that response cannot be blank
            let alertController = UIAlertController(title: "Response Cannot Be Blank", message: "Please fill out a value using the text box or click \"Cancel\" to exit.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func cancelResponse(_ sender: AnyObject) {
        // Ask user if they are sure they want to go back to main screen
        let alertController = UIAlertController(title: "Are you sure you want to back?", message: "You cannot return to this screen and any unsaved data will be lost.", preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: .default) { (action:UIAlertAction!) in
            self.dismiss(animated: true, completion: nil)
        }
        let noAction = UIAlertAction(title: "No", style: .default) { (action:UIAlertAction!) in
            return
        }
        
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        self.present(alertController, animated: true, completion: nil)
    }
}


