//
//  PhotoAlbumViewController+Photo.swift
//  VirtualTourist
//
//  Created by Shirley on 5/28/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation
import CoreData

// MARK: PhotoAlbumViewController+Photo

extension PhotoAlbumViewController {
    
    // MARK: setupFetchedPhotosController - fetch the photos for the location pin in data store
    
    func setupFetchedPhotosController(doRemoveAll: Bool) {
        
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", argumentArray: [pin!])
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = []
        
        fetchedPhotosController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedPhotosController.performFetch()
            if let results = fetchedPhotosController?.fetchedObjects {
                 if doRemoveAll {
                    self.photos.removeAll()
                }
                self.photos = results
            }
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    // MARK: savePhotosFor - add photos to the location pin's photos array in data store
    
    func savePhotosFor(_ pin: Pin, from newCollection: [FlickrPhoto], completionHandlerForPhotoSave: @escaping (_ success: Bool) -> Void) {
        
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
        
        completionHandlerForPhotoSave(true)
    }
    
    // MARK: savePhotoImageFor - save photo images for the location pin in data store
    
    func savePhotoImageFor(_ pin: Pin, completionHandlerForPhotoImageSave: @escaping (_ success: Bool, _ error: String?) -> Void) {
        
        setupFetchedPhotosController(doRemoveAll: false)
        if self.photos.count > 0 {
            for aPhoto in self.photos {
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
        completionHandlerForPhotoImageSave(true, nil)
    }

    // MARK: deleteAllPhotos - Delete all photos for the pin from data store
    
    func deleteAllPhotos() {
        
        for aPhoto in self.photos {
            dataController.viewContext.delete(aPhoto)
        }
        try? dataController.viewContext.save()
        
        // Reset
        self.photos.removeAll()
    }
    
    // MARK: searchPhotoCollectionFor - search Flickr photo collection for location pin
    
    func searchPhotoCollectionFor(_ pin: Pin, _ searchPage: Int?, completionHandlerForSearchPhotoCollection: @escaping (_ success: Bool, _ result: [FlickrPhoto]?, _ error: String?) -> Void) {
        
        FlickrClient.sharedInstance().getPhotosForCoordinate(pin.latitude, pin.longitude, searchPage) { (results, error) in
            
            guard (error == nil) else {
                completionHandlerForSearchPhotoCollection(false, nil, (error?.userInfo[NSLocalizedDescriptionKey] as! String))
                return
            }
            
            performUIUpdatesOnMain {
                if let results = results {
                    completionHandlerForSearchPhotoCollection(true, results, nil)
                } else {
                    completionHandlerForSearchPhotoCollection(false, nil, "Cannot load photos")
                }
            }
        }
    }
    
    // MARK: downloadFlickrPhotosFor - download new Flickr photo collection
    
    func downloadFlickrPhotosFor(_ pin: Pin) {
        
        // Initialize
        PhotoAlbumViewController.hasFlickrPhoto = true
        
        searchPhotoCollectionFor(pin, FlickrClient.searchPage) { (success, result, error) in
            
            if success {
 
                self.savePhotosFor(pin, from: result!) { (success) in
                    if success {
                        
                        self.savePhotoImageFor(pin) { (success, error) in
                            if success {
                                
                                self.displayPhotos { (completion) in
                                    self.resetUIAfterDownloadingPhotos()
                                }
                            }
                            else {
                                self.displayError("Unable to save photo images")
                            }
                        }
                    } else {
                        self.displayError("Unable to save photo")
                    }
                }
            } else {
                self.displayError(error)
            }
            self.isLoadingFlickrPhotos = false
        }
        self.resetUIAfterDownloadingPhotos()
    }
    
    // MARK: displayPhotos - dipplay photos in collection view
    
    func displayPhotos(completionHandlerForDisplayPhotos: @escaping (_ success: Bool) -> Void) {
        
        self.isLoadingFlickrPhotos = false
        self.setupFetchedPhotosController(doRemoveAll: true)
        
        // Display new set of photos for the pin location
        if (self.photos.count > 0) {
            let delay = DispatchTime.now() + .seconds(1)
            DispatchQueue.main.asyncAfter(deadline: delay) {
                completionHandlerForDisplayPhotos(true)
            }
        } else {
            self.appDelegate.presentAlert(self, "No photos available")
            completionHandlerForDisplayPhotos(true)
        }
    }
    
}
