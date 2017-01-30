//
//  UserProfileViewController.swift
//  low-effort-sensing
//
//  Copyright © 2017 Kapil Garg. All rights reserved.
//

import Foundation
import Parse
import MapKit

class UserProfileViewController: UIViewController, MKMapViewDelegate, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var contributionLabel: UILabel!
    @IBOutlet weak var markedLocationLabel: UILabel!
    @IBOutlet weak var peopleHelpedLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var userProfileImage: UIImageView!
    @IBOutlet weak var contributionMap: MKMapView!
    @IBOutlet weak var contributionTableView: UITableView!
    
    let regionRadius: CLLocationDistance = 1000
    let appUserDefaults = UserDefaults.init(suiteName: appGroup)
    let colors: [UIColor] = [UIColor(hue: 0.8639, saturation: 0.76, brightness: 0.73, alpha: 1.0),
                             UIColor(hue: 0.7444, saturation: 0.64, brightness: 0.66, alpha: 1.0),
                             UIColor(hue: 0.5194, saturation: 0.46, brightness: 0.45, alpha: 1.0),
                             UIColor(hue: 0.0028, saturation: 0.89, brightness: 0.76, alpha: 1.0),
                             UIColor(hue: 0.3333, saturation: 1, brightness: 0.51, alpha: 1.0)]
    let green: UIColor = UIColor(hue: 0.3389, saturation: 0.56, brightness: 0.68, alpha: 1.0)
    let red: UIColor = UIColor(hue: 0.0111, saturation: 0.77, brightness: 0.95, alpha: 1.0)
    
    struct ContributionData {
        var category: String
        var timestamp: String
        var contributionType: String
        var latitude: Double
        var longitude: Double
        var hotspotId: String
    }
    var tableData: [ContributionData] = []
    
    // MARK: Class Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup map view
        contributionMap.delegate = self
        contributionMap.showsUserLocation = true
        contributionMap.userTrackingMode = MKUserTrackingMode.follow
        
        // setup table view
        contributionTableView.dataSource = self
        contributionTableView.delegate = self
        
        // retrieve data and display
        retrieveAndDrawData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setTextElements(_ username: String, contributions: String, markedLocations: String, peopleHelped: String) {
        usernameLabel.text = username
        contributionLabel.text = contributions
        markedLocationLabel.text = markedLocations
        peopleHelpedLabel.text = peopleHelped
    }
    
    func setUserImage(_ initials: String) {
        print(initials)
        let initialLabel = UILabel()
        initialLabel.frame.size = CGSize(width: userProfileImage.frame.size.width,
                                         height: userProfileImage.frame.size.height)
        initialLabel.textColor = UIColor.white
        initialLabel.text = initials
        initialLabel.font = UIFont(name: initialLabel.font.fontName, size: 42)
        initialLabel.textAlignment = NSTextAlignment.center
        initialLabel.backgroundColor = self.colors[Int(arc4random_uniform(UInt32(self.colors.count)))]
        initialLabel.layer.cornerRadius = userProfileImage.frame.size.width / 2
        initialLabel.frame = initialLabel.frame.integral
        
        UIGraphicsBeginImageContext(initialLabel.frame.size)
        initialLabel.layer.render(in: UIGraphicsGetCurrentContext()!)
        userProfileImage.image = UIGraphicsGetImageFromCurrentImageContext()
        userProfileImage.layer.cornerRadius = userProfileImage.frame.size.width / 2
        userProfileImage.clipsToBounds = true
        userProfileImage.frame = initialLabel.frame.integral
        UIGraphicsEndImageContext()
    }
    
    func centerMapOnLocation(_ location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        contributionMap.setRegion(coordinateRegion, animated: true)
    }
    
    func createTitleFromTag(_ tag: String) -> String{
        switch tag {
        case "food":
            return "Free/Sold Food"
        case "queue":
            return "How Long is the Line?"
        case "space":
            return "How Busy is the Space?"
        case "surprising":
            return "Something Surprising is Happening!"
        case "guestevent":
            return "Guest Event Happening"
        case "dtrdonut":
            return "Donuts for DTR!"
        case "windowdrawing":
            return "What's on the windows?"
        default:
            return ""
        }
    }
    
    func drawNewAnnotations(_ locations: [ContributionData]) {
        // clear all existing annotations
        contributionMap.removeAnnotations(contributionMap.annotations)
        
        // draw new annotations
        for object in locations {
            let newLocation = MarkedLocation(title: object.category,
                                             locationName: object.timestamp,
                                             discipline: object.contributionType,
                                             coordinate:  CLLocationCoordinate2D(latitude: object.latitude,
                                                                                 longitude: object.longitude),
                                             hotspotId: object.hotspotId)
            
            contributionMap.addAnnotation(newLocation)
        }
    }
    
    func retrieveAndDrawData() {
        // fetch data
        PFCloud.callFunction(inBackground: "fetchUserProfileData",
                             withParameters: ["vendorId": vendorId],
                             block: ({ (foundObjs: Any?, error: Error?) -> Void in
                                if error == nil {
                                    // parse response
                                    if let foundObjs = foundObjs as? [String:Any] {
                                        // draw test elements and image
                                        self.setTextElements(foundObjs["username"] as! String,
                                                        contributions: String(foundObjs["contributionCount"] as! Int),
                                                        markedLocations: String(foundObjs["markedLocationCount"] as! Int),
                                                        peopleHelped: String(foundObjs["peopleHelped"] as! Int))
                                        self.setUserImage(foundObjs["initials"] as! String)
                                        
                                        // get location data
                                        let contributionArray = foundObjs["contributionLocations"] as! [AnyObject]
                                        self.tableData = []
                                        
                                        for object in contributionArray {
                                            if let object = object as? [String : Any?] {
                                                // convert objects
                                                let category = self.createTitleFromTag(object["category"] as! String)
                                                let contributionType = object["contributionType"] as! String
                                                let latitude = object["latitude"] as! Double
                                                let longitude = object["longitude"] as! Double
                                                let hotspotId = object["hotspotId"] as! String
                                                
                                                let date = Date(timeIntervalSince1970: TimeInterval(object["timestamp"] as! Int))
                                                let dateFormatter = DateFormatter()
                                                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                                                let dateString = dateFormatter.string(from: date as Date)
                                                
                                                // create ContributionData object and add to data
                                                let currentRow = ContributionData(category: category, timestamp: dateString, contributionType: contributionType, latitude: latitude, longitude: longitude, hotspotId: hotspotId)
                                                self.tableData.append(currentRow)
                                            }
                                        }
                                        
                                        // setup table view
                                        DispatchQueue.main.async{
                                            self.contributionTableView.reloadData()
                                        }
                                        
                                        // setup map view
                                        self.drawNewAnnotations(self.tableData)
                                    }
                                } else {
                                    print("Error in retrieving user profile from Parse: \(error). Trying again.")
                                    self.retrieveAndDrawData()
                                }
                             }))
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? MarkedLocation {
            let identifier = "pin"
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                as? MKPinAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
//                view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure) as UIView
            }
            
            // set color
            if (annotation.discipline == "marked") {
                view.pinTintColor = red
            } else {
                view.pinTintColor = green
            }
            return view
        }
        return nil
    }
    
    // TODO: connect this with the new contribution view
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContributionDataCellPrototype") as! ContributionDataCell
        cell.categoryLabel.text = tableData[(indexPath as NSIndexPath).row].category
        cell.dateLabel.text = tableData[(indexPath as NSIndexPath).row].timestamp
        
        if (tableData[(indexPath as NSIndexPath).row].contributionType == "marked") {
            cell.contributionImage.image = UIImage(named: "AddLocation")
            cell.contributionImage.image = cell.contributionImage.image!.withRenderingMode(.alwaysTemplate)
            cell.contributionImage.tintColor = self.red
        } else {
            cell.contributionImage.image = UIImage(named: "RespondNotification")
            cell.contributionImage.image = cell.contributionImage.image!.withRenderingMode(.alwaysTemplate)
            cell.contributionImage.tintColor = self.green
        }
        cell.isUserInteractionEnabled = false
        
        // dynamic font sizing
        cell.categoryLabel.adjustsFontSizeToFitWidth = true
        cell.categoryLabel.minimumScaleFactor = 0.5
        
        cell.dateLabel.adjustsFontSizeToFitWidth = true
        cell.dateLabel.minimumScaleFactor = 0.5

        return cell
    }
    
    @IBAction func backToMap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

