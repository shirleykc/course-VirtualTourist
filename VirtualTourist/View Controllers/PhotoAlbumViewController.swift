//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Shirley on 3/18/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegateFlowLayout {

    // MARK: Properties
    
    var appDelegate: AppDelegate!
    var annotation: Annotation!
    var span: MKCoordinateSpan!
    var photoCollection: FlickrPhotoCollection!
    
    // action buttons
    var newPhotosButton: UIBarButtonItem?
    var removePhotosButton: UIBarButtonItem?
    
    // The location whose photos are being displayed
    var pin: Pin!
    var photos = [Photo]()
    
    var dataController:DataController!
    var fetchedPhotosController:NSFetchedResultsController<Photo>!

    var selectedPhotoCells = [IndexPath]()
    var isLoadingFlickrPhotos: Bool = false
    
    static var hasFlickrPhoto: Bool = false
    
    // MARK: Outlets

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    // MARK: Life Cycle
    
    // MARK: viewDidLoad
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Grab the app delegate
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        self.navigationController?.setToolbarHidden(false, animated: true)
        self.navigationController?.toolbar.barTintColor = UIColor.white
        self.navigationController?.toolbar.tintColor = UIColor.blue
        
        photoCollectionView.delegate = self
        
        mapView.delegate = self
        
        // add annotation to the map
        mapView.addAnnotation(annotation)
        mapView.setCenter(annotation.coordinate, animated: true)
        mapView.setRegion(MKCoordinateRegionMake(annotation.coordinate, span), animated: true)
        print("mapView addAnnotatiopin")
        
        // Grab the photos
        setupFetchedPhotosController(doRemoveAll: true)
        
        isLoadingFlickrPhotos = (photos.count == 0) ? true : false
        print("viewDidLoad photos.count \(photos.count)")
        
        // Implement flowLayout here.
        let photoFlowLayout = photoCollectionView.collectionViewLayout as? UICollectionViewFlowLayout
        configure(flowLayout: photoFlowLayout!, withSpace: 1, withColumns: 3, withRows: 5)
        
        // Initialize new collection button
        createNewPhotosButton()
        setUIActions()
        
        // If empty photo collection, then download new set of photos
        if (isLoadingFlickrPhotos) {
            setUIForDownloadingPhotos()
            downloadFlickrPhotosFor(pin)
        } else {
            newPhotosButton?.isEnabled = true
        }
    }
    
    // MARK: viewWillAppear
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)

        photoCollectionView.reloadData()
    }
    
    // MARK: viewDidAppear
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        photoCollectionView.reloadData()
    }

    // MARK: viewDidDisappear
    
    override func viewDidDisappear(_ animated: Bool) {
        
        super.viewDidDisappear(animated)
        
        fetchedPhotosController = nil
        
        self.navigationController?.setToolbarHidden(true, animated: true)
    }
    
    // MARK: Actions
    
    // MARK: newCollectionPressed - new collection button is pressed
    
    @objc func newCollectionPressed() {
        print("start newCollectionPressed")
        
        // Initialize
        isLoadingFlickrPhotos = true
        
        setUIForDownloadingPhotos()
        deleteAllPhotos()
        
        print("newCollectionPressed searchPage: \(FlickrClient.searchPage)")
        
        downloadFlickrPhotosFor(pin)
    }
    
    // MARK: removePhotosPressed - remove selected photos button is pressed
    
    @objc func removePhotosPressed(_ sender: UIButton?) {
        
        var selectedPhotos = [Photo]()
        selectedPhotoCells = selectedPhotoCells.sorted(by: {$0.item > $1.item})
        
        // Delete selected photos and perform batch update
        photoCollectionView.performBatchUpdates({
            
            // Delete photos from collectioView and collection
            for indexPath in self.selectedPhotoCells {
                self.photoCollectionView.deleteItems(at: [indexPath])
                self.photos.remove(at: indexPath.item)
            }
            
            // Delete photos from data store
            for indexPath in self.selectedPhotoCells {
                let aPhoto = fetchedPhotosController.object(at: indexPath)
                selectedPhotos.append(aPhoto)
            }
            
            performUIUpdatesOnMain {
                for aPhoto in selectedPhotos {
                    print("removePhotos \(aPhoto.title)")
                    self.dataController.viewContext.delete(aPhoto)
                }
                
                try? self.dataController.viewContext.save()
            }
        }) {(completion) in
            
            // Fetch remaining photos from the data store
            self.setupFetchedPhotosController(doRemoveAll: true)
            
            // Reset
            //            self.isEditingPhotos = false
            self.removePhotosButton?.isEnabled = false
            self.createNewPhotosButton()
            self.newPhotosButton?.isEnabled = true
            self.resetSelectedPhotoCells()
        }
    }
    
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
                print("photoAlbumController - fetchPhotosController - performFetch results \(results.count)")
                if doRemoveAll {
                    self.photos.removeAll()
                }
                self.photos = results

                print("photoAlbumController - fetchPhotosController - performFetch photos \(self.photos.count)")
            }
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    // MARK: configure - configure the flowLayout
    
    func configure(flowLayout: UICollectionViewFlowLayout, withSpace space: CGFloat, withColumns numOfColumns: CGFloat, withRows numOfRows: CGFloat) {
        
        let width: CGFloat = (UIScreen.main.bounds.size.width - ((numOfColumns + 1) * space)) / numOfColumns
        let height: CGFloat = (photoCollectionView.frame.size.height - ((numOfRows + 1) * space)) / numOfRows
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: width, height: height)
    }
    
    // MARK: searchPhotoCollectionFor - search Flickr photo collection for location pin
    
    func searchPhotoCollectionFor(_ pin: Pin, _ searchPage: Int?, completionHandlerForSearchPhotoCollection: @escaping (_ success: Bool, _ result: [FlickrPhoto]?, _ error: String?) -> Void) {
        
        print("searchPhotoCollectionFor - searchPage: \(searchPage)")
                
        FlickrClient.sharedInstance().getPhotosForCoordinate(pin.latitude, pin.longitude, searchPage) { (results, error) in
            
            guard (error == nil) else {
                completionHandlerForSearchPhotoCollection(false, nil, (error?.userInfo[NSLocalizedDescriptionKey] as! String))
                return
            }
            
            performUIUpdatesOnMain {
                if let results = results {
                    completionHandlerForSearchPhotoCollection(true, results, nil)
                    print("searchPhotoCollectionFor - photos - \(results.count)")
                } else {
                    completionHandlerForSearchPhotoCollection(false, nil, "Cannot load photos")
                }
            }
        }
    }
    
    // MARK: savePhotosFor - add photos to the location pin's photos array in data store
    
    func savePhotosFor(_ pin: Pin, from newCollection: [FlickrPhoto], completionHandlerForPhotoSave: @escaping (_ success: Bool) -> Void) {
        
        print("MapView savePhotoFor - newPhotos: \(newCollection.count)")
        
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
                                print("savePhotoImageFor photo title: \(mediumURL)")
                            }
                        }
                    }
                }
            }
        }
        completionHandlerForPhotoImageSave(true, nil)
    }
    
    // MARK: displayPhotos - dipplay photos in collection view
    
    func displayPhotos(completionHandlerForDisplayPhotos: @escaping (_ success: Bool) -> Void) {
        
        print("displayPhotosFor - photos count: \(photos.count)")
        
        self.isLoadingFlickrPhotos = false
        self.setupFetchedPhotosController(doRemoveAll: true)
        
        // Display new set of photos for the pin location
        if (self.photos.count > 0) {
            let delay = DispatchTime.now() + .seconds(1)
            DispatchQueue.main.asyncAfter(deadline: delay) {
                completionHandlerForDisplayPhotos(true)
            }
            print("displayPhotosFor - dispatchQueue self.photos.count: \(self.photos.count)")
        } else {
            completionHandlerForDisplayPhotos(true)
        }
    }
    
    // MARK: downloadFlickrPhotosFor - download new Flickr photo collection

    func downloadFlickrPhotosFor(_ pin: Pin) {
        
        // Initialize
        PhotoAlbumViewController.hasFlickrPhoto = true
        
        searchPhotoCollectionFor(pin, FlickrClient.searchPage) { (success, result, error) in
            
            if success {
                print("downloadFlickrPhotosFor count: \(pin.photos?.count)")

                if let result = result,
                    result.count == 0 {
                    self.appDelegate.presentAlert(self, "No photos available")
                } else {
                
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
                }
            } else {
                self.displayError(error)
            }
            self.isLoadingFlickrPhotos = false
        }
    }
    
    // Helpers
    
    // MARK: createNewPhotosButton - create and set the new collection button
    
    private func createNewPhotosButton() {
        
        var toolbarButtons: [UIBarButtonItem] = [UIBarButtonItem]()
        
        // use empty flexible space bar button to center the new collection button
        let flexButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)
        
        newPhotosButton = UIBarButtonItem(title: "New Collection", style: .plain, target: self, action: #selector(newCollectionPressed))
        toolbarButtons.append(flexButton)
        toolbarButtons.append(newPhotosButton!)
        toolbarButtons.append(flexButton)
        self.setToolbarItems(toolbarButtons, animated: true)
    }

    // MARK: createRemovePhotosButton - create and set the remove photoes button
    
    private func createRemovePhotosButton() {
        
        var toolbarButtons: [UIBarButtonItem] = [UIBarButtonItem]()
        
        // use empty flexible space bar button to center the new collection button
        let flexButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)
        
        removePhotosButton = UIBarButtonItem(title: "Remove Selected Photos", style: .plain, target: self, action: #selector(removePhotosPressed))
        toolbarButtons.append(flexButton)
        toolbarButtons.append(removePhotosButton!)
        toolbarButtons.append(flexButton)
        self.setToolbarItems(toolbarButtons, animated: true)
    }
}

