//
//  TravelMapViewController+Pin.swift
//  VirtualTourist
//
//  Created by Shirley on 5/28/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation
import MapKit
import CoreData

// MARK: TravelMapViewController+Pin

extension TravelMapViewController {

    // MARK: setUpFetchPinsController - fetch location pins data controller
    
    func setUpFetchPinsController() {
        
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedPinsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try fetchedPinsController.performFetch()
        } catch {
            fatalError("The fetch pins could not be performed: \(error.localizedDescription)")
        }
    }
    
    // MARK: addLocationPin - add a location pin to data store
    
    func addLocationPin(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> Pin {
        
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = latitude
        pin.longitude = longitude
        pin.creationDate = Date()
        
        try? dataController.viewContext.save()
        
        return pin
    }
    
    // MARK: createAnnotations - fetch location pins from data store to create annotaions on map
    
    func createAnnotations() {
        
        // Create an MKPointAnnotation for each pin
        guard let pins = fetchedPinsController.fetchedObjects else {
            appDelegate.presentAlert(self, "No pins available")
            return
        }
        
        // first, remove previous annotations
        let allannotations = mapView.annotations
        mapView.removeAnnotations(allannotations)
        
        for aPin in pins {
            createAnnotation(pin: aPin)
        }
    }
    
    // MARK: createAnnotation - create an annotation from location pin
    
    func createAnnotation(pin: Pin) {
        
        // create the annotation and set its coordiate properties
        let annotation = Annotation(pin: pin)
        
        // add annotation to the map
        mapView.addAnnotation(annotation)
    }
    
    // MARK: createAnnotationFor - create an annotation for a location coordinate
    
    func createAnnotationFor(coordinate: CLLocationCoordinate2D) -> Annotation {
        
        // create the annotation and set its coordiate properties
        let annotation = Annotation(locationCoordinate: coordinate)
        
        // add annotation to the map
        mapView.addAnnotation(annotation)
        
        return annotation
    }
}
