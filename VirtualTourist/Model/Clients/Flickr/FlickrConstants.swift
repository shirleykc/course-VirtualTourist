//
//  FlickrConstants.swift
//  VirtualTourist
//
//  Created by Shirley on 3/18/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit

// MARK: - FlickrClient (Constants)

extension FlickrClient {
    
    // MARK: Flickr Constants
    
    struct FlickrConstants {
        
        // MARK: URLs
        static let ApiScheme = "https"
        
        // MARK: Flickr API
        static let ApiHost = "api.flickr.com"
        static let ApiPath = "/services/rest"
        
        static let SearchBBoxHalfWidth = 1.0
        static let SearchBBoxHalfHeight = 1.0
        static let SearchLatRange = (-90.0, 90.0)
        static let SearchLonRange = (-180.0, 180.0)
    }
    
    // MARK: Flickr Parameter Keys
    
    struct ParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let GalleryID = "gallery_id"
        static let Extras = "extras"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let SafeSearch = "safe_search"
        static let Text = "text"
        static let BoundingBox = "bbox"
        static let Latitude = "lat"
        static let Longitude = "lon"
        static let Page = "page"
        static let PerPage = "per_page"
    }
    
    // MARK: Flickr Parameter Values
    
    struct ParameterValues {
        static let SearchMethod = "flickr.photos.search"
        static let APIKey = "da06c54180915b15f8b6812bd758b440"
        static let ResponseFormat = "json"
        static let DisableJSONCallback = "1" /* 1 means "yes" */
        static let GalleryPhotosMethod = "flickr.galleries.getPhotos"
        static let GalleryID = "5704-72157622566655097"
        static let MediumURL = "url_m"
        static let UseSafeSearch = "1"
        static let PerPage = "51"
    }
    
    // MARK: Flickr Response Keys
    
    struct ResponseKeys {
        static let Status = "stat"
        static let Photos = "photos"
        static let Photo = "photo"
        static let ID = "id"
        static let Title = "title"
        static let MediumURL = "url_m"
        static let Pages = "pages"
        static let Total = "total"
    }
    
    // MARK: Flickr Response Values
    
    struct ResponseValues {
        static let OKStatus = "ok"
    }
}