// MARK: MKMapViewDelegate

extension PhotoAlbumViewController: MKMapViewDelegate {
    
    // MARK: mapView - viewFor - Create a view for the annotation
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
                
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
            print("PhotoAlbum mapView viewFor")
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
}

// MARK: UICollectionViewDelegate, UICollectionViewDataSource

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    // MARK: numberOfSections - collectionView - Collection View Data Source
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        print("PhotoAlbumViewController - numberOfSections")
        return fetchedPhotosController.sections?.count ?? 1
    }
    
    // MARK: collectionView - numberOfItemsInSection - Collection View Data Source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        // Set number of photos to display
        var photoCount: Int
        if (isLoadingFlickrPhotos) {
            photoCount = Int(FlickrClient.ParameterValues.PerPage)!
            print("collectionView isLoadingFlickrPhotos numberOfItemsInSection: \(photoCount)")
        } else {
            photoCount = photos.count
            print("collectionView numberOfItemsInSection: \(photoCount)")
        }
        
        return photoCount
    }
    
    // MARK: collectionView - cellForItemAt - Collection View Cell Item
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        print("collectionView cellForItemAt \(indexPath)")

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionCell", for: indexPath) as! PhotoCollectionCell

        // Initialize
        cell.photoImage?.image = UIImage()
        
        print("collectionView cellForItemAt hasFlickrPhoto: \(PhotoAlbumViewController.hasFlickrPhoto)")

        if (PhotoAlbumViewController.hasFlickrPhoto) {
            cell.activityIndicatorView.startAnimating()
        } 
        
        // Display photo
        if (!isLoadingFlickrPhotos) {
            if indexPath.item < photos.count {
                print("cellForItemAt indexPath.item: \(indexPath.item) photos.count: \(photos.count)")
                let aPhoto = fetchedPhotosController.object(at: indexPath)
                if let imageData = aPhoto.image {
                    cell.photoImage?.image = UIImage(data: imageData)
                    cell.activityIndicatorView.stopAnimating()
                    print("image cellForItemAt object \(indexPath) , photo count \(photos.count), title: \(aPhoto.title)")
                }
            }
        }
        
        toggleSelectedPhoto(cell, at: indexPath)
        
        return cell
    }
    
    // MARK: collectionView - didSelectItemAt - Select an item in Collection View
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath:IndexPath) {

        // Add or remove the highlighted cells to the list
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCollectionCell
        
        setSelectedPhoto(cell, at: indexPath)
        
        // create and set action button
        if selectedPhotoCells.count > 0 {
            newPhotosButton?.isEnabled = false
            createRemovePhotosButton()
            removePhotosButton?.isEnabled = true
        } else {
            removePhotosButton?.isEnabled = false
            createNewPhotosButton()
            newPhotosButton?.isEnabled = true
        }
    }
}

