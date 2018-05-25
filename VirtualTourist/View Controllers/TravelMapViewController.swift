//
//  TravelMapViewController.swift
//  VirtualTourist
//
//  Created by Shirley on 3/18/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit
import MapKit
import CoreData

// MARK: - TravelMapViewController: UIViewController, MKMapViewDelegate

/**
 * This view controller demonstrates the objects involved in displaying pins on a map.
 *
 * The map is a MKMapView.
 * The pins are represented by MKPointAnnotation instances.
 *
 * The view controller conforms to the MKMapViewDelegate so that it can receive a method
 * invocation when a pin annotation is tapped. It accomplishes this using two delegate
 * methods: one to put a small "info" button on the right side of each pin, and one to
 * respond when the "info" button is tapped.
 */

class TravelMapViewController: UIViewController {
    
    // MARK: Properties
    
    var appDelegate: AppDelegate!
    var completionHandlerForOpenURL: ((_ success: Bool) -> Void)?
    
    var dataController: DataController!
    
    var fetchedPinsController: NSFetchedResultsController<Pin>!
    var fetchedRegionController: NSFetchedResultsController<Region>!
    
    var annotation: Annotation?
    var region: Region?
    
    // The map. See the setup in the Storyboard file. Note particularly that the view controller
    // is set up as the map view's delegate.
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Grab the app delegate */
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        addGestureRecognizer()
        
//        /* Grab the region */
//        setUpFetchRegionController()
//        loadMapRegion()
//        
//        /* Grab the pins */
//        setUpFetchPinsController()
//        createAnnotations()
    }
    
    func addLocationPin(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> Pin {
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = latitude
        pin.longitude = longitude
        pin.creationDate = Date()
        
        try? dataController.viewContext.save()
        
        return pin
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        mapView.delegate = self

        /* Grab the region */
        setUpFetchRegionController()
        loadMapRegion()
        
        /* Grab the pins */
        setUpFetchPinsController()
        createAnnotations()        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        fetchedPinsController = nil
        fetchedRegionController = nil
    }
    
    @objc func dropPin(_ recognizer: UIGestureRecognizer) {
        let point:CGPoint = recognizer.location(in: self.mapView)
        
        let coordinate = mapView.convert(point, toCoordinateFrom: self.mapView)
        let span = mapView.region.span
        let center = mapView.region.center
        
        if (recognizer.state == .began) {
            print("dropPin createAnnotation: \(coordinate.latitude), \(coordinate.longitude), \(span), \(center)")
            
            annotation = createAnnotationFor(coordinate: coordinate)
        } else if (recognizer.state == .changed) {
            // move pin to a new location
            annotation?.updateCoordinate(newLocationCoordinate: coordinate)
        } else if (recognizer.state == .ended) {
            
            // Save location pin to data store
            print("drop addLocation: \(coordinate)")
            let pin = addLocationPin(latitude: coordinate.latitude, longitude: coordinate.longitude)
            annotation?.pin = pin
            
            // Download photos for pin location
            let result = searchPhotoCollectionFor(pin)
            if result.count > 0 {
                pin.photos = NSSet(array: [result])
            } else {
                pin.photos = NSSet()
            }
        }
    }
    
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
        print("createAnnotation: \(pins.count)")
    }
    
    fileprivate func createAnnotation(pin: Pin) {
        // create the annotation and set its coordiate properties
        let annotation = Annotation(pin: pin)
        
        // add annotation to the map
        mapView.addAnnotation(annotation)
    }
    
    fileprivate func createAnnotationFor(coordinate: CLLocationCoordinate2D) -> Annotation {
        // create the annotation and set its coordiate properties
        let annotation = Annotation(locationCoordinate: coordinate)
        
        // add annotation to the map
        mapView.addAnnotation(annotation)
        
        return annotation
    }
    
    fileprivate func setUpFetchPinsController() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedPinsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pin")
        do {
            try fetchedPinsController.performFetch()
        } catch {
            fatalError("The fetch pins could not be performed: \(error.localizedDescription)")
        }
    }
    
    fileprivate func setUpFetchRegionController() {
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
    
    // MARK: configure tap and hold recognizer
    
    fileprivate func addGestureRecognizer() {
        let longpressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(dropPin(_:)))
        
        mapView.addGestureRecognizer(longpressRecognizer)
    }
    
    // MARK: Set span to user selected zoom level
    
    func setSpan() {
        
        let latitudeDelta = mapView.region.span.latitudeDelta
        let longitudeDelta = mapView.region.span.longitudeDelta
        
        setRegion(latitudeDelta, longitudeDelta)
    }
    
    // MARK: set map region per selected location and zoom level choice
    
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
    
    // MARK: Map Region
    
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
    
    // MARK: save map region per user selected location and zoom level to data store
    
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
    
    // MARK: Center map on latest student location
    
    private func centerMapOnPin(pin: Pin) {
        let regionRadius: CLLocationDistance = AppDelegate.AppConstants.RegionRadius  // meters
        let centerCoordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(centerCoordinate, regionRadius, regionRadius)
        
        mapView.setCenter(centerCoordinate, animated: true)
        mapView.setRegion(coordinateRegion, animated: true)
    }
}

