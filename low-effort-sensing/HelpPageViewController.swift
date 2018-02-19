//
//  HelpPageViewController.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 2/8/17.
//  Copyright © 2017 Kapil Garg. All rights reserved.
//

import Foundation
import Parse

class HelpPageViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18,
                                                                                                                      weight: UIFont.Weight.light),
                                                                        NSAttributedStringKey.foregroundColor: UIColor.white]
        self.navigationController?.navigationBar.tintColor = UIColor.white
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func logoutFromLES(_ sender: Any) {
        // confirm if user wants to be logged out
        let alert = UIAlertController(title: "Logging Out",
                                      message: "Are you sure you want to log out from LES?",
                                      preferredStyle: UIAlertControllerStyle.alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { (result : UIAlertAction) -> Void in
            print("User logout canceled")
        }
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
            print("Logging user out and redirecting to signup")

            // logout user
            PFUser.logOut() // TODO: log logout events in DB

            // redirect to signup view
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let signupViewController = mainStoryboard.instantiateViewController(withIdentifier: "WelcomeViewController") as UIViewController

            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.window = UIWindow(frame: UIScreen.main.bounds)
            appDelegate.window?.rootViewController = signupViewController
            appDelegate.window?.makeKeyAndVisible()
        }

        alert.addAction(cancelAction)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
}
