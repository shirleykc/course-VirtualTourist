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
 * The view controller conforms to the MKMapViewDelegate.
 */

class TravelMapViewController: UIViewController {
    
    // MARK: Properties
    
    var appDelegate: AppDelegate!
    var completionHandlerForOpenURL: ((_ success: Bool) -> Void)?
    
    var dataController: DataController!
    
    var fetchedPinsController: NSFetchedResultsController<Pin>!
    var fetchedRegionController: NSFetchedResultsController<Region>!
    var fetchedPhotosController: NSFetchedResultsController<Photo>!
    
    var annotation: Annotation?
    var region: Region?
    
    // action buttons
    var removePinsBanner: UIBarButtonItem?
    var editButton: UIBarButtonItem?
    var doneButton: UIBarButtonItem?
    
    var doDeletePins: Bool = false
    
    // MARK: Outlets
    
    @IBOutlet weak var mapView: MKMapView!
//    @IBOutlet weak var editButton: UIBarButtonItem!
    
    // MARK: Life Cycle
    
    // MARK: viewDidLoad

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Grab the app delegate
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        // Add gesture recognizer
        addGestureRecognizer()
        
        self.navigationController?.setToolbarHidden(true, animated: true)
        createEditButton(navigationItem)
    }
    
    // MARK: viewAllAppear
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        mapView.delegate = self

        // Grab the region
        setUpFetchRegionController()
        loadMapRegion()
        
        // Grab the pins
        setUpFetchPinsController()
        createAnnotations()
        
        self.navigationController?.setToolbarHidden(true, animated: true)
        createEditButton(navigationItem)
    }
    
    // MARK: viewDidDisappear
    
    override func viewDidDisappear(_ animated: Bool) {
        
        super.viewDidDisappear(animated)
        
        fetchedPinsController = nil
        fetchedRegionController = nil
    }
    
    // MARK: Actions
    
    // MARK: dropPin - drop a location pin on the map
    
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
            searchPhotoCollectionFor(pin)
        }
    }
    
    // MARK: done - Done deleting pins
    
    @objc func done() {
        
        self.navigationController?.setToolbarHidden(true, animated: true)
        
        doDeletePins = false
        
        createEditButton(navigationItem)
    }
    
    // MARK: editButtonPressed - edit button is pressed
    
//    @IBAction func editButtonPressed(_ sender: UIBarButtonItem?) {
    
    // MARK: editPin - edit pin button is pressed
    
    @objc func editPin() {
        
        self.navigationController?.setToolbarHidden(false, animated: true)
        self.navigationController?.toolbar.barTintColor = UIColor.red
        self.navigationController?.toolbar.tintColor = UIColor.white
        
        createRemovePinsBanner()
        removePinsBanner?.isEnabled = true
        
        doDeletePins = true
        
        createDoneButton(navigationItem)
    }
    
    // MARK: createRemovePinsBanner - create and set the remove pins banner
    
    private func createRemovePinsBanner() {
        
        var toolbarButtons: [UIBarButtonItem] = [UIBarButtonItem]()
        
        // use empty flexible space bar button to center the new collection button
        let flexButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)
        
        removePinsBanner = UIBarButtonItem(title: "Tap Pins to Delete", style: .plain, target: self, action: nil)
        toolbarButtons.append(flexButton)
        toolbarButtons.append(removePinsBanner!)
        toolbarButtons.append(flexButton)
        self.setToolbarItems(toolbarButtons, animated: true)
    }
    
    // MARK: createEditButton - create and set the Edit bar buttons
    
    private func createEditButton(_ navigationItem: UINavigationItem) {
        
        var rightButtons: [UIBarButtonItem] = [UIBarButtonItem]()
        editButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.edit, target: self, action: #selector(editPin))
        rightButtons.append(editButton!)
        navigationItem.setRightBarButtonItems(rightButtons, animated: true)
    }
    
    // MARK: createDoneButton - create and set the Done bar buttons
    
    private func createDoneButton(_ navigationItem: UINavigationItem) {
        
        var rightButtons: [UIBarButtonItem] = [UIBarButtonItem]()
        doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(done))
        rightButtons.append(doneButton!)
        navigationItem.setRightBarButtonItems(rightButtons, animated: true)
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
        print("createAnnotation: \(pins.count)")
    }
    
    // MARK: Helpers
    
    // MARK: createAnnotation - create an annotation from location pin
    
    fileprivate func createAnnotation(pin: Pin) {
        
        // create the annotation and set its coordiate properties
        let annotation = Annotation(pin: pin)
        
        // add annotation to the map
        mapView.addAnnotation(annotation)
    }
    
    // MARK: createAnnotationFor - create an annotation for a location coordinate
    
    fileprivate func createAnnotationFor(coordinate: CLLocationCoordinate2D) -> Annotation {
        
        // create the annotation and set its coordiate properties
        let annotation = Annotation(locationCoordinate: coordinate)
        
        // add annotation to the map
        mapView.addAnnotation(annotation)
        
        return annotation
    }
    
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
    
    
    // MARK: addGestureRecognizer - configure tap and hold recognizer
    
    func addGestureRecognizer() {
        let longpressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(dropPin(_:)))
        
        mapView.addGestureRecognizer(longpressRecognizer)
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
    
    // MARK: centerMapOnPin - enter map on latest student location
    
    private func centerMapOnPin(pin: Pin) {
        
        let regionRadius: CLLocationDistance = AppDelegate.AppConstants.RegionRadius  // meters
        let centerCoordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(centerCoordinate, regionRadius, regionRadius)
        
        mapView.setCenter(centerCoordinate, animated: true)
        mapView.setRegion(coordinateRegion, animated: true)
    }
}

