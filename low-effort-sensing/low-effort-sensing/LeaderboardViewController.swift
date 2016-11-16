//
//  LeaderboardViewController.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 11/16/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import Foundation

class LeaderboardViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    struct LeaderboardData {
        var rankingLabel: String
        var usernameLabel: String
        var scoreLabel: String
    }
    
    var tableData: [LeaderboardData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadDataIntoArray()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LeaderboardDataCellPrototype") as! LeaderboardDataCell
        cell.rankingLabel.text = tableData[(indexPath as NSIndexPath).row].rankingLabel
        cell.usernameLabel.text = tableData[(indexPath as NSIndexPath).row].usernameLabel
        cell.scoreLabel.text = tableData[(indexPath as NSIndexPath).row].scoreLabel
        cell.isUserInteractionEnabled = false
        
        // dyanmic font sizing
        cell.rankingLabel.adjustsFontSizeToFitWidth = true
        cell.rankingLabel.minimumScaleFactor = 0.5
        
        cell.usernameLabel.adjustsFontSizeToFitWidth = true
        cell.usernameLabel.minimumScaleFactor = 0.5
        
        cell.scoreLabel.adjustsFontSizeToFitWidth = true
        cell.scoreLabel.minimumScaleFactor = 0.5
        return cell
    }
    
    func loadDataIntoArray() {
        // set value for first row
        let firstRow = LeaderboardData(rankingLabel: "Ranking", usernameLabel: "Username", scoreLabel: "Score")
        tableData.append(firstRow)
    }
    
    @IBAction func returnToMap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
    
