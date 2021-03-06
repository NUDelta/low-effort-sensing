//
//  QuestionRowController.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 2/26/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import WatchKit

class QuestionRowController: NSObject {
    // MARK: Class Variables
    @IBOutlet var separator: WKInterfaceSeparator!
    @IBOutlet var questionLabel: WKInterfaceLabel!
    
    // MARK: Class Functions
    var question: Dictionary<String, String>? {
        didSet {
            if let question = question {
                if question["answer"] == "" {
                    if let newQuestionLabel = question["question"] {
                        questionLabel.setText(newQuestionLabel)
                        separator.setColor(UIColor.red)
                    }
                } else {
                    if let newQuestionLabel = question["answer"] {
                        questionLabel.setText(newQuestionLabel)
                        separator.setColor(UIColor.green)
                    }
                }
            }
        }
    }
}