// MARK: MKMapViewDelegate

extension TravelMapViewController: MKMapViewDelegate {
    
    // MARK: mapView - viewFor - Create a view with callout accessory view
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        let reuseId = "pin"

        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
            print("mapView viewFor")
        }
        else {
            pinView!.annotation = annotation
        }

        return pinView
    }
    
    // MARK: mapView - didSelect - opens the photo album of the selected location pin
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if doDeletePins {
            if let annotation = view.annotation as? Annotation {
                print("mapView doDeletePins didSelect annotation: \(annotation.coordinate)")
                if let pin = annotation.pin {
                    dataController.viewContext.delete(pin)
                    try? dataController.viewContext.save()
                    
                    mapView.removeAnnotation(annotation)
                    setUpFetchPinsController()
                }
            }
        } else {
            let controller = storyboard!.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
            if let annotation = view.annotation as? Annotation {
                print("mapView didSelect annotation: \(annotation.coordinate)")
                
                controller.pin = annotation.pin
                controller.annotation = annotation
                controller.span = mapView.region.span
                controller.dataController = dataController
            }
            
            navigationController!.pushViewController(controller, animated: true)
        }
        
        print("mapView didSelect: \(view.annotation?.coordinate)")
    }
    
    // MARK: mapView - regionDidChangeAnimated - Set and save location and zoom level when map region is changed
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        // Set and save location and zoom level when map region is changed
        setSpan()
    }
}

// MARK: Helpers

extension TravelMapViewController {
    
    // MARK: searchPhotoCollectionFor - search photo collection for a pin
    
    func searchPhotoCollectionFor(_ pin: Pin) {
        
        print("MapView searchPhotoCollectionFor - searchPage: \(FlickrClient.searchPage)")
        
        // Initialize
        PhotoAlbumViewController.hasFlickrPhoto = true
        
        FlickrClient.sharedInstance().getPhotosForCoordinate(pin.latitude, pin.longitude, FlickrClient.searchPage) { (result, error) in
            
            guard (error == nil) else {
                self.displayError(error?.userInfo[NSLocalizedDescriptionKey] as? String)
                return
            }
            
            performUIUpdatesOnMain {
                if let result = result {
                    if result.count > 0 {
                        print("map searchPhotoCollectionFor - result - \(result.count)")
                        self.savePhotosFor(pin, from: result)
                    }
                }
            }
        }
    }
    
    // MARK: savePhotosFor - save photos for a location pin
    
    func savePhotosFor(_ pin: Pin, from newCollection: [FlickrPhoto]) {
        
        print("MapView savePhotosFor - newCollection: \(newCollection.count)")
        
        // Save photo urls and title for pin
        for newPhoto in newCollection {
            if let mediumURL = newPhoto.mediumURL {
                let photo = Photo(context: self.dataController.viewContext)
                photo.creationDate = Date()
                photo.title = newPhoto.title
                photo.url = mediumURL
                photo.image = Data()
                photo.pin = pin
                
                print("addPhoto \(photo.title)")
            }
        }
        
        try? self.dataController.viewContext.save()
        
        savePhotoImageFor(pin)
    }
    
    // MARK: savePhotoImageFor - save photo images for the location pin in data store
    
    func savePhotoImageFor(_ pin: Pin) {
        
        let photos:[Photo] = setupFetchedPhotosController(pin)
        if photos.count > 0 {
            for aPhoto in photos {
                if let mediumURL = aPhoto.url {
                    
                    FlickrClient.sharedInstance().getPhotoImageFrom(mediumURL) { (imageData, error) in
                        
                        if error == nil {
                            performUIUpdatesOnMain {
                                aPhoto.image = imageData
                                try? self.dataController.viewContext.save()
                                print("savePhotoImageFor photo title: \(mediumURL)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: setupFetchedPhotosController - fetch the photos for the location pin in data store
    
    func setupFetchedPhotosController(_ pin: Pin) -> [Photo] {
        
        var photos = [Photo]()
        
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", argumentArray: [pin])
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = []
        
        fetchedPhotosController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedPhotosController.performFetch()
            if let results = fetchedPhotosController?.fetchedObjects {
                print("photoAlbumController - fetchPhotosController - performFetch results \(results.count)")
                photos = results
                
                print("photoAlbumController - fetchPhotosController - performFetch photos \(photos.count)")
            }
        } catch {
            displayError("Cannot fetch photos")
        }
        
        return photos
    }
    
    // MAKR: displayError - Display error
    
    func displayError(_ errorString: String?) {
        
        print(errorString!)
        dismiss(animated: true, completion: nil)
    }
}
