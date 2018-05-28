//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Shirley on 3/18/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit

// MARK: - FlickrClient: NSObject

class FlickrClient : NSObject {
    
    // MARK: Properties
    
    // Search page for Flickr photos, default to 1, otherwise a random page number generated from previous search
    static var searchPage: Int?

    // shared session
    var session = URLSession.shared
    
    // MARK: Initializers
    
    override init() {
        super.init()
    }
    
    // MARK: Flickr GET Method
    
    func taskForGETMethod(parameters: [String:AnyObject], completionHandlerForGET: @escaping (_ result: [String:AnyObject]?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        /* 1. Set the parameters */
        var parametersWithApiKey = parameters
        parametersWithApiKey[FlickrClient.ParameterKeys.APIKey] = FlickrClient.ParameterValues.APIKey as AnyObject?
        
        /* 2/3. Build the URL, Configure the request */
        let request = NSMutableURLRequest(url: flickrURLFromParameters(parametersWithApiKey, withPathExtension: nil))
        
        /* 4. Make the request */
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request: \(error!)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandlerForGET)
        }
        
        /* 7. Start the request */
        task.resume()
        
        return task
    }
    
    // MARK: Helper for Creating a URL from Parameters
    
    private func flickrURLFromParameters(_ parameters: [String:AnyObject], withPathExtension: String? = nil) -> URL {
        
        var components = URLComponents()
        components.scheme = FlickrClient.FlickrConstants.ApiScheme
        components.host = FlickrClient.FlickrConstants.ApiHost
        components.path = FlickrClient.FlickrConstants.ApiPath + (withPathExtension ?? "")
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    // MARK: given raw JSON, return a usable Foundation object
    
    private func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: [String:AnyObject]?, _ error: NSError?) -> Void) {
        
        /* parse the data */
        
        let parsedResult: [String:AnyObject]!
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
            return
        }
        
        /* GUARD: Did Flickr return an error (stat != ok)? */
        guard let stat = parsedResult[FlickrClient.ResponseKeys.Status] as? String,
            stat == FlickrClient.ResponseValues.OKStatus else {
            let userInfo = [NSLocalizedDescriptionKey : "Flickr API returned an error. See error code and message in \(parsedResult)"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
            return
        }
        
        /* GUARD: Is "photos" key in our result? */
        guard let photosDictionary = parsedResult[FlickrClient.ResponseKeys.Photos] as? [String:AnyObject] else {
            let userInfo = [NSLocalizedDescriptionKey : "Cannot find keys '\(FlickrClient.ResponseKeys.Photos)' in \(parsedResult)"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
            return
        }
        
        /* GUARD: Is "pages" key in the photosDictionary? */
        guard let totalPages = photosDictionary[FlickrClient.ResponseKeys.Pages] as? Int else {
            let userInfo = [NSLocalizedDescriptionKey : "Cannot find key '\(FlickrClient.ResponseKeys.Pages)' in \(photosDictionary)"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
            return
        }
        
        // pick a random page for the next search
        let pageLimit = min(totalPages, 100)
        FlickrClient.searchPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
        
        completionHandlerForConvertData(photosDictionary, nil)
    }
    
    // MARK: getPhotosForCoordinate
    
    func getPhotosForCoordinate(_ latitude: Double, _ longitude: Double, _ page: Int?, completionHandlerForPhotos: @escaping (_ result: [FlickrPhoto]?, _ error: NSError?) -> Void) {
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let parameters = [
            FlickrClient.ParameterKeys.Latitude: latitude,
            FlickrClient.ParameterKeys.Longitude: longitude,
            FlickrClient.ParameterKeys.Method: FlickrClient.ParameterValues.SearchMethod,
            FlickrClient.ParameterKeys.SafeSearch: FlickrClient.ParameterValues.UseSafeSearch,
            FlickrClient.ParameterKeys.Extras: FlickrClient.ParameterValues.MediumURL,
            FlickrClient.ParameterKeys.Format: FlickrClient.ParameterValues.ResponseFormat,
            FlickrClient.ParameterKeys.NoJSONCallback: FlickrClient.ParameterValues.DisableJSONCallback,
            FlickrClient.ParameterKeys.Page: (page ?? 1),
            FlickrClient.ParameterKeys.PerPage: FlickrClient.ParameterValues.PerPage
        ] as [String : AnyObject]
        
        /* 2. Make the request */
        let _ = taskForGETMethod(parameters: parameters as [String:AnyObject]) { (results, error) in
            
            /* 3. Send the desired value(s) to completion handler */
            if let error = error {
                completionHandlerForPhotos(nil, error)
            } else {
                /* GUARD: Is the "photo" key in photosDictionary? */
                guard let photosDictionary = results,
                    let photosArray = photosDictionary[FlickrClient.ResponseKeys.Photo] as? [[String: AnyObject]] else {
                    let userInfo = [NSLocalizedDescriptionKey : "Cannot find key '\(FlickrClient.ResponseKeys.Photo)' in \(results)"]
                    completionHandlerForPhotos(nil, NSError(domain: "getPhotosForCoordinate", code: 1, userInfo: userInfo))
                    return
                }
                
                FlickrPhotoCollection.photosFromResults(photosArray)
                completionHandlerForPhotos(FlickrPhotoCollection.sharedInstance().photos, nil)
            }
        }
    }
    
    // MARK: Send URL Request to launch photo image URL
    
    func taskForURL(mediumURL: String, completionHandlerForURL: @escaping (_ data: Data?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        /* 1. Set the parameters */
        
        /* 2/3. Build the URL, Configure the request */
        let imageURL = URL(string: mediumURL)
        let request = URLRequest(url: imageURL! as URL)
        
        /* 4. Make the request */
        let task = session.dataTask(with: request) { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForURL(nil, NSError(domain: "taskForURL", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request: \(error!)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            completionHandlerForURL(data as Data?, nil)
        }
        
        /* 7. Start the request */
        task.resume()
        
        return task
    }
    
    func getPhotoImageFrom(_ mediumURL: String, completionHandlerForPhotoImage: @escaping (_ data: Data?, _ error: NSError?) -> Void) {
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        
        /* 2. Make the request */
        let _ = taskForURL(mediumURL: mediumURL) { (results, error) in
            
            /* 3. Send the desired value(s) to completion handler */
            if let error = error {
                completionHandlerForPhotoImage(nil, error)
            } else {
                completionHandlerForPhotoImage(results, nil)
            }
        }
    }
    
    // MARK: Shared Instance
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
}
