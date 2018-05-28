//
//  TravelMapViewController+Region.swift
//  VirtualTourist
//
//  Created by Shirley on 5/28/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation
import MapKit
import CoreData

// MARK: TravelMapViewController+Region

extension TravelMapViewController {

    // MARK: setUpFetchRegionController - fetch preset map region data controller
    
    func setUpFetchRegionController() {
        
        let fetchRequest: NSFetchRequest<Region> = Region.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.fetchLimit = 1
        
        fetchedRegionController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "region")
        do {
            try fetchedRegionController.performFetch()
        } catch {
            fatalError("The fetch region could not be performed: \(error.localizedDescription)")
        }
    }
    
    // MARK: setSpan - Set span to user selected zoom level
    
    func setSpan() {
        
        let latitudeDelta = mapView.region.span.latitudeDelta
        let longitudeDelta = mapView.region.span.longitudeDelta
        
        setRegion(latitudeDelta, longitudeDelta)
    }
    
    // MARK: setRegion - set map region per selected location and zoom level choice
    
    func setRegion(_ latitudeDelta: CLLocationDegrees, _ longitudeDelta: CLLocationDegrees) {
        
        // Set map to selected location
        let latitude = mapView.region.center.latitude
        let longitude = mapView.region.center.longitude
        
        // Set map region per location and zoom level choice
        let location = CLLocationCoordinate2DMake(latitude, longitude)
        let span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta)
        let region = MKCoordinateRegionMake(location, span)
        
        mapView.setRegion(region, animated: true)
        saveRegion(region)
    }
    
    // MARK: loadMapRegion - Map Region
    
    func loadMapRegion() {
        
        // Create an MKPointAnnotation for each pin
        if let results = fetchedRegionController.fetchedObjects,
            results.count > 0 {
            region = results[0]
        }
        
        if let savedRegion = region {
            
            // Load last map location and zoom level
            let latitude = savedRegion.latitude
            let longitude = savedRegion.longitude
            let latitudeDelta = savedRegion.latitudeDelta
            let longitudeDelta = savedRegion.longitudeDelta
            
            // Set map region by previous location and zoom level choice
            let location = CLLocationCoordinate2DMake(latitude, longitude)
            let span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta)
            let mapRegion = MKCoordinateRegionMake(location, span)
            
            mapView.setRegion(mapRegion, animated: true)
        }
    }
    
    // MARK: saveRegion - save map region per user selected location and zoom level to data store
    
    func saveRegion(_ mapRegion: MKCoordinateRegion) {
        
        // Save map region to user selected location and zoom level
        if (region == nil) {
            region = Region(context: dataController.viewContext)
        }
        
        region?.latitude = mapRegion.center.latitude
        region?.longitude = mapRegion.center.longitude
        region?.latitudeDelta = mapRegion.span.latitudeDelta
        region?.longitudeDelta = mapRegion.span.longitudeDelta
        region?.creationDate = Date()
        
        try? dataController.viewContext.save()
    }
    
}