extension TravelMapViewController: MKMapViewDelegate {
    
    // MARK: mapView - viewFor - Create a view with callout accessory view
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {


        let reuseId = "pin"

        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
//            pinView!.detailCalloutAccessoryView = UIButton()
            print("mapView viewFor")
        }
        else {
            pinView!.annotation = annotation
        }

        return pinView
    }
    
    // MARK: mapView - calloutAccessoryControlTapped - opens the system browser
    // to the URL specified in the annotationViews subtitle property.
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let controller = storyboard!.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
        if let annotation = view.annotation as? Annotation {
            print("mapView didSelect annotation: \(annotation.coordinate)")
            
            controller.pin = annotation.pin
            controller.annotation = annotation
            controller.span = mapView.region.span
            controller.dataController = dataController
//            if controller.searchPage == nil {
//                controller.searchPage = 1
//            }
            PhotoAlbumViewController.hasFlickrPhoto = false
        }
        navigationController!.pushViewController(controller, animated: true)
        print("mapView didSelect: \(view.annotation?.coordinate)")
    }
    
    // MARK: mapView - regionDidChangeAnimated - Set and save location and zoom level when map region is changed
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        // Set and save location and zoom level when map region is changed
        setSpan()
    }
}

extension TravelMapViewController {
    
    func searchPhotoCollectionFor(_ pin: Pin) -> [Photo] {
        
        let searchPage = 1
        print("MapView searchPhotoCollectionFor - searchPage: \(searchPage)")
        
        var photos = [Photo]()
        
        FlickrClient.sharedInstance().getPhotosForCoordinate(pin.latitude, pin.longitude, searchPage) { (result, error) in
            
            guard (error == nil) else {
                self.displayError(error?.userInfo[NSLocalizedDescriptionKey] as? String)
                return
            }
            
            if let result = result {
                if result.count > 0 {
                    PhotoAlbumViewController.hasFlickrPhoto = true
                    photos = self.savePhotosFor(pin, from: result)
                }
            }
        }
    
        print("searchPhotoCollectionFor - photos - \(photos.count)")
    
        return photos
    }
    
    func savePhotosFor(_ pin: Pin, from newCollection: [FlickrPhoto]) -> [Photo] {
        
        print("MapView savePhotosFor - newCollection: \(newCollection.count)")
        
        return addPhotosFor(pin, from: newCollection)
    }
    
    // Adds a new `photo` to the the `pin`'s `photoCollection` array
    
    func addPhotosFor(_ pin: Pin, from photoCollection: [FlickrPhoto]) -> [Photo]{
        
        var photos = [Photo]()
        
        // Save photo urls and title for pin
        for newPhoto in photoCollection {
            if let mediumURL = newPhoto.mediumURL,
                let imageURL = URL(string: mediumURL) {
                let photo = Photo(context: dataController.viewContext)
                photo.creationDate = Date()
                photo.title = newPhoto.title
                photo.url = mediumURL
                if let imageData = try? Data(contentsOf: imageURL) {
                    photo.image = imageData
                }
                photo.pin = pin
                
                photos.append(photo)
                print("addPhoto \(photo.title)")
            }
        }
        
        try? dataController.viewContext.save()
        
        return photos
    }
    
    // MAKR: Display error
    
    func displayError(_ errorString: String?) {
        
        print(errorString!)
        dismiss(animated: true, completion: nil)
    }
}
