//
//  Photos.swift
//  VirtualTourist
//
//  Created by Cesar Colorado on 9/17/15.
//  Copyright (c) 2015 Cesar Colorado. All rights reserved.
//

import UIKit

//1. import Core Data
import CoreData

//2. include the strange statement @objc(Object). This makes Object visible to Core Data code (Objective-C code)
@objc(Photos)

//3. Make Object a subclass of NSManagedObject
class Photos : NSManagedObject{
    
    //4. Add @NSManaged in front of each of the properties/attributes
    @NSManaged var imageURL: String?
    @NSManaged var pin: Pin?
    
    
    struct Keys {
        static let imageURL = "imageURL"
    }
    
    var image: UIImage? {
        get {
            return Flicker.Caches.imageCache.imageWithIdentifier(imageURL)
        }
        
        set {
            Flicker.Caches.imageCache.storeImage(image, withIdentifier: imageURL!)
        }
    }

    
    //5. Include the standard Core Data init method, which inserts the object into a context
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    //6. Write an init method that takes a dictionary and a context.
    init(dictionary: [String:AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photos", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        imageURL = dictionary[Keys.imageURL] as? String
    }
    
    
}