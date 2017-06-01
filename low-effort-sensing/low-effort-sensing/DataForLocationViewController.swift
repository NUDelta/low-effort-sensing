//
//  DataForLocationViewController.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 5/28/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import Foundation
import Parse

class DataForLocationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // MARK: - Class Variables
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var locationCategory: UILabel!
    @IBOutlet weak var distanceToLocationLabel: UILabel!
    @IBOutlet weak var locationInformationMessage: UILabel!
    
    struct LocationData {
        var firstRowLabel: String
        var secondRowLabel: String
        var initials: String
        var timestamp: String
        var vendorId: String
    }
    
    var tableData: [LocationData] = []
    var currentHotspot: [String : AnyObject] = [:]
    var distanceToHotspot: String = ""
    let colors: [UIColor] = [UIColor(hue: 0.8639, saturation: 0.76, brightness: 0.73, alpha: 1.0),
                             UIColor(hue: 0.7444, saturation: 0.64, brightness: 0.66, alpha: 1.0),
                             UIColor(hue: 0.5194, saturation: 0.46, brightness: 0.45, alpha: 1.0),
                             UIColor(hue: 0.0028, saturation: 0.89, brightness: 0.76, alpha: 1.0),
                             UIColor(hue: 0.3333, saturation: 1, brightness: 0.51, alpha: 1.0)]
    
    // MARK: - View Controller Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup table view
        tableView.dataSource = self
        tableView.delegate = self
        
        // set preliminary text
        let tag = self.currentHotspot["tag"] as! String
        let locationCommonName = self.currentHotspot["locationCommonName"] as! String
        let scaffoldedMessage = self.currentHotspot["scaffoldedMessage"] as! String
        
        if locationCommonName == "" {
            locationCategory.text = createTitleFromTag(tag)
        } else {
            locationCategory.text = locationCommonName
        }

        // special case: free/sold food 
        if tag == "food" {
            locationCategory.text = "Free/Sold Food"
        }
        
        distanceToLocationLabel.text = self.distanceToHotspot + " from current location"
        locationInformationMessage.text = scaffoldedMessage
        locationInformationMessage.sizeToFit()
        
        locationCategory.adjustsFontSizeToFitWidth = true
        locationCategory.minimumScaleFactor = 0.5
        distanceToLocationLabel.adjustsFontSizeToFitWidth = true
        distanceToLocationLabel.minimumScaleFactor = 0.5
        locationInformationMessage.adjustsFontSizeToFitWidth = true
        locationInformationMessage.minimumScaleFactor = 0.5
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Data Fetching and Formatting Functions
    func updateClassVariables(_ hotspot: [String : AnyObject], distance: String) {
        self.currentHotspot = hotspot
        self.distanceToHotspot = distance
    }
    
    func computeColor(_ initials: String) -> UIColor {
        let initialCode = initials.asciiArray.reduce(0, +)
        let colorCode = Int(initialCode) % self.colors.count
        return self.colors[colorCode]
    }
    
    func retrieveAndDrawData(_ hotspotId: String) {
        // fetch data
//        PFCloud.callFunction(inBackground: "fetchMapDataView",
//                             withParameters: ["hotspotId": hotspotId],
//                             block: ({ (foundObjs: Any?, error: Error?) -> Void in
//                                if error == nil {
//                                    // parse response
//                                    if let foundObjs = foundObjs as? [AnyObject] {
//                                        
//                                        // update table data
//                                        let answers = foundObjs
//                                        self.tableData = []
//                                        
//                                        for object in answers {
//                                            if let object = object as? [String : Any?] {
//                                                // convert objects
//                                                let question = self.getQuestionForKey(object["question"] as! String,
//                                                                                 tag: self.currentHotspot["tag"] as! String)
//                                                let answer = self.getAnswerForKey(object["question"] as! String)
//                                                let initials = object["initials"] as! String
//                                                let vendorId = object["vendorId"] as! String
//                                                
//                                                let date = Date(timeIntervalSince1970: TimeInterval(object["timestamp"] as! Int))
//                                                let dateFormatter = DateFormatter()
//                                                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//                                                let dateString = dateFormatter.string(from: date as Date)
//                                                
//                                                // create LocationData object and add to data
//                                                let currentRow = LocationData(firstRowLabel: question,
//                                                                              secondRowLabel: answer,
//                                                                              initials: initials,
//                                                                              timestamp: dateString,
//                                                                              vendorId: vendorId)
//                                                self.tableData.append(currentRow)
//                                            }
//                                        }
//                                        
//                                        // setup table view
//                                        self.refreshTableView()
//                                    }
//                                } else {
//                                    print("Error in retrieving location data from Parse: \(String(describing: error)). Trying again.")
//                                    self.retrieveAndDrawData(hotspotId)
//                                }
//                             }))
    }
    
    func getQuestionForKey(_ questionKey: String, tag: String) -> String {
        var questionDictionary: [String : String] = [:]
        
        switch tag {
        case "food":
            questionDictionary = foodKeyToQuestion
            break
        case "queue":
            questionDictionary = queueKeyToQuestion
            break
        case "space":
            questionDictionary = spaceKeyToQuestion
            break
        case "surprising":
            questionDictionary = surprisingKeyToQuestion
            break
        case "guestevent":
            questionDictionary = guestEventKeyToQuestion
            break
        case "dtrdonut":
            questionDictionary = dtrDonutKeyToQuestion
            break
        case "windowdrawing":
            questionDictionary = windowDrawingKeyToQuestion
            break
        default:
            break
        }
        
        return questionDictionary[questionKey]!
    }
    
    func getAnswerForKey(_ answerKey: String) -> String {
        let info = self.currentHotspot["info"] as! [String : String]
        return info[answerKey]!
    }
    
    func createTitleFromTag(_ tag: String) -> String {
        switch tag {
        case "food":
            return "Free/Sold Food"
//        case "queue":
//            return "How Long is the Line?"
//        case "space":
//            return "How Busy is the Space?"
//        case "surprising":
//            return "Something Surprising is Happening!"
//        case "guestevent":
//            return "Guest Event Happening"
//        case "dtrdonut":
//            return "Donuts for DTR!"
//        case "windowdrawing":
//            return "What's on the windows?"
        default:
            return ""
        }
    }
    
    // MARK: - Table View Functions
    func refreshTableView() {
        DispatchQueue.main.async{
            self.tableView.reloadData()
            return
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationDataCellPrototype") as! LocationDataCell
        cell.questionLabel.text = tableData[(indexPath as NSIndexPath).row].firstRowLabel
        cell.answerLabel.text = tableData[(indexPath as NSIndexPath).row].secondRowLabel
        cell.timestampLabel.text = tableData[(indexPath as NSIndexPath).row].timestamp
        cell.isUserInteractionEnabled = false
        
        // set image
        let initialLabel = UILabel()
        initialLabel.frame.size = CGSize(width: cell.userImageLabel.frame.size.width,
                                         height: cell.userImageLabel.frame.size.height)
        initialLabel.textColor = UIColor.white
        initialLabel.text = tableData[(indexPath as NSIndexPath).row].initials
        initialLabel.font = UIFont(name: initialLabel.font.fontName, size: 36)
        initialLabel.textAlignment = NSTextAlignment.center
        initialLabel.backgroundColor = self.computeColor(tableData[(indexPath as NSIndexPath).row].initials)
        initialLabel.layer.cornerRadius = cell.userImageLabel.frame.size.width / 2
        initialLabel.frame = initialLabel.frame.integral
        
        UIGraphicsBeginImageContext(initialLabel.frame.size)
        initialLabel.layer.render(in: UIGraphicsGetCurrentContext()!)
        cell.userImageLabel.image = UIGraphicsGetImageFromCurrentImageContext()
        cell.userImageLabel.layer.cornerRadius = cell.userImageLabel.frame.size.width / 2
        cell.userImageLabel.clipsToBounds = true;
        cell.userImageLabel.frame = initialLabel.frame.integral
        UIGraphicsEndImageContext()
        
        
        // dynamic font sizing
        cell.questionLabel.adjustsFontSizeToFitWidth = true
        cell.questionLabel.minimumScaleFactor = 0.5
        
        cell.answerLabel.adjustsFontSizeToFitWidth = true
        cell.answerLabel.minimumScaleFactor = 0.5
        
        cell.timestampLabel.adjustsFontSizeToFitWidth = true
        cell.timestampLabel.minimumScaleFactor = 0.5
        
        return cell
    }
    
    @IBAction func returnToMap(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
}
