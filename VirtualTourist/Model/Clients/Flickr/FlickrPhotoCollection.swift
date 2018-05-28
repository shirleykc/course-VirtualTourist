//
//  FlickrPhotoCollection.swift
//  VirtualTourist
//
//  Created by Shirley on 4/22/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation
import UIKit

// MARK: - FlickrPhotoCollection

class FlickrPhotoCollection {
    
    // MARK: Properties
    
    var photos: [FlickrPhoto]?
    
    // MARK: Initializers
    
    // MARK: Shared Instance
    
    class func sharedInstance() -> FlickrPhotoCollection {
        
        struct Singleton {
            static var sharedInstance = FlickrPhotoCollection()
        }
        return Singleton.sharedInstance
    }
    
    // Build a collection of Photo from dictionary collection
    
    class func photosFromResults(_ results: [[String:AnyObject]]) -> Void {
        
        var photos = [FlickrPhoto]()
        
        // iterate through array of dictionaries, each photo is a dictionary
        for result in results {
            let photo = FlickrPhoto(dictionary: result)
            photos.append(photo)
        }
        
        self.sharedInstance().photos = photos
    }
}
