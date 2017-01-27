//
//  UserProfileViewController.swift
//  low-effort-sensing
//
//  Copyright © 2017 Kapil Garg. All rights reserved.
//

import Foundation
import Parse
import MapKit
import ChameleonFramework

class UserProfileViewController: UIViewController, MKMapViewDelegate {
    @IBOutlet weak var contributionLabel: UILabel!
    @IBOutlet weak var markedLocationLabel: UILabel!
    @IBOutlet weak var peopleHelpedLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var userProfileImage: UIImageView!
    @IBOutlet weak var contributionMap: MKMapView!
    
    let regionRadius: CLLocationDistance = 1000
    let appUserDefaults = UserDefaults.init(suiteName: appGroup)
    
    // MARK: Class Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        // setup map view
        contributionMap.delegate = self
        contributionMap.showsUserLocation = true
        contributionMap.userTrackingMode = MKUserTrackingMode.follow
    }
    
    override func viewDidAppear(_ animated: Bool) {
        contributionLabel.text = "hello"
        
        let lblNameInitialize = UILabel()
        lblNameInitialize.frame.size = CGSize(width: 100.0, height: 100.0)
        lblNameInitialize.textColor = UIColor.white
        lblNameInitialize.text = "KG"
        lblNameInitialize.font = UIFont(name: lblNameInitialize.font.fontName, size: 36)
        lblNameInitialize.textAlignment = NSTextAlignment.center
        lblNameInitialize.backgroundColor = UIColor.randomFlat()
        lblNameInitialize.layer.cornerRadius = 50.0
        
        UIGraphicsBeginImageContext(lblNameInitialize.frame.size)
        lblNameInitialize.layer.render(in: UIGraphicsGetCurrentContext()!)
        userProfileImage.image = UIGraphicsGetImageFromCurrentImageContext()
        userProfileImage.layer.cornerRadius = userProfileImage.frame.size.width / 2;
        userProfileImage.clipsToBounds = true;
        UIGraphicsEndImageContext()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func centerMapOnLocation(_ location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        contributionMap.setRegion(coordinateRegion, animated: true)
    }
    
    func createTitleFromTag(_ tag: String) -> String{
        switch tag {
        case "food":
            return "Free/Sold Food Here"
        case "queue":
            return "How Long is the Line Here?"
        case "space":
            return "How Busy is the Space Here?"
        case "surprising":
            return "Something Surprising is Happening Here!"
        default:
            return ""
        }
    }
    
    func drawNewAnnotations(_ locations: [String : AnyObject]) {
        // clear all existing annotations
        contributionMap.removeAnnotations(contributionMap.annotations)
        
        // draw new annotations
        
    }
    
    func getAndDrawMyMarkedLocations() {
        let query = PFQuery(className: "hotspot")
        query.whereKey("vendorId", equalTo: vendorId)
        query.findObjectsInBackground(block: {(objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    var monitoredHotspotDictionary = [String : AnyObject]()
                    
                    for object in objects {
                        let currGeopoint = object["location"] as! PFGeoPoint
                        let currLat = currGeopoint.latitude
                        let currLong = currGeopoint.longitude
                        let id = object.objectId!
                        
                        let info : [String : AnyObject]? = object["info"] as? [String : AnyObject]
                        
                        // Add data to user defaults
                        var unwrappedEntry = [String : AnyObject]()
                        unwrappedEntry["id"] = id as AnyObject
                        unwrappedEntry["vendorId"] = (object["vendorId"] as! String) as AnyObject
                        unwrappedEntry["tag"] = (object["tag"] as! String) as AnyObject
                        unwrappedEntry["info"] = info as AnyObject
                        unwrappedEntry["latitude"] = currLat as AnyObject
                        unwrappedEntry["longitude"] = currLong as AnyObject
                        unwrappedEntry["archived"] = (object["archived"] as? Bool) as AnyObject
                        unwrappedEntry["timestampCreated"] = (object["timestampCreated"] as? Int) as AnyObject
                        unwrappedEntry["gmtOffset"] = (object["gmtOffset"] as? Int) as AnyObject
                        unwrappedEntry["timestampLastUpdate"] = (object["timestampLastUpdate"] as? Int) as AnyObject
                        unwrappedEntry["submissionMethod"] = (object["submissionMethod"] as? String) as AnyObject
                        unwrappedEntry["locationCommonName"] = (object["locationCommonName"] as? String) as AnyObject
                        
                        monitoredHotspotDictionary[id] = unwrappedEntry as AnyObject
                    }
                    
                    self.appUserDefaults?.set(monitoredHotspotDictionary, forKey: myHotspotsRegionKey)
                    self.appUserDefaults?.synchronize()
                    
                    // add annotations onto map view
                    self.drawNewAnnotations(monitoredHotspotDictionary)
                }
            } else {
                // Log details of the failure
                print("Error: \(error!) \(error.debugDescription)")
            }
        })
    }
    
    func contributionMap(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
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
                view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure) as UIView
            }
            return view
        }
        return nil
    }
    
    // TODO: connect this with the new contribution view
    func contributionMap(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
    }
    
}

