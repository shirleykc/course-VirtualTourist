//
//  Annotation.swift
//  VirtualTourist
//
//  Created by Shirley on 5/6/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation
import MapKit

// MARK: Annotation

class Annotation: NSObject, MKAnnotation {
    
    // MARK: Properties

    var locationCoordinate: CLLocationCoordinate2D
    
    var coordinate: CLLocationCoordinate2D {
        return locationCoordinate
    }
    
    var pin: Pin?
    
    // MARK: Initializers
    
    init(pin: Pin) {
        self.pin = pin
        self.locationCoordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
    }
    
    init(locationCoordinate: CLLocationCoordinate2D) {
        self.locationCoordinate = locationCoordinate
    }
    
    // MARK: Class Functions
    public func updateCoordinate(newLocationCoordinate: CLLocationCoordinate2D) -> Void {
        
        // Update location coordinate from old to new
        willChangeValue(forKey: "coordinate")
        locationCoordinate = newLocationCoordinate
        didChangeValue(forKey: "coordinate")
    }
}

