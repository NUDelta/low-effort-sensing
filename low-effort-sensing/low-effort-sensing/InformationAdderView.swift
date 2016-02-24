//
//  InformationAdderView.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 2/24/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//


import UIKit
import Parse
import CoreLocation
import WatchConnectivity
import Foundation

class InformationAdderView: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, CLLocationManagerDelegate {
    
    // MARK: Properities
    @IBOutlet weak var foodType: UITextField!
    @IBOutlet weak var foodDuration: UITextField!
    @IBOutlet weak var stillFood: UITextField!
    
    var oldFoodTypeSelection = ""
    var oldFoodDurationSelection = ""
    var oldStillFoodSelection = ""
    
    let foodTypeData = ["pizza", "noodles", "milkshakes", "sandwiches"]
    let foodDurationData = ["< 30 mins", "1 hour", "2 hours"]
    let stillFoodData = ["Yes-a lot", "Some-going fast!", "None"]
    
    var foodTypePicker: UIPickerView!
    var foodDurationPicker: UIPickerView!
    var stillFoodPicker: UIPickerView!
    
    // Passed in arguments
    var hotspotObj: PFObject!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Set up food type picker
        foodTypePicker = UIPickerView(frame: CGRectMake(0, 200, view.frame.width, 300))
        foodTypePicker.backgroundColor = .whiteColor()
        
        foodTypePicker.showsSelectionIndicator = true
        foodTypePicker.delegate = self
        foodTypePicker.dataSource = self
        
        let foodTypeToolBar = UIToolbar()
        foodTypeToolBar.barStyle = UIBarStyle.Default
        foodTypeToolBar.translucent = true
        foodTypeToolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
        foodTypeToolBar.sizeToFit()
        
        let doneFoodTypeButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: "doneFoodTypePicker")
        let spaceFoodTypeButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        let cancelFoodTypeButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: "cancelFoodTypePicker")
        
        foodTypeToolBar.setItems([cancelFoodTypeButton, spaceFoodTypeButton, doneFoodTypeButton], animated: false)
        foodTypeToolBar.userInteractionEnabled = true
        
        foodType.inputView = foodTypePicker
        foodType.inputAccessoryView = foodTypeToolBar
        
        self.foodType.delegate = self
        
        // Set up food duration picker
        foodDurationPicker = UIPickerView(frame: CGRectMake(0, 200, view.frame.width, 300))
        foodDurationPicker.backgroundColor = .whiteColor()
        
        foodDurationPicker.showsSelectionIndicator = true
        foodDurationPicker.delegate = self
        foodDurationPicker.dataSource = self
        
        let foodDurationToolBar = UIToolbar()
        foodDurationToolBar.barStyle = UIBarStyle.Default
        foodDurationToolBar.translucent = true
        foodDurationToolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
        foodDurationToolBar.sizeToFit()
        
        let doneFoodDurationButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: "doneFoodDurationPicker")
        let spaceFoodDurationButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        let cancelFoodDurationButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: "cancelFoodDurationPicker")
        
        foodDurationToolBar.setItems([cancelFoodDurationButton, spaceFoodDurationButton, doneFoodDurationButton], animated: false)
        foodDurationToolBar.userInteractionEnabled = true
        
        foodDuration.inputView = foodDurationPicker
        foodDuration.inputAccessoryView = foodDurationToolBar
        
        self.foodDuration.delegate = self
        
        // Set up food duration picker
        stillFoodPicker = UIPickerView(frame: CGRectMake(0, 200, view.frame.width, 300))
        stillFoodPicker.backgroundColor = .whiteColor()
        
        stillFoodPicker.showsSelectionIndicator = true
        stillFoodPicker.delegate = self
        stillFoodPicker.dataSource = self
        
        let stillFoodToolBar = UIToolbar()
        stillFoodToolBar.barStyle = UIBarStyle.Default
        stillFoodToolBar.translucent = true
        stillFoodToolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
        stillFoodToolBar.sizeToFit()
        
        let doneStillFoodButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: "doneStillFoodPicker")
        let spaceStillFoodButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        let cancelStillFoodButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: "cancelStillFoodPicker")
        
        stillFoodToolBar.setItems([cancelStillFoodButton, spaceStillFoodButton, doneStillFoodButton], animated: false)
        stillFoodToolBar.userInteractionEnabled = true
        
        stillFood.inputView = stillFoodPicker
        stillFood.inputAccessoryView = stillFoodToolBar
        
        self.stillFood.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // The number of columns of data
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch (pickerView) {
        case self.foodTypePicker:
            return foodTypeData.count
        case self.foodDurationPicker:
            return foodDurationData.count
        case self.stillFoodPicker:
            return stillFoodData.count
        default:
            return 1
        }
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch (pickerView) {
        case self.foodTypePicker:
            return foodTypeData[row]
        case self.foodDurationPicker:
            return foodDurationData[row]
        case self.stillFoodPicker:
            return stillFoodData[row]
        default:
            return ""
        }
    }
    
    // Catpure the picker view selection
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // This method is triggered whenever the user makes a change to the picker selection.
        // The parameter named row and component represents what was selected.
        switch (pickerView) {
        case self.foodTypePicker:
            foodType.text = foodTypeData[row]
        case self.foodDurationPicker:
            foodDuration.text = foodDurationData[row]
        case self.stillFoodPicker:
            stillFood.text = stillFoodData[row]
        default:
            return
        }
    }
    
    // Food Type Picker buttons
    func doneFoodTypePicker() {
        oldFoodTypeSelection = foodType.text!
        foodType.resignFirstResponder()
    }
    
    func cancelFoodTypePicker() {
        foodType.text = oldFoodTypeSelection
        foodType.resignFirstResponder()
    }

    // Food Duration Picker buttons
    func doneFoodDurationPicker() {
        oldFoodDurationSelection = foodDuration.text!
        foodDuration.resignFirstResponder()
    }
    
    func cancelFoodDurationPicker() {
        foodDuration.text = oldFoodDurationSelection
        foodDuration.resignFirstResponder()
    }
    
    // Still Food Picker buttons
    func doneStillFoodPicker() {
        oldStillFoodSelection = stillFood.text!
        stillFood.resignFirstResponder()
    }
    
    func cancelStillFoodPicker() {
        stillFood.text = oldStillFoodSelection
        stillFood.resignFirstResponder()
    }
    
    @IBAction func pushFilledDataToParse(sender: AnyObject) {

    }
    
    // MARK: Actions
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if (identifier == "submitAndToMain") {
            // Get latest values and add to Parse object
            var filledDataDict = [String : AnyObject]()
            filledDataDict["foodType"] = foodType.text
            filledDataDict["foodDuration"] = foodDuration.text
            filledDataDict["stillFood"] = stillFood.text
            
            hotspotObj["info"] = filledDataDict
            hotspotObj.saveInBackground()
            
            print("Pushing data to parse")
            print(hotspotObj)
            
            return true
        } else if (identifier == "backToMain") {
            return true
        }
        return true
    }
}

