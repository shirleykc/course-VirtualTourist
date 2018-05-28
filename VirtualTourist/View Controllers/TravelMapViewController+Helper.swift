//
//  TravelMapViewController+Helper.swift
//  VirtualTourist
//
//  Created by Shirley on 5/28/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation
import UIKit

// MARK: TravelMapViewController+Helper

extension TravelMapViewController {

    // MARK: createRemovePinsBanner - create and set the remove pins banner
    
    func createRemovePinsBanner() {
        
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
    
    func createEditButton(_ navigationItem: UINavigationItem) {
        
        var rightButtons: [UIBarButtonItem] = [UIBarButtonItem]()
        editButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.edit, target: self, action: #selector(editPin))
        rightButtons.append(editButton!)
        navigationItem.setRightBarButtonItems(rightButtons, animated: true)
    }
    
    // MARK: createDoneButton - create and set the Done bar buttons
    
    func createDoneButton(_ navigationItem: UINavigationItem) {
        
        var rightButtons: [UIBarButtonItem] = [UIBarButtonItem]()
        doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(done))
        rightButtons.append(doneButton!)
        navigationItem.setRightBarButtonItems(rightButtons, animated: true)
    }
    
}
