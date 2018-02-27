//
//  ForYouViewController.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 2/26/18.
//  Copyright © 2018 Kapil Garg. All rights reserved.
//

import UIKit

class ForYouViewController: UITableViewController {
    var tempData = [["info": "There is private seating (tables) to work at (near outlets and windows) at Coffee Lab.", "name": "coffee lab", "distance": "5 minutes"],
                    ["info": "There is private seating (tables) to work at (near outlets and windows) at Coffee Lab.There is private seating (tables) to work at (near outlets and windows) at Coffee Lab.There is private seating (tables) to work at (near outlets and windows) at Coffee Lab.There is private seating (tables) to work at (near outlets and windows) at Coffee Lab.", "name": "coffee lab", "distance": "5 minutes"],
                    ["info": "There is private seating (tables) to work at (near outlets and windows) at Coffee Lab.", "name": "coffee lab", "distance": "5 minutes"],
                    ["info": "There is private seating (tables) to work at (near outlets and windows) at Coffee Lab.", "name": "coffee lab", "distance": "5 minutes"],
                    ["info": "There is private seating (tables) to work at (near outlets and windows) at Coffee Lab.", "name": "coffee lab", "distance": "5 minutes"],
                    ["info": "There is private seating (tables) to work at (near outlets and windows) at Coffee Lab.", "name": "coffee lab", "distance": "5 minutes"],
                    ["info": "There is private seating (tables) to work at (near outlets and windows) at Coffee Lab.", "name": "coffee lab", "distance": "5 minutes"]]
    // MARK: Class Variables
    var tableData: [[String : String]] = []
    let appUserDefaults = UserDefaults.init(suiteName: appGroup)

    // MARK: - View Controller Functions
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18,
                                                                                                                      weight: UIFont.Weight.light),
                                                                        NSAttributedStringKey.foregroundColor: UIColor.white]
        self.navigationController?.navigationBar.tintColor = UIColor.white

        // create data array
        generateDataArray()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        var numberOfSections: Int = 0
        if self.tableData.count > 0 {
            tableView.separatorStyle = .singleLine
            numberOfSections = 1
            tableView.backgroundView = nil
        } else {
            let attrs = [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 40)]
            let attributedString = NSMutableAttributedString(string: "\u{1F62D}", attributes:attrs)
            let normalString = NSMutableAttributedString(string:
                "\n\nThere aren't any locations with information you may like currently. Check back later!")
            attributedString.append(normalString)

            let noDataLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            noDataLabel.attributedText = attributedString
            noDataLabel.textColor = UIColor.black
            noDataLabel.textAlignment = .center
            noDataLabel.numberOfLines = 0
            tableView.backgroundView = noDataLabel
            tableView.separatorStyle = .none
        }

        return numberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableData.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentData = self.tableData[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationInfoCell", for: indexPath) as! LocationInfoViewCell
        cell.locationInfo.text = currentData["info"]
        cell.locationName.text = currentData["name"]
        cell.locationDistance.text = currentData["distance"]! + " minutes away"
        cell.selectionStyle = .none

        return cell
    }

    // MARK: - Data Functions
    func generateDataArray() {
        // create new, unsorted tableData
        let monitoredHotspotDictionary = appUserDefaults?.dictionary(forKey: savedHotspotsRegionKey) as [String : AnyObject]? ?? [:]
        var newTableData: [[String : String]] = []

        for (_, info) in monitoredHotspotDictionary {
            let parsedInfo = info as! [String : AnyObject]
            let currNotificationCategory = parsedInfo["notificationCategory"] as! String
            let preferredInfo = parsedInfo["preferredInfo"] as! String

            if currNotificationCategory != "enroute" && preferredInfo != "" {
                let currLat = parsedInfo["latitude"] as! Double
                let currLng = parsedInfo["longitude"] as! Double
                let locationName = parsedInfo["locationName"] as! String

                let lastLocation = MyPretracker.sharedManager.currentLocation!
                let monitorLocation = CLLocation(latitude: currLat, longitude: currLng)
                let distanceToLocation = lastLocation.distance(from: monitorLocation)
                let timeToLocation = Int(distanceToLocation / 84.0) // approximate walking speed = 1.4 m/s * 60s/min = 84 m/min

                let currentData: [String : String] = [
                    "info": preferredInfo,
                    "name": locationName,
                    "distance": String(timeToLocation)
                ]
                newTableData.append(currentData)
            }
        }

        // sort tableData and assign to class variable
        self.tableData = newTableData.sorted {
            guard let s1 = Int($0["distance"]!), let s2 = Int($1["distance"]!) else {
                return false
            }

            return s1 < s2
        }
    }
}
