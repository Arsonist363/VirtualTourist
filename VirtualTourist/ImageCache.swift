//
//  ImageCache.swift
//  VirtualTourist
//
//  Created by Cesar Colorado on 9/24/15.
//  Copyright (c) 2015 Cesar Colorado. All rights reserved.
//

import UIKit

class ImageCache
{
    
    // MARK: - Properties
    
    private var inMemoryCache = NSCache()
    
    // MARK: - Retrieving images
    
    func imageWithIdentifier(identifier: String?) -> UIImage? {
        
        // If identifier is nil or empty return nil
        if identifier == nil || identifier! == "" {
            return nil
        }
        
        let path = pathForIdentifier(identifier!)
        var data: NSData?
        
        // First try the memory cache
        if let image = inMemoryCache.objectForKey(path) as? UIImage {
            // Check if image still exists on disk, otherwise save again
            if !(NSFileManager.defaultManager().fileExistsAtPath(path)) {
                let data = UIImagePNGRepresentation(image)
                data.writeToFile(path, atomically: true)
            }
            
            return image
        }
        
        // Next try hard drive
        if let data = NSData(contentsOfFile: path) {
            return UIImage(data: data)
        }
        
        return nil
    }
    
    // MARK: - Saving images
    
    func storeImage(image: UIImage?, withIdentifier identifier: String) {
        let path = pathForIdentifier(identifier)
        
        // If image is nil remove images from cache
        if image == nil {
            inMemoryCache.removeObjectForKey(path)
            NSFileManager.defaultManager().removeItemAtPath(path, error: nil)
            return
        }
        
        // Otherwise keep image in memory...
        inMemoryCache.setObject(image!, forKey: path)
        
        // ...and in Documents directory
        let data = UIImagePNGRepresentation(image!)
        data.writeToFile(path, atomically: true)
    }
    
    // MARK: - Helper
    
    // Add file name to Documents directory
    func pathForIdentifier(identifier: String) -> String {
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).first as! NSURL
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier)
        
        return fullURL.path!
    }
}