// MARK: - PhotoAlbumViewController (Configure UI)

extension PhotoAlbumViewController {
    
    // MARK: setUIActions - Set UI action buttons
    
    func setUIActions() {
        if (isLoadingFlickrPhotos) {
//            isEditingPhotos = false
            newPhotosButton?.isEnabled = false
            removePhotosButton?.isEnabled = false
         } else {
//            isEditingPhotos = true
            newPhotosButton?.isEnabled = true
            removePhotosButton?.isEnabled = false
        }
    }
    
    // MARK: setUIForDownloadingPhotos - Set user interface for downloading photos
    
    func setUIForDownloadingPhotos() {
        newPhotosButton?.isEnabled = false
        removePhotosButton?.isEnabled = false
        photoCollectionView.reloadData()
    }
    
    // MARK: resetUIAfterDownloadingPhotos - Reset user interface after download
    
    func resetUIAfterDownloadingPhotos() {
        newPhotosButton?.isEnabled = true
        removePhotosButton?.isEnabled = false
        photoCollectionView.reloadData()
    }
    
    // MARK: deleteAllPhotos - Delete all photos for the pin from data store
    
    func deleteAllPhotos() {
        
        for aPhoto in self.photos {
            print("deleteAllPhotos \(aPhoto.title)")
            dataController.viewContext.delete(aPhoto)
        }
        try? dataController.viewContext.save()
        
        // Reset
        self.photos.removeAll()
        
        print("deleteAllPhotos count: \(self.photos.count)")
    }
    
