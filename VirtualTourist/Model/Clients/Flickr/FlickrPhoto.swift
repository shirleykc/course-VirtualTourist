//
//  FlickrPhoto.swift
//  VirtualTourist
//
//  Created by Shirley on 4/21/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

// MARK: - FlickrPhoto

struct FlickrPhoto {
    
    // MARK: Properties
    
    let title: String?
    let mediumURL: String?
    
    // MARK: Initializers
    
    // construct a FlickrPhoto from a dictionary
    init(dictionary: [String:AnyObject]) {
        title = dictionary[FlickrClient.ResponseKeys.Title] as? String
        mediumURL = dictionary[FlickrClient.ResponseKeys.MediumURL] as? String
    }
}

// MARK: - FlickrPhoto: Equatable

extension FlickrPhoto: Equatable {}

func ==(lhs: FlickrPhoto, rhs: FlickrPhoto) -> Bool {
    return lhs.mediumURL == rhs.mediumURL
}

