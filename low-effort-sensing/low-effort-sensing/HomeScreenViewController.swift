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


class HomeScreenViewController: UIViewController, MKMapViewDelegate {
    // MARK: Class Variables
    @IBOutlet weak var mapView: MKMapView!
    let regionRadius: CLLocationDistance = 1000
    
    @IBOutlet weak var nearbyButton: UIButton!
    @IBOutlet weak var myLocationsButton: UIButton!
    var showingNearby: Bool = Bool()
    let charcoalGreyColor: UIColor = UIColor.init(red: 116.0 / 255.0, green: 125.0 / 255.0, blue: 125.0 / 255.0, alpha: 1.0)
    
    let appUserDefaults = UserDefaults.init(suiteName: appGroup)
    
    // MARK: Class Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        // setup map view
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = MKUserTrackingMode.follow
        
        // make buttons resize 
        nearbyButton.titleLabel!.numberOfLines = 0
        nearbyButton.titleLabel!.adjustsFontSizeToFitWidth = true
        nearbyButton.titleLabel!.lineBreakMode = NSLineBreakMode.byClipping
        nearbyButton.titleLabel!.minimumScaleFactor = 0.5
        
        myLocationsButton.titleLabel!.numberOfLines = 0
        myLocationsButton.titleLabel!.adjustsFontSizeToFitWidth = true
        myLocationsButton.titleLabel!.lineBreakMode = NSLineBreakMode.byClipping
        myLocationsButton.titleLabel!.minimumScaleFactor = 0.5
        
        // check for changes in NSUserDefaults
        NotificationCenter.default.addObserver(self, selector: #selector(HomeScreenViewController.defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // add pins for marked locations
        let monitoredHotspotDictionary = self.appUserDefaults?.dictionary(forKey: savedHotspotsRegionKey) ?? Dictionary()
        drawNewAnnotations(monitoredHotspotDictionary as [String : AnyObject])
        
        // set nearby shown
        showingNearby = true
        nearbyButton.backgroundColor = charcoalGreyColor
        nearbyButton.setTitleColor(UIColor.white, for: UIControlState())
        
        myLocationsButton.backgroundColor = UIColor.white
        myLocationsButton.setTitleColor(UIColor.black, for: UIControlState())
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func defaultsChanged(_ notification:Notification){
        if (notification.object as? UserDefaults) != nil {
            let monitoredHotspotDictionary = self.appUserDefaults?.dictionary(forKey: savedHotspotsRegionKey) ?? Dictionary()
            drawNewAnnotations(monitoredHotspotDictionary as [String : AnyObject])
        }
    }
    
    func centerMapOnLocation(_ location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func addAnnotationsForDictionary(_ location: [String : AnyObject]) {
        let currentLocation = MyPretracker.sharedManager.locationManager?.location?.coordinate
        var lastLocation: CLLocation = CLLocation()
        
        let annotationLocation = CLLocation.init(coordinate: CLLocationCoordinate2D(latitude: location["latitude"] as! Double, longitude: location["longitude"] as! Double),
                                                 altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, course: 0.0, speed: 0.0, timestamp: Date.init())
        let tag = location["tag"] as! String
        
        var distanceToLocation: Double
        var distanceInFeet: Int
        var distanceString = ""
        
        // check if pretracker has an updated location to compute distance, if not don't display a distance.
        if let currentLocation = currentLocation {
            lastLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
            
            distanceToLocation = lastLocation.distance(from: annotationLocation)
            distanceInFeet = Int(distanceToLocation * 3.28084)
            distanceString =  "\(distanceInFeet) feet away"
        } else {
            distanceString = "Distance currently unavailable"
        }
        
        var annotationTitle = ""
        let locationCommonName = location["locationCommonName"] as! String
        if locationCommonName == "" {
            annotationTitle = createTitleFromTag(tag)
        } else {
            if tag == "queue" {
                annotationTitle = locationCommonName + " (line tracking)"
            } else if tag == "space" {
                annotationTitle = locationCommonName + " (space tracking)"
            }
        }
        
        let newLocation = MarkedLocation(title: annotationTitle,
                                         locationName: distanceString,
                                         discipline: tag,
                                         coordinate: CLLocationCoordinate2D(latitude: location["latitude"] as! Double, longitude: location["longitude"] as! Double),
                                         hotspotId: location["id"] as! String)
        mapView.addAnnotation(newLocation)
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
        mapView.removeAnnotations(mapView.annotations)
        
        // draw new annotations
        for (_, info) in locations {
            addAnnotationsForDictionary(info as! [String : AnyObject])
        }
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
                view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure) as UIView
            }
            return view
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // get data for hotspot
        var monitoredHotspotDictionary: [String : AnyObject]
        if showingNearby {
            monitoredHotspotDictionary = self.appUserDefaults?.dictionary(forKey: savedHotspotsRegionKey) as [String : AnyObject]? ?? Dictionary()
        } else {
            monitoredHotspotDictionary = self.appUserDefaults?.dictionary(forKey: myHotspotsRegionKey) as [String : AnyObject]? ?? Dictionary()
        }
        
        let annotationMarkedLocation = view.annotation as! MarkedLocation
        let annotationDistance = view.annotation?.subtitle
        let annotationHotpspotDictionary = monitoredHotspotDictionary[annotationMarkedLocation.hotspotId]
    
        // show DataForLocationViewController
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let dataForLocation : DataForLocationViewController = mainStoryboard.instantiateViewController(withIdentifier: "DataForLocationView") as! DataForLocationViewController
        
        dataForLocation.updateClassVariables(annotationHotpspotDictionary as! [String : AnyObject],
                                             distance: annotationDistance!!)
        dataForLocation.retrieveAndDrawData(annotationMarkedLocation.hotspotId)
        self.show(dataForLocation, sender: dataForLocation)
    }
    
    @IBAction func toggleNearbyPlaces(_ sender: AnyObject) {
        if !showingNearby {
            // draw new annotations
            let monitoredHotspotDictionary = self.appUserDefaults?.dictionary(forKey: savedHotspotsRegionKey) ?? Dictionary()
            drawNewAnnotations(monitoredHotspotDictionary as [String : AnyObject])
            
            // update buttons
            showingNearby = true
            nearbyButton.backgroundColor = charcoalGreyColor
            nearbyButton.setTitleColor(UIColor.white, for: UIControlState())
            
            myLocationsButton.backgroundColor = UIColor.white
            myLocationsButton.setTitleColor(UIColor.black, for: UIControlState())
        }
    }
    
    @IBAction func toggleLocationsMarked(_ sender: AnyObject) {
        if showingNearby {
            // draw new annotations
            getAndDrawMyMarkedLocations()
            
            // update buttons
            showingNearby = false
            myLocationsButton.backgroundColor = charcoalGreyColor
            myLocationsButton.setTitleColor(UIColor.white, for: UIControlState())
            
            nearbyButton.backgroundColor = UIColor.white
            nearbyButton.setTitleColor(UIColor.black, for: UIControlState())
        }
    }
    
    @IBAction func presentLeaderBoard(_ sender: Any) {
        // show Leaderboard view
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let profile : UserProfileViewController = mainStoryboard.instantiateViewController(withIdentifier: "ProfileViewController") as! UserProfileViewController
        
        self.show(profile, sender: profile)
        
//        let leaderboard : LeaderboardViewController = mainStoryboard.instantiateViewController(withIdentifier: "LeaderboardView") as! LeaderboardViewController
//        
//        self.show(leaderboard, sender: leaderboard)
    }
}