    // MAKR: displayError - Display error
    
    func displayError(_ errorString: String?) {
        
        print(errorString!)
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: setSelectedPhoto - set selected photos from collection cell selection
    
    func setSelectedPhoto(_ cell: PhotoCollectionCell, at indexPath: IndexPath) {
        
//        // Do not allow to select photos if not in edit photos mode
//        if (!isEditingPhotos) {
//            print("setSelectedPhoto isEditingPhotos: \(isEditingPhotos)")
//            return
//        }
        
        // Set photo cell selection
        if let index = selectedPhotoCells.index(of: indexPath) {
            selectedPhotoCells.remove(at: index)
        } else {
            selectedPhotoCells.append(indexPath)
        }
        
        toggleSelectedPhoto(cell, at: indexPath)
    }
    
    // MARK: toggleSelectedPhoto - toggle the selected photo cell in collection view
    
    func toggleSelectedPhoto(_ cell: PhotoCollectionCell, at indexPath: IndexPath) {
        
        // Toggle photo selection
        if let _ = selectedPhotoCells.index(of: indexPath) {
            cell.alpha = 0.375
        } else {
            cell.alpha = 1.0
        }
    }
    
    // MARK: resetSelectedPhotoCells - reset the selected photo cell array
    
    func resetSelectedPhotoCells() {
        
//        // Do not allow to reset photo selection if in edit mode
//        if (isEditingPhotos) {
//            return
//        }
        
        // Reset selected cells
        selectedPhotoCells.removeAll()
        photoCollectionView.reloadData()
    }
}
