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
    
    let appUserDefaults = UserDefaults.init(suiteName: appGroup)
    
    // MARK: - View Controller Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        // setup map view
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = MKUserTrackingMode.follow
        
        // check for changes in NSUserDefaults
        NotificationCenter.default.addObserver(self, selector: #selector(HomeScreenViewController.defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // add pins for marked locations
        let monitoredHotspotDictionary = self.appUserDefaults?.dictionary(forKey: savedHotspotsRegionKey) ?? Dictionary()
        drawNewAnnotations(monitoredHotspotDictionary as [String : AnyObject])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 18, weight: UIFontWeightLight),
                                                                        NSForegroundColorAttributeName: UIColor.white]
        self.navigationController?.navigationBar.tintColor = UIColor.white
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Annotation Drawing
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
        
        let annotationLocation = CLLocation.init(coordinate: CLLocationCoordinate2D(latitude: location["latitude"] as! Double,
                                                                                    longitude: location["longitude"] as! Double),
                                                                                    altitude: 0.0,
                                                                                    horizontalAccuracy: 0.0,
                                                                                    verticalAccuracy: 0.0,
                                                                                    course: 0.0,
                                                                                    speed: 0.0,
                                                                                    timestamp: Date.init())
        let tag = location["tag"] as! String
        
        var distanceToLocation: Double
        var distanceInMinutes: Int
        var distanceString = ""
        
        // check if pretracker has an updated location to compute distance, if not don't display a distance.
        if let currentLocation = currentLocation {
            lastLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
            
            distanceToLocation = lastLocation.distance(from: annotationLocation)
            distanceInMinutes = Int(distanceToLocation / 100.0) // approximate walking speed = 100m/min
            distanceString =  "\(distanceInMinutes) minutes away"
        } else {
            distanceString = "Distance currently unavailable"
        }
        
        var annotationTitle = ""
        let locationCommonName = location["locationCommonName"] as! String
        if locationCommonName == "" {
            annotationTitle = createTitleFromTag(tag)
        } else {
            annotationTitle = locationCommonName
        }
        
        let newLocation = MarkedLocation(title: annotationTitle,
                                         locationName: distanceString,
                                         discipline: tag,
                                         coordinate: CLLocationCoordinate2D(latitude: location["latitude"] as! Double,
                                                                            longitude: location["longitude"] as! Double),
                                         hotspotId: location["id"] as! String)
        mapView.addAnnotation(newLocation)
    }
    
    func createTitleFromTag(_ tag: String) -> String{
        switch tag {
        case "food":
            return "Free/Sold Food Here"
        default:
            return ""
        }
    }
    
    // TODO: check if exploit location, if so don't draw
    func drawNewAnnotations(_ locations: [String : AnyObject]) {
        // clear all existing annotations
        mapView.removeAnnotations(mapView.annotations)
        
        // draw new annotations
        for (_, info) in locations {
            let currentLocationInfo = info as! [String : AnyObject]
            
            if (currentLocationInfo["locationType"] as! String != "exploit") {
                addAnnotationsForDictionary(currentLocationInfo)
            }
        }
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
    
    // MARK: - Annotation Interaction
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // get data for hotspot
        var monitoredHotspotDictionary: [String : AnyObject] = self.appUserDefaults?.dictionary(forKey: savedHotspotsRegionKey) as [String : AnyObject]? ?? Dictionary()
        
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
}
