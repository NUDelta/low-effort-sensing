//
//  NameViewController.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 5/22/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import Foundation
import Parse

class LoginViewController: UIViewController {
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    
    // MARK: Class Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func loginUser(_ sender: Any) {
        let userEmail = self.email.text
        let userPassword = self.password.text

        // attempt to login user, segue if possible
        if !(userEmail?.isEmpty)! && !(userPassword?.isEmpty)! {
            PFUser.logInWithUsername(inBackground: userEmail!, password: userPassword!, block: {(user, error) -> Void in
                if error == nil {
                    print("user successfully logged in")

                    // save last login time
                    let currentUser = PFUser.current()
                    if let currentUser = currentUser {
                        let date = Date()
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        let currentDateString = dateFormatter.string(from: date)
                        
                        currentUser["lastLoggedIn"] = currentDateString
                        currentUser.saveInBackground(block: ({ (success: Bool, error: Error?) -> Void in
                            if (!success) {
                                print("Error in saving new location to Parse: \(String(describing: error)). Attempting eventually.")
                                currentUser.saveEventually()
                            }
                        }))
                    }

                    self.performSegue(withIdentifier: "LoginSegue", sender: self)
                } else {
                    print("error in logging in: \(error!.localizedDescription)")

                    let alert = UIAlertController(title: "Login Failed",
                                                  message: "Invalid email/password. Please verify your email and password.",
                                                  preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "ok", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            })
        } else {
            let alert = UIAlertController(title: "Login Failed",
                                          message: "Email and Password must both be filled.",
                                          preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}
