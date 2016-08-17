//
//  GetInformationInterfaceController.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 2/26/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class GetInformationInterfaceController: WKInterfaceController, WCSessionDelegate {
    @available(watchOSApplicationExtension 2.2, *)
    internal func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?){
    }
    
    // MARK: Class Variables
    @IBOutlet var questionsTable: WKInterfaceTable!
    @IBOutlet var locationIDLabel: WKInterfaceLabel!
    @IBOutlet var idLabel: WKInterfaceLabel!
    
    var questions = [String]()
    var locationInstanceDictionary = Dictionary<String, AnyObject>()
    
    // session for communicating with iphone
    let watchSession = WCSession.default()
    
    // MARK: Class Functions
    override func awake(withContext context: AnyObject?) {
        super.awake(withContext: context)
        // setup watch session
        watchSession.delegate = self
        watchSession.activate()
        
        // Configure interface objects here.
        guard let newLocationInstance = context as! Dictionary<String, AnyObject>? else {return}
        locationInstanceDictionary = newLocationInstance
        questions = [String]((newLocationInstance["info"] as! [String : String]).keys)
        let infoDict = newLocationInstance["info"] as! [String : String]
        
        // set values for location and ID labels
        locationIDLabel.setText("ID: " + (newLocationInstance["id"] as? String)!)
        idLabel.setText(newLocationInstance["tag"] as? String)
        
        
        questionsTable.setNumberOfRows(questions.count, withRowType: "QuestionRow")
        for index in 0..<questionsTable.numberOfRows {
            if let controller = questionsTable.rowController(at: index) as? QuestionRowController {
                var currentQuestion = ["question": "", "answer": infoDict[questions[index]]!]
                switch(questions[index]) {
                    case "foodDuration":
                        currentQuestion["question"] = "Food until?"
                        break
                    case "foodType":
                        currentQuestion["question"] = "Food type?"
                        break
                    case "stillFood":
                        currentQuestion["question"] = "Still food?"
                        break
                    default:
                        break
                }
                controller.question = currentQuestion
            }
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    // MARK: - UI Functions
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        // create suggestion array based on question selected
        var suggestionArray = [String]()
        switch(questions[rowIndex]) {
        case "foodDuration":
            suggestionArray = ["< 30 mins", "1 hour", "2 hours"]
            break
        case "foodType":
            suggestionArray = ["pizza", "noodles", "milkshakes", "sandwiches"]
            break
        case "stillFood":
            suggestionArray = ["Yes-a lot", "Some-going fast!", "None"]
            break
        default:
            break
        }
        
        presentTextInputController(withSuggestions: suggestionArray, allowedInputMode: WKTextInputMode.plain,
            completion: { completionArray in
                if let completionArray = completionArray {
                    if (completionArray.count > 0) {
                        if let controller = self.questionsTable.rowController(at: rowIndex) as? QuestionRowController {
                            // update dictionary storing all values
                            let currentQuestion = self.questions[rowIndex]
                            var currentInfoDict = self.locationInstanceDictionary["info"] as! [String : String]
                            currentInfoDict[currentQuestion] = completionArray[0] as? String
                            self.locationInstanceDictionary["info"] = currentInfoDict
                            
                            // update UI
                            controller.question = ["question": currentQuestion, "answer": (completionArray[0] as? String)!]
                        }
                    }
                }
        })
    }
    
    @IBAction func submitDataToParse() {
        watchSession.sendMessage(["command": "pushToParse", "value": locationInstanceDictionary],
            replyHandler: {response in
                guard let pushedSuccessfully = response["response"] as! Bool? else {return}
                
                if pushedSuccessfully {
                    self.dismiss()
                } else {
                    return
                }
            }, errorHandler: {error in
                print("Error in pushing data to Parse: \(error)")
        })
    }
    
    @available(watchOSApplicationExtension 2.2, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: NSError?) {
        
    }
}
