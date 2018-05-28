//
//  PhotoAlbumViewController+Helper.swift
//  VirtualTourist
//
//  Created by Shirley on 5/28/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation
import UIKit

// MARK: - PhotoAlbumViewController+Helper (Configure UI)

extension PhotoAlbumViewController {
    
    // MARK: createNewPhotosButton - create and set the new collection button
    
    func createNewPhotosButton() {
        
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
    
    func createRemovePhotosButton() {
        
        var toolbarButtons: [UIBarButtonItem] = [UIBarButtonItem]()
        
        // use empty flexible space bar button to center the remove photo button
        let flexButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)
        
        removePhotosButton = UIBarButtonItem(title: "Remove Selected Photos", style: .plain, target: self, action: #selector(removePhotosPressed))
        toolbarButtons.append(flexButton)
        toolbarButtons.append(removePhotosButton!)
        toolbarButtons.append(flexButton)
        self.setToolbarItems(toolbarButtons, animated: true)
    }
    
    // MARK: setUIActions - Set UI action buttons
    
    func setUIActions() {
        if (isLoadingFlickrPhotos) {
            newPhotosButton?.isEnabled = false
            removePhotosButton?.isEnabled = false
        } else {
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
    
    // MAKR: displayError - Display error
    
    func displayError(_ errorString: String?) {
        
        print(errorString!)
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: setSelectedPhoto - set selected photos from collection cell selection
    
    func setSelectedPhoto(_ cell: PhotoCollectionCell, at indexPath: IndexPath) {
        
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
        
        // Reset selected cells
        selectedPhotoCells.removeAll()
        photoCollectionView.reloadData()
    }
    
}
