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
//    // MARK: Class Variables
//    @IBOutlet weak var mapView: MKMapView!
//    let regionRadius: CLLocationDistance = 1000
//    
//    let appUserDefaults = NSUserDefaults.init(suiteName: "group.com.delta.les")
//    
//    // MARK: Class Functions
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        // Do any additional setup after loading the view, typically from a nib.
//        
//        // set initial location to current user location
//        let currentLocation = MyPretracker.sharedManager.locationManager?.location?.coordinate
//        let initialLocation = CLLocation(latitude: (currentLocation?.latitude)!,
//                                         longitude: (currentLocation?.longitude)!)
//        centerMapOnLocation(initialLocation)
//        
//        // add pins for marked locations
//        let monitoredHotspotDictionary = self.appUserDefaults?.dictionaryForKey(savedHotspotsRegionKey) ?? Dictionary()
//        for (_, info) in monitoredHotspotDictionary {
//            addAnnotationsForDictionary(info as! [String : AnyObject])
//            
//            let location = info as! [String : AnyObject]
//            let lastLocation = MyPretracker.sharedManager.locationManager?.location
//            let annotationLocation = CLLocation.init(coordinate: CLLocationCoordinate2D(latitude: location["latitude"] as! Double, longitude: location["longitude"] as! Double), altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, course: 0.0, speed: 0.0, timestamp: NSDate.init())
//            
//            let distanceToLocation = lastLocation!.distanceFromLocation(annotationLocation)
//            print(info)
//            print(distanceToLocation)
//        }
//    }
//    
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
//    
//    func centerMapOnLocation(location: CLLocation) {
//        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
//                                                                  regionRadius * 2.0, regionRadius * 2.0)
//        mapView.setRegion(coordinateRegion, animated: true)
//    }
//    
//    func addAnnotationsForDictionary(location: [String : AnyObject]) {
//        let lastLocation = MyPretracker.sharedManager.locationManager?.location
//        let annotationLocation = CLLocation.init(coordinate: CLLocationCoordinate2D(latitude: location["latitude"] as! Double, longitude: location["longitude"] as! Double), altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, course: 0.0, speed: 0.0, timestamp: NSDate.init())
//        
//        let distanceToLocation = lastLocation!.distanceFromLocation(annotationLocation)
//        
//        let newLocation = MarkedLocation(title: location["tag"] as! String,
//                                         locationName: "\(distanceToLocation) meters from your location",
//                                         discipline: "food",
//                                         coordinate: CLLocationCoordinate2D(latitude: location["latitude"] as! Double, longitude: location["longitude"] as! Double))
//        mapView.addAnnotation(newLocation)
//    }
}
