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
    @IBOutlet weak var viewLabel: UILabel!
    
    let appUserDefaults = UserDefaults.init(suiteName: appGroup)

    // MARK: Class Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        self.viewLabel.adjustsFontSizeToFitWidth = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
//        if (segue.identifier == "CompletionSegue") {
//            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "launchedBefore")
//            
//            let newUser = PFObject(className: "user", dictionary: appUserDefaults?.dictionaryForKey("welcomeData"))
//            newUser.saveInBackground()
//            
//            // add view to hierarchy
//            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//            let homeViewController: HomeScreenViewController = mainStoryboard.instantiateViewControllerWithIdentifier("HomeScreenViewController") as! HomeScreenViewController
//            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
//            appDelegate.window = UIWindow(frame: UIScreen.mainScreen().bounds)
//            
//            appDelegate.window?.rootViewController = homeViewController
//            appDelegate.window?.makeKeyAndVisible()
//        }
//    }
    
    @IBAction func setupComplete(_ sender: AnyObject) {
        UserDefaults.standard.set(true, forKey: "launchedBefore")
        
        let newUser = PFObject(className: "user", dictionary: appUserDefaults?.dictionary(forKey: "welcomeData"))
        newUser.saveInBackground()
        
        // add view to hierarchy
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let homeViewController: HomeScreenViewController = mainStoryboard.instantiateViewController(withIdentifier: "HomeScreenViewController") as! HomeScreenViewController
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window = UIWindow(frame: UIScreen.main.bounds)
        
        appDelegate.window?.rootViewController = homeViewController
        appDelegate.window?.makeKeyAndVisible()
    }
}
