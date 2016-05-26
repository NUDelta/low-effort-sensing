//
//  HomeScreenViewController.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 5/23/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import Foundation
import Parse
import MapKit
import CoreLocation

class HomeScreenViewController: UIViewController {
    // MARK: Class Variables
    @IBOutlet weak var mapView: MKMapView!
    let regionRadius: CLLocationDistance = 1000
    
    @IBOutlet weak var nearbyButton: UIButton!
    @IBOutlet weak var myLocationsButton: UIButton!
    var showingNearby: Bool = Bool()
    let charcoalGreyColor: UIColor = UIColor.init(red: 116.0 / 255.0, green: 125.0 / 255.0, blue: 125.0 / 255.0, alpha: 1.0)
    
    let appUserDefaults = NSUserDefaults.init(suiteName: appGroup)
    
    // MARK: Class Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        // setup map view
        mapView.showsUserLocation = true
    }
    
    override func viewDidAppear(animated: Bool) {
        // set initial location to current user location
        let currentLocation = MyPretracker.sharedManager.locationManager?.location?.coordinate
        var initialLocation: CLLocation = CLLocation()
        
        if let currentLocation = currentLocation {
            initialLocation = CLLocation(latitude: currentLocation.latitude,
                                         longitude: currentLocation.longitude)
        } else {
            initialLocation = CLLocation(latitude: 42.057034, longitude: -87.677132) // center around tech for default location
        }
        centerMapOnLocation(initialLocation)
        
        // add pins for marked locations
        let monitoredHotspotDictionary = self.appUserDefaults?.dictionaryForKey(savedHotspotsRegionKey) ?? Dictionary()
        drawNewAnnotations(monitoredHotspotDictionary)
        
        // set nearby shown
        showingNearby = true
        nearbyButton.backgroundColor = charcoalGreyColor
        nearbyButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        
        myLocationsButton.backgroundColor = UIColor.whiteColor()
        myLocationsButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func addAnnotationsForDictionary(location: [String : AnyObject]) {
        let lastLocation = MyPretracker.sharedManager.locationManager?.location
        let annotationLocation = CLLocation.init(coordinate: CLLocationCoordinate2D(latitude: location["latitude"] as! Double, longitude: location["longitude"] as! Double), altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, course: 0.0, speed: 0.0, timestamp: NSDate.init())
        
        let distanceToLocation = lastLocation!.distanceFromLocation(annotationLocation)
        let distanceInFeet = Int(distanceToLocation * 3.28084)
        let tag = location["tag"] as! String
        
        let newLocation = MarkedLocation(title: createTitleFromTag(tag),
                                         locationName: "\(distanceInFeet) feet away",
                                         discipline: tag,
                                         coordinate: CLLocationCoordinate2D(latitude: location["latitude"] as! Double, longitude: location["longitude"] as! Double))
        mapView.addAnnotation(newLocation)
    }
    
    func createTitleFromTag(tag: String) -> String{
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
    
    func drawNewAnnotations(locations: [String : AnyObject]) {
        // clear all existing annotations
        mapView.removeAnnotations(mapView.annotations)
        
        // draw new annotations
        for (_, info) in locations {
            addAnnotationsForDictionary(info as! [String : AnyObject])
        }
    }
    
    func getAndDrawMyMarkedLocations() {
        let query = PFQuery(className: "hotspot")
        query.whereKey("vendorId", equalTo: vendorId)
        query.findObjectsInBackgroundWithBlock {
            (objects: [PFObject]?, error: NSError?) -> Void in
            
            if error == nil {
                if let objects = objects {
                    var monitoredHotspotDictionary = [String : AnyObject]()
                    for object in objects {
                        let currGeopoint = object["location"] as! PFGeoPoint
                        let currLat = currGeopoint.latitude
                        let currLong = currGeopoint.longitude
                        let id = object.objectId!
                        
                        // Add data to user defaults
                        var unwrappedEntry = [String : AnyObject]()
                        unwrappedEntry["latitude"] = currLat
                        unwrappedEntry["longitude"] = currLong
                        unwrappedEntry["id"] = id
                        unwrappedEntry["tag"] = object["tag"]
                        let info : [String : AnyObject]? = object["info"] as? [String : AnyObject]
                        unwrappedEntry["info"] = info
                        
                        monitoredHotspotDictionary[object.objectId!] = unwrappedEntry
                    }
                    self.appUserDefaults?.setObject(monitoredHotspotDictionary, forKey: myHotspotsRegionKey)
                    self.appUserDefaults?.synchronize()
                    
                    // add annotations onto map view
                    self.drawNewAnnotations(monitoredHotspotDictionary)
                }
            } else {
                // Log details of the failure
                print("Error: \(error!) \(error!.userInfo)")
            }
        }
    }
    
    @IBAction func toggleNearbyPlaces(sender: AnyObject) {
        if !showingNearby {
            // draw new annotations
            let monitoredHotspotDictionary = self.appUserDefaults?.dictionaryForKey(savedHotspotsRegionKey) ?? Dictionary()
            drawNewAnnotations(monitoredHotspotDictionary)
            
            // update buttons
            showingNearby = true
            nearbyButton.backgroundColor = charcoalGreyColor
            nearbyButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            
            myLocationsButton.backgroundColor = UIColor.whiteColor()
            myLocationsButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
        }
    }
    
    @IBAction func toggleLocationsMarked(sender: AnyObject) {
        if showingNearby {
            // draw new annotations
            getAndDrawMyMarkedLocations()
            
            // update buttons
            showingNearby = false
            myLocationsButton.backgroundColor = charcoalGreyColor
            myLocationsButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            
            nearbyButton.backgroundColor = UIColor.whiteColor()
            nearbyButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
        }
    }
}
