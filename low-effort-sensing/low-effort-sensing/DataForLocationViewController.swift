//
//  DataForLocationViewController.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 5/28/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import Foundation

class DataForLocationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    struct LocationData {
        var firstRowLabel: String
        var secondRowLabel: String
    }
    
    var tableData: [LocationData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("LocationDataCellPrototype") as! LocationDataCell
        cell.questionLabel.text = tableData[indexPath.row].firstRowLabel
        cell.answerLabel.text = tableData[indexPath.row].secondRowLabel
        cell.userInteractionEnabled = false
        
        // dyanmic font sizing
        cell.questionLabel.adjustsFontSizeToFitWidth = true
        cell.questionLabel.minimumScaleFactor = 0.5
        cell.answerLabel.adjustsFontSizeToFitWidth = true
        cell.answerLabel.minimumScaleFactor = 0.5
        return cell
    }
    
    func loadDataForHotspotDictionary(hotspotDictionary: [String : AnyObject], distance: String) {
        let tag = hotspotDictionary["tag"] as! String
        
        // set value for first row
        var firstRowLabelValue = ""
        let locationCommonName = hotspotDictionary["locationCommonName"] as! String
        if locationCommonName == "" {
            firstRowLabelValue = createTitleFromTag(tag)
        } else {
            if tag == "queue" {
                firstRowLabelValue = locationCommonName + " (line tracking)"
            } else if tag == "space" {
                firstRowLabelValue = locationCommonName + " (space tracking)"
            }
        }
        
        let firstRow = LocationData(firstRowLabel: firstRowLabelValue, secondRowLabel: distance + " from current location")
        tableData.append(firstRow)
        
        tableData = tableData + fillDataForQuestions(hotspotDictionary)
    }
    
    func createTitleFromTag(tag: String) -> String{
        switch tag {
            case "food":
                return "Information for Free/Sold Food"
            case "queue":
                return "Information for Line Tracking"
            case "space":
                return "Information for Space Tracking"
            case "surprising":
                return "Information for a Surprising Thing"
            default:
                return ""
        }
    }
    
    func fillDataForQuestions(hotspot: [String : AnyObject]) -> [LocationData] {
        let tag = hotspot["tag"] as! String
        let info = hotspot["info"] as! [String : String]
        var questionOrdering: [String] = []
        
        var filledData: [LocationData] = []
        var questionDictionary: [String : String] = [:]
        
        switch tag {
        case "food":
            questionOrdering = ["foodtype", "howmuchfood", "freeorsold", "forstudentgroup", "cost", "sellingreason"]
            questionDictionary = foodKeyToQuestion
            break
        case "queue":
            questionOrdering = ["linetime", "islonger", "isworthwaiting", "npeople"]
            questionDictionary = queueKeyToQuestion
            break
        case "space":
            questionOrdering = ["isavailable", "seatingtype", "seating near power", "iswifi", "manypeople", "loudness", "event"]
            questionDictionary = spaceKeyToQuestion
            break
        case "surprising":
            questionOrdering = ["whatshappening", "famefrom", "vehicles", "peopledoing"]
            questionDictionary = surprisingKeyToQuestion
            break
        default:
            break
        }
        
        // add data to table
        for questionKey in questionOrdering {
            let question = questionDictionary[questionKey]
            var questionAnswer: String = ""
            if info[questionKey]! == "" {
                questionAnswer = "Data has not been contributed yet"
            } else {
                questionAnswer = info[questionKey]!
            }
            
            let currentRow = LocationData(firstRowLabel: question!, secondRowLabel: questionAnswer)
            filledData.append(currentRow)
        }
        
        return filledData
    }
    
    @IBAction func returnToMap(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}