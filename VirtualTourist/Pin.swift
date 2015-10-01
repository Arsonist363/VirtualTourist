//
//  Pin.swift
//  VirtualTourist
//
//  Created by Cesar Colorado on 9/17/15.
//  Copyright (c) 2015 Cesar Colorado. All rights reserved.
//

import UIKit
import CoreData

@objc(Pin)

class Pin: NSManagedObject {

    //our managed attributes
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var photo: [Photos]
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(annotationLatitude: Double, annotationLongitude: Double, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        latitude = annotationLatitude as Double
        longitude = annotationLongitude as Double
    }

}
