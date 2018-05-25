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
    
    /// The location whose photos are being displayed
    var pin: Pin!
    var photos = [Photo]()
    
    var dataController:DataController!
    
    var fetchedPhotosController:NSFetchedResultsController<Photo>!
    var fetchedPinsController:NSFetchedResultsController<Pin>!
    
    var isLoadingFlickrPhotos: Bool = false
    
    static var hasFlickrPhoto: Bool = false
    
    // MARK: Outlets

    // The map. See the setup in the Storyboard file. Note particularly that the view controller
    // is set up as the map view's delegate.
    @IBOutlet weak var mapView: MKMapView!
    
//    @IBOutlet weak var photoFlowLayout: UICollectionViewFlowLayout!
    //    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    // MARK: Life Cycle
    
    // MARK: viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Grab the app delegate */
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        photoCollectionView.delegate = self
        
        mapView.delegate = self
        
        // add annotation to the map
        mapView.addAnnotation(annotation)
        mapView.setCenter(annotation.coordinate, animated: true)
        mapView.setRegion(MKCoordinateRegionMake(annotation.coordinate, span), animated: true)
        print("mapView addAnnotatiopin")
        
        /* Grab the photos */
        fetchedPhotos()
        
        isLoadingFlickrPhotos = (photos.count == 0) ? true : false
        
        // Implement flowLayout here.
        let photoFlowLayout = photoCollectionView.collectionViewLayout as? UICollectionViewFlowLayout
        configure(flowLayout: photoFlowLayout!, withSpace: 2, withColumns: 3, withRows: 4)
        
        setUIActions()
        
        // If empty photo collection, then download new set of photos
        if (isLoadingFlickrPhotos) {
            setUIForDownloadingPhotos()
            downloadFlickrPhotosFor(pin)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        photoCollectionView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        photoCollectionView.reloadData()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        fetchedPhotosController = nil
    }
    
    func setupFetchedPhotosController() -> NSFetchedResultsController<Photo> {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", argumentArray: [pin!])
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let fetchController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchController.delegate = self
        
        return fetchController
    }
    
    func fetchedPhotos() {
        fetchedPhotosController = setupFetchedPhotosController()
        
        do {
            try fetchedPhotosController.performFetch()
            if let results = fetchedPhotosController?.fetchedObjects {
                print("photoAlbumController - fetchPhotosController - performFetch results \(results.count)")
                self.photos.removeAll()
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
    
    func searchPhotoCollectionFor(_ pin: Pin, _ searchPage: Int, completionHandlerForSearchPhotoCollection: @escaping (_ success: Bool, _ result: [Photo]?, _ error: String?) -> Void) {

        print("searchPhotoCollectionFor - searchPage: \(searchPage)")

        var photos = [Photo]()
        
        FlickrClient.sharedInstance().getPhotosForCoordinate(pin.latitude, pin.longitude, searchPage) { (results, error) in

            guard (error == nil) else {
                completionHandlerForSearchPhotoCollection(false, nil, (error?.userInfo[NSLocalizedDescriptionKey] as! String))
                return
            }
           
            performUIUpdatesOnMain {
                if let results = results {
                    if results.count > 0 {
                        PhotoAlbumViewController.hasFlickrPhoto = true
                        for aPhoto in results {
                            self.savePhotoFor(pin, from: aPhoto) { (success, result, error) in
                                if success {
                                    if let newPhoto = result {
                                        photos.append(newPhoto)
                                    }
                                }
                                
                            }
                        }
 //                       photos = self.savePhotosFor(pin, from: result)
                        completionHandlerForSearchPhotoCollection(true, photos, nil)
                    } else {
                        PhotoAlbumViewController.hasFlickrPhoto = false
                        FlickrClient.searchPage = 1
                        completionHandlerForSearchPhotoCollection(false, photos, "No photos available")
                    }
                    print("searchPhotoCollectionFor - photos - \(results.count)")

                } else {
                    completionHandlerForSearchPhotoCollection(false, nil, "Cannot load photos")
                }

            }
        }
    }
   
    // Adds a new `photo` to the the `pin`'s `photoCollection` array
    
    func savePhotoFor(_ pin: Pin, from newPhoto: FlickrPhoto, completionHandlerForPhotoSave: @escaping (_ success: Bool, _ result: Photo?, _ error: String?) -> Void) {
        
        print("MapView savePhotoFor - newPhoto: \(newPhoto.title)")
        
        // Save photo urls and title for pin
        if let mediumURL = newPhoto.mediumURL,
            let imageURL = URL(string: mediumURL) {
            performUIUpdatesOnMain {
                let photo = Photo(context: self.dataController.viewContext)
                photo.creationDate = Date()
                photo.title = newPhoto.title
                photo.url = mediumURL
                if let imageData = try? Data(contentsOf: imageURL) {
                    photo.image = imageData
                }
                photo.pin = pin
                try? self.dataController.viewContext.save()

                print("addPhoto \(photo.title)")
                completionHandlerForPhotoSave(true, photo, nil)
            }
        }
        completionHandlerForPhotoSave(false, nil, "Could not save photo")
    }
    
    func savePhotosFor(_ pin: Pin, from newCollection: [FlickrPhoto]) -> [Photo] {
        
        print("MapView savePhotosFor - newCollection: \(newCollection.count)")
        
        return addPhotosFor(pin, from: newCollection)
    }
    
//    func savePhotosFor(_ pin: Pin, from newCollection: [FlickrPhoto], completionHandlerForSavePhotos: @escaping (_ success: Bool, _ result: [Photo]?, _ error: String?) -> Void) {
//
//        print("savePhotosFor - searchPage: \(FlickrClient.searchPage) newCollection count: \(newCollection.count)")
//                
//        performUIUpdatesOnMain {
//            let result = self.addPhotosFor(pin, from: newCollection)
//            self.fetchedPhotos()
// //           self.photoCollectionView.reloadData()
//            completionHandlerForSavePhotos(true, result, nil)
//        }
//    }
    
    func displayPhotosFor(completionHandlerForDisplayPhotos: @escaping (_ success: Bool, _ error: String?) -> Void) {
        
        print("displayPhotosFor - photos count: \(photos.count)")
        
        self.isLoadingFlickrPhotos = false
        self.fetchedPhotos()
        
        // Display new set of photos for the pin location
        if (self.photos.count > 0) {
            let delay = DispatchTime.now() + .seconds(1)
            DispatchQueue.main.asyncAfter(deadline: delay) {
//                self.photoCollectionView.reloadData()
                completionHandlerForDisplayPhotos(true, nil)
            }
            print("displayPhotosFor - dispatchQueue self.photos.count: \(self.photos.count)")
            //            performUIUpdatesOnMain {
            //
            //                self.photoCollectionView.reloadData()
            //            }
        }
        
 //       completionHandlerForDisplayPhotos(true, nil)
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
    
    // MARK: New Collection - get new Flickr collection
    
    func downloadFlickrPhotosFor(_ pin: Pin) {
        // Initialize
        PhotoAlbumViewController.hasFlickrPhoto = true
        
        searchPhotoCollectionFor(pin, FlickrClient.searchPage) { (success, result, error) in
            performUIUpdatesOnMain {
                if success {
                    print("downloadFlickrPhotosFor count: \(pin.photos?.count)")
                    
                    self.displayPhotosFor() { (success, error) in
                        if success {
                            // reset user interface
                            self.resetUIAfterDownloadingPhotos()
//                            self.photoCollectionView.reloadData()
                        } else {
                            print(error)
                            self.appDelegate.presentAlert(self, "Unable to download photos available")
                        }
                    }
                } else {
                    if let result = result,
                        result.count == 0 {
                        self.appDelegate.presentAlert(self, "No photos available")
                    } else {
                        self.displayError(error)
                    }
                }
 
            }
        }
    }
    
    @IBAction func newCollectionPressed(_ sender: AnyObject) {
        print("start newCollectionPressed")

        // Initialize
        isLoadingFlickrPhotos = true

        setUIForDownloadingPhotos()
        deleteAllPhotos()
//        fetchedPhotos()
//        photoCollectionView.reloadData()
        
//        setupFetchedPhotosController()
        
//        if let currentPage = searchPage {
//            searchPage = currentPage + 1
//        } else {
//            searchPage = 1
//        }
        
        print("newCollectionPressed searchPage: \(FlickrClient.searchPage)")
        
        downloadFlickrPhotosFor(pin)
    }
    

}

extension PhotoAlbumViewController: MKMapViewDelegate {
    
    // MARK: mapView - viewFor - Create a view with callout accessory view
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
                
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
            //            pinView!.detailCalloutAccessoryView = UIButton()
            print("PhotoAlbum mapView viewFor")
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    // MARK: collectionView - Collection View Data Source
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        print("PhotoAlbumViewController - numberOfSections")
        return fetchedPhotosController.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        // Set number of photos to display
//        if (PhotoAlbumViewController.hasFlickrPhoto) {
//            photoCount = photos.count
//            print("collectionView hasFlickrPhoto numberOfItemsInSection: \(photoCount)")
//        } else
        var photoCount: Int
        if (isLoadingFlickrPhotos) {
            photoCount = Int(FlickrClient.ParameterValues.PerPage)!
            print("collectionView isLoadingFlickrPhotos numberOfItemsInSection: \(photoCount)")
        } else {
            photoCount = photos.count
            print("collectionView numberOfItemsInSection: \(photoCount)")
        }
        
        return photoCount
//        return photos.count
    }
    
    // MARK: collectionView - Collection View Cell Item
    
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
            let aPhoto = fetchedPhotosController.object(at: indexPath)
            
            if let imageData = aPhoto.image {
                cell.photoImage?.image = UIImage(data: imageData)
                cell.activityIndicatorView.stopAnimating()
                PhotoAlbumViewController.hasFlickrPhoto = false
                print("image cellForItemAt object \(indexPath) , photo count \(photos.count), title: \(aPhoto.title)")
            }
        }
        
        return cell
    }
    
    // MARK: collectionView - Select an item in Collection View
    
    //    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath:IndexPath) {
    //
    //        // Launch Meme Detail View
    //        let detailController = storyboard!.instantiateViewController(withIdentifier: "MemeDetailViewController") as! MemeDetailViewController
    //        detailController.meme = allSentMemes[(indexPath as NSIndexPath).row]
    //        navigationController!.pushViewController(detailController, animated: true)
    //
    //    }
    
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
//    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        print("controllerWillChangeContent")
//        blockOperations.removeAll(keepingCapacity: false)
//    }
//
//    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        photoCollectionView.performBatchUpdates({
//            self.blockOperations.forEach { $0.start() }
//        }, completion: { finished in
//            self.blockOperations.removeAll(keepingCapacity: false)
//        })
//        print("controllerDidChangeContent")
//    }
    
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
//        switch type {
//
//        case .delete:
//            print("fetch controller delete")
//            guard let indexPath = indexPath else { return }
//            photoCollectionView.performBatchUpdates({
//                self.photos.remove(at: indexPath.item)
//                self.photoCollectionView.deleteItems(at: [indexPath])
//            }, completion: nil)
////            break
//
//        case .insert:
//            print("fetch controller insert")
//            guard let newIndexPath = newIndexPath else { return }
//            photoCollectionView.performBatchUpdates({
//                self.photos.append(anObject as! Photo)
//                self.photoCollectionView.insertItems(at: [newIndexPath])
//            }, completion: nil)
//            break
//
//
//        case .move:
//            print("fetch controller move")
//            guard let indexPath = indexPath,  let newIndexPath = newIndexPath else { return }
//            photoCollectionView.performBatchUpdates({
//                self.photoCollectionView.moveItem(at: indexPath, to: newIndexPath)
//            }, completion: nil)
//            break
//        case .update:
//            print("fetch controller update - not supported")
//            guard let indexPath = indexPath else { return }
//            photoCollectionView.performBatchUpdates({
//                self.photoCollectionView.reloadItems(at: [indexPath])
//            }, completion: nil)
//            break
//        }
//    }

//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
//        let indexSet = IndexSet(integer: sectionIndex)
//        switch type {
//        case .insert:
//            tableView.insertSections(indexSet, with: .fade)
//            break
//        case .delete:
//            tableView.deleteSections(indexSet, with: .fade)
//            break
//        case .update, .move:
//            fatalError("Invalid change type in controller(_:didChange:atSectionIndex:for:). Only .insert or .delete should be possible.")
//        }
//    }
}

// MARK: - PhotoAlbumViewController (Configure UI)

extension PhotoAlbumViewController {
    
    // MARK: Enable or disable UI
    
    func setUIEnabled(_ enabled: Bool) {
        newCollectionButton.isEnabled = enabled
        
        // adjust new collection button alpha
        if enabled {
            newCollectionButton.alpha = 1.0
        } else {
            newCollectionButton.alpha = 0.5
        }
    }
    
    // MARK: Set UI actions
    
    func setUIActions() {
//        deletePhotos.isEnabled = isEditingPhotos
        if (isLoadingFlickrPhotos) {
            setUIEnabled(false)
        } else {
            setUIEnabled(true)
        }
    }
    
    // MARK: Set user interface for downloading photos
    
    func setUIForDownloadingPhotos() {
        setUIEnabled(false)
        photoCollectionView.reloadData()
    }
    
    // MARK: Reset user interface after download
    
    func resetUIAfterDownloadingPhotos() {
        setUIEnabled(true)
        photoCollectionView.reloadData()
    }
    
    // MARK: Delete all photos for the pin from data store
    
    func deleteAllPhotos() {
        
        for aPhoto in self.photos {
            print("deleteAllPhotos \(aPhoto.title)")
            pin.removeFromPhotos(aPhoto)
            dataController.viewContext.delete(aPhoto)
        }
        try? dataController.viewContext.save()
        
        // Reset
        self.photos.removeAll()
        pin.photos = NSSet()
        
        print("deleteAllPhotos count: \(self.photos.count)")
    }
    
    // MAKR: Display error
    
    func displayError(_ errorString: String?) {
        
        print(errorString!)
        dismiss(animated: true, completion: nil)
    }
}

