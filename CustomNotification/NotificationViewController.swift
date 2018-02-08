//
//  NotificationViewController.swift
//  CustomNotification
//
//  Created by Kapil Garg on 9/14/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet var label: UILabel?
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
    }
    
    func didReceive(_ notification: UNNotification) {
        print("custom notification called")
        print(notification.request.content)
//        self.label?.text = notification.request.content.body
    }

}
