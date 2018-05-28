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
        
        // Grab the photos
        setupFetchedPhotosController(doRemoveAll: true)
        
        isLoadingFlickrPhotos = (photos.count == 0) ? true : false
        
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
        
        // Initialize
        isLoadingFlickrPhotos = true
        
        setUIForDownloadingPhotos()
        deleteAllPhotos()
        
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
                    self.dataController.viewContext.delete(aPhoto)
                }
                
                try? self.dataController.viewContext.save()
            }
        }) {(completion) in
            
            // Fetch remaining photos from the data store
            self.setupFetchedPhotosController(doRemoveAll: true)
            
            // Reset
            self.removePhotosButton?.isEnabled = false
            self.createNewPhotosButton()
            self.newPhotosButton?.isEnabled = true
            self.resetSelectedPhotoCells()
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
         return fetchedPhotosController.sections?.count ?? 1
    }
    
    // MARK: collectionView - numberOfItemsInSection - Collection View Data Source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        // Set number of photos to display
        var photoCount: Int
        if (isLoadingFlickrPhotos) {
            photoCount = Int(FlickrClient.ParameterValues.PerPage)!
        } else {
            photoCount = photos.count
        }
        
        return photoCount
    }
    
    // MARK: collectionView - cellForItemAt - Collection View Cell Item
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionCell", for: indexPath) as! PhotoCollectionCell

        // Initialize
        cell.photoImage?.image = UIImage()
        
        if (PhotoAlbumViewController.hasFlickrPhoto) {
            cell.activityIndicatorView.startAnimating()
        } 
        
        // Display photo
        if (!isLoadingFlickrPhotos) {
            if indexPath.item < photos.count {
                let aPhoto = fetchedPhotosController.object(at: indexPath)
                if let imageData = aPhoto.image {
                    cell.photoImage?.image = UIImage(data: imageData)
                    cell.activityIndicatorView.stopAnimating()
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
