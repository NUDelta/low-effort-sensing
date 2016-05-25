//
//  CompletionViewController.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 5/22/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import Foundation
import Parse

class CompletionViewController: UIViewController {
    let appUserDefaults = NSUserDefaults.init(suiteName: appGroup)
    
    // MARK: Class Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "CompletionSegue") {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "launchedBefore")
            
            let newUser = PFObject(className: "user", dictionary: appUserDefaults?.dictionaryForKey("welcomeData"))
            newUser.saveInBackground()
        }
    }
}