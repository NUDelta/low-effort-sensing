//
//  GetInformationInterfaceController.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 2/26/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import WatchKit
import Foundation


class GetInformationInterfaceController: WKInterfaceController {
    
    // MARK: Attributes
    @IBOutlet var questionsTable: WKInterfaceTable!
    var questions = ["", "Question 2", "Question 3"]
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        questionsTable.setNumberOfRows(questions.count, withRowType: "QuestionRow")
        for index in 0..<questionsTable.numberOfRows {
            if let controller = questionsTable.rowControllerAtIndex(index) as? QuestionRowController {
                let currentQuestion = ["question": "Food left?", "answer": questions[index]]
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

}
