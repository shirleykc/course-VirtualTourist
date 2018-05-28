//
//  TravelMapViewController+Photo.swift
//  VirtualTourist
//
//  Created by Shirley on 5/28/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation
import CoreData

// MARK: TravelMapViewController+Photo

extension TravelMapViewController {
    
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
                photos = results
            }
        } catch {
            displayError("Cannot fetch photos")
        }
        
        return photos
    }
    
    // MARK: searchPhotoCollectionFor - search photo collection for a pin
    
    func searchPhotoCollectionFor(_ pin: Pin) {
        
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
                        self.savePhotosFor(pin, from: result)
                    }
                }
            }
        }
    }
    
    // MARK: savePhotosFor - save photos for a location pin
    
    func savePhotosFor(_ pin: Pin, from newCollection: [FlickrPhoto]) {
        
        // Save photo urls and title for pin
        for newPhoto in newCollection {
            if let mediumURL = newPhoto.mediumURL {
                let photo = Photo(context: self.dataController.viewContext)
                photo.creationDate = Date()
                photo.title = newPhoto.title
                photo.url = mediumURL
                photo.image = Data()
                photo.pin = pin
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
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MAKR: displayError - Display error
    
    func displayError(_ errorString: String?) {
        
        print(errorString!)
        dismiss(animated: true, completion: nil)
    }
}
