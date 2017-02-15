//
//  HelpPageViewController.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 2/8/17.
//  Copyright © 2017 Kapil Garg. All rights reserved.
//

import Foundation

class HelpPageViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 18, weight: UIFontWeightLight),
                                                                        NSForegroundColorAttributeName: UIColor.white]
        self.navigationController?.navigationBar.tintColor = UIColor.white
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
