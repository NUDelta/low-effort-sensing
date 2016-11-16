//
//  LeaderboardViewController.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 11/16/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import Foundation
import Parse

class LeaderboardViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    var tableData: [LeaderboardData] = []
    
    let charcoalGreyColor: UIColor = UIColor.init(red: 116.0 / 255.0, green: 125.0 / 255.0, blue: 125.0 / 255.0, alpha: 1.0)
    let goldColor: UIColor = UIColor.init(red: 255.0 / 255.0, green: 215.0 / 255.0, blue: 0.0 / 255.0, alpha: 1.0)
    let silverColor: UIColor = UIColor.init(red: 192.0 / 255.0, green: 192.0 / 255.0, blue: 192.0 / 255.0, alpha: 1.0)
    let bronzeColor: UIColor = UIColor.init(red: 205.0 / 255.0, green: 127.0 / 255.0, blue: 50.0 / 255.0, alpha: 1.0)
    
    struct LeaderboardData {
        var rankingLabel: String
        var usernameLabel: String
        var scoreLabel: String
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
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
        
        // special coloring for top 3 cells and 0th header cell
        switch indexPath.row {
        case 0:
            cell.backgroundColor = self.charcoalGreyColor
        case 1:
            cell.backgroundColor = self.goldColor
        case 2:
            cell.backgroundColor = self.silverColor
        case 3:
            cell.backgroundColor = self.bronzeColor
        default:
            cell.backgroundColor = UIColor.white
        }
        return cell
    }
    
    func loadDataIntoArray() {
        // clear out data
        tableData = []
        
        // set value for first row
        let firstRow = LeaderboardData(rankingLabel: "Ranking", usernameLabel: "Username", scoreLabel: "Score")
        tableData.append(firstRow)
        
        // get leaderboard rankings
        PFCloud.callFunction(inBackground: "rankingsByContribution",
                             withParameters: nil,
                             block: ({ (foundObjs: Any?, error: Error?) -> Void in
                                if error == nil {
                                    // parse response
                                    if let foundObjs = foundObjs {
                                        let foundObjsArray = foundObjs as! [AnyObject]
                                        var counter = 1
                                        
                                        for object in foundObjsArray {
                                            if let object = object as? [String : Any?] {
                                                let displayName = object["displayName"] as! String
                                                let totalScore = object["totalScore"] as! Int
                                                
                                                // Add data to tableData array
                                                let currentRow = LeaderboardData(rankingLabel: String(counter), usernameLabel: displayName, scoreLabel: String(totalScore))
                                                self.tableData.append(currentRow)
                                                counter += 1
                                            }
                                        }
                                        
                                        // reload table view
                                        DispatchQueue.main.async{
                                            self.tableView.reloadData()
                                        }
                                    }
                                } else {
                                    print("Error in retrieving leaderboard from Parse: \(error). Trying again.")
                                    self.loadDataIntoArray()
                                }
                             }))
    }
    
    @IBAction func returnToMap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
    
