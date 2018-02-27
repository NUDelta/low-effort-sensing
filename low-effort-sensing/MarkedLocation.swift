//
//  MarkedLocations.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 5/24/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import Foundation
import MapKit

class MarkedLocation: NSObject, MKAnnotation {
    let title: String?
    let locationName: String
    let discipline: String
    let coordinate: CLLocationCoordinate2D
    let taskLocationId: String
    
    init(title: String, locationName: String, discipline: String, coordinate: CLLocationCoordinate2D, taskLocationId: String) {
        self.title = title
        self.locationName = locationName
        self.discipline = discipline
        self.coordinate = coordinate
        self.taskLocationId = taskLocationId
        
        super.init()
    }
    
    var subtitle: String? {
        return locationName
    }
}
