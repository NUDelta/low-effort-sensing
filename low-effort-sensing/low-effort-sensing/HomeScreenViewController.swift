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
    
    let appUserDefaults = NSUserDefaults.init(suiteName: appGroup)
    
    // MARK: Class Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        // setup map view
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = MKUserTrackingMode.Follow
    }
    
    override func viewDidAppear(animated: Bool) {
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
        let currentLocation = MyPretracker.sharedManager.locationManager?.location?.coordinate
        var lastLocation: CLLocation = CLLocation()
        
        let annotationLocation = CLLocation.init(coordinate: CLLocationCoordinate2D(latitude: location["latitude"] as! Double, longitude: location["longitude"] as! Double), altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, course: 0.0, speed: 0.0, timestamp: NSDate.init())
        let tag = location["tag"] as! String
        
        var distanceToLocation: Double
        var distanceInFeet: Int
        var distanceString = ""
        
        // check if pretracker has an updated location to compute distance, if not don't display a distance.
        if let currentLocation = currentLocation {
            lastLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
            
            distanceToLocation = lastLocation.distanceFromLocation(annotationLocation)
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
            print(locationCommonName)
            print(tag)
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
                        
                        let info : [String : AnyObject]? = object["info"] as? [String : AnyObject]
                        
                        // Add data to user defaults
                        var unwrappedEntry = [String : AnyObject]()
                        unwrappedEntry["id"] = id
                        unwrappedEntry["vendorId"] = object["vendorId"] as! String
                        unwrappedEntry["tag"] = object["tag"] as! String
                        unwrappedEntry["info"] = info
                        unwrappedEntry["latitude"] = currLat
                        unwrappedEntry["longitude"] = currLong
                        unwrappedEntry["archived"] = object["archived"] as? Bool
                        unwrappedEntry["timestampCreated"] = object["timestampCreated"] as? Int
                        unwrappedEntry["gmtOffset"] = object["gmtOffset"] as? Int
                        unwrappedEntry["timestampLastUpdate"] = object["timestampLastUpdate"] as? Int
                        unwrappedEntry["submissionMethod"] = object["submissionMethod"] as? String
                        unwrappedEntry["locationCommonName"] = object["locationCommonName"] as? String
                        
                        monitoredHotspotDictionary[id] = unwrappedEntry
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
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? MarkedLocation {
            let identifier = "pin"
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
                as? MKPinAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
                view.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure) as UIView
            }
            return view
        }
        return nil
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // get data for hotspot
        var monitoredHotspotDictionary: [String : AnyObject]
        if showingNearby {
            monitoredHotspotDictionary = self.appUserDefaults?.dictionaryForKey(savedHotspotsRegionKey) ?? Dictionary()
        } else {
            monitoredHotspotDictionary = self.appUserDefaults?.dictionaryForKey(myHotspotsRegionKey) ?? Dictionary()
        }
        
        let annotationMarkedLocation = view.annotation as! MarkedLocation
        let annotationDistance = view.annotation?.subtitle
        let annotationHotpspotDictionary = monitoredHotspotDictionary[annotationMarkedLocation.hotspotId]
    
        // show DataForLocationViewController
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let dataForLocation : DataForLocationViewController = mainStoryboard.instantiateViewControllerWithIdentifier("DataForLocationView") as! DataForLocationViewController
        
        dataForLocation.loadDataForHotspotDictionary(annotationHotpspotDictionary as! [String : AnyObject], distance: annotationDistance!!)
        self.showViewController(dataForLocation, sender: dataForLocation)
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
