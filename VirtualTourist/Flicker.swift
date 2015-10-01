//
//  Flicker.swift
//  VirtualTourist
//
//  Created by Cesar Colorado on 9/17/15.
//  Copyright (c) 2015 Cesar Colorado. All rights reserved.
//

import Foundation
import UIKit

class Flicker:  NSObject {
    
    /* Shared session */
    var session: NSURLSession
    
    /* Flicker CONSTANT */
    var err: NSError? = nil
    let BASE_URL = "https://api.flickr.com/services/rest/"
    let METHOD_NAME = "flickr.photos.search"
    let API_KEY = "f079e6123e4d60e1a18cd977eeb29aba"
    let EXTRAS = "url_m"
    let SAFE_SEARCH = "1"
    let DATA_FORMAT = "json"
    let NO_JSON_CALLBACK = "1"
    let page = "1"
    let BOUNDING_BOX_HALF_WIDTH = 1.0
    let BOUNDING_BOX_HALF_HEIGHT = 1.0
    let LAT_MIN = -90.0
    let LAT_MAX = 90.0
    let LON_MIN = -180.0
    let LON_MAX = 180.0
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    func getmorepages(latitude: Double, longitude: Double, completionHandler: (urls: [String]?, success: Bool, error: String?)-> Void) {
        /* 1. Set the parameters */
        let methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "bbox": createBoundingBoxString(latitude, longitude: longitude),
            "safe_search": SAFE_SEARCH,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK,
        ]
        
        /* 2. Build the URL */
        let urlString = BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        
        /* 3. Configure the request */
        let request = NSMutableURLRequest(URL: url)
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) {data, response, error in
            if error != nil {
                completionHandler(urls: nil, success: false, error: "There was an error contacting the Parse server")
            } else {
                
                /* 5/6. Parse the data and use the data (happens in completion handler) */
                
                let response = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: nil) as? [String : AnyObject]
                
                if let error = response!["error"] as? String {
                    completionHandler(urls: nil, success: false, error: error)
                }else{
                    if let photosDictionary = response?["photos"] as? [String:AnyObject]{
                        if let totalPages = photosDictionary["pages"] as? Int {
                            /* Flickr API - will only return up the 4000 images (100 per page * 40 page max) */
                            let pageLimit = min(totalPages, 40)
                            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                            self.getPictures(latitude, longitude: longitude, pageNumber: randomPage, completionHandler: { (urls, success, error) -> Void in
                                completionHandler(urls: urls, success: true, error: nil)
                            })
                        }
                    }
                }
                
            }
        }
        /* 7. Start the request */
        task.resume()
    }
    func getPictures(latitude: Double, longitude: Double, pageNumber: Int, completionHandler: (urls: [String]?, success: Bool, error: String?) -> Void) {
        var methodArguments: [String : AnyObject]

        /* 1. Set the parameters */
        methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "bbox": createBoundingBoxString(latitude, longitude: longitude),
            "safe_search": SAFE_SEARCH,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK,
            "page": pageNumber
        ]
        
        /* 2. Build the URL */
        let urlString = BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        
        /* 3. Configure the request */
        let request = NSMutableURLRequest(URL: url)
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) {data, response, error in
            if error != nil {
                completionHandler(urls: nil, success: false, error: "There was an error contacting the Parse server")
            } else {
                
                /* 5/6. Parse the data and use the data (happens in completion handler) */
                
                let response = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: nil) as? [String : AnyObject]
                
                if let error = response!["error"] as? String {
                    completionHandler(urls: nil, success: false, error: error)
                }else{
                    if let photosDictionary = response?["photos"] as? [String:AnyObject]{
            
                            // get the first 21 pictures
                            if let photos = photosDictionary["photo"] as? [[String: AnyObject]]{
                                let total = photos.count
                                var temp = photos
                                let max = min(21, total)
                                temp = Array(temp[0..<max])
                           
                                let urls = map(temp) { (photo: [String:AnyObject]) -> String in
                                    let urlString = photo["url_m"] as! String
                                    return urlString
                                }
                                completionHandler(urls: urls, success: true, error: nil)
                            }
                        
                    }
                }
                
            }
        }
        /* 7. Start the request */
        task.resume()
        
    }
    func downloadpics(flickerurl: String, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> Void {
        /* 1. Set the parameters */
        //none
        
        /* 2. Build the URL */
        let url = NSURL(string: flickerurl)
        
        /* 3. Configure the request */
        let request = NSMutableURLRequest(URL: url!)
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, downloadError) -> Void in
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            if let error = downloadError {
                completionHandler(imageData: nil, error: error)
            } else {
                completionHandler(imageData: data, error: nil)

            }
            
        })
        /* 7. Start the request */
        task.resume()
    }
    
    /* Bounding box */
    func createBoundingBoxString(latitude: Double, longitude: Double) -> String {
        
        let latitude = latitude
        let longitude = longitude
        
        let bottom_left_lon = max(longitude - BOUNDING_BOX_HALF_WIDTH, LON_MIN)
        let bottom_left_lat = max(latitude - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        let top_right_lon = min(longitude + BOUNDING_BOX_HALF_HEIGHT, LON_MAX)
        let top_right_lat = min(latitude + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    func escapedParameters(parameters: [String : AnyObject]) -> String {

        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }
    
    class func sharedInstance() -> Flicker {
        
        struct Singleton {
            static var sharedInstance = Flicker()
        }
        
        return Singleton.sharedInstance
    }
    // MARK: - Shared Image Cache
    
    struct Caches {
        static let imageCache = ImageCache()
    }

}
