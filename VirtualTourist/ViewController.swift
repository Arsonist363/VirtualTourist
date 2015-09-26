//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Cesar Colorado on 9/17/15.
//  Copyright (c) 2015 Cesar Colorado. All rights reserved.
//

import CoreData
import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {
    
    // Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deletePinView: UIView!
    
    // Managed Object Context 
    var appDelegate: AppDelegate!
    var sharedContext: NSManagedObjectContext!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //appDelegate for context save method
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        //initializing our context
        sharedContext = appDelegate.managedObjectContext
        
        // Adding UI buttons
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        //long press gesture recognizer allowing us call our "dropPin" method.
        var longPress = UILongPressGestureRecognizer(target: self, action: "dropPin:")
        longPress.minimumPressDuration = 0.5
        
        //add the recognizer to mapView
        mapView.addGestureRecognizer(longPress)
        
        //Set ViewController as mapView delegate
        mapView.delegate = self
        
        //add pins to map
        mapView.addAnnotations(fetchAllPins())
        
        
    }
    
    func dropPin(gestureRecognizer: UIGestureRecognizer) {
        
        let tapPoint: CGPoint = gestureRecognizer.locationInView(mapView)
        let touchMapCoordinate: CLLocationCoordinate2D = mapView.convertPoint(tapPoint, toCoordinateFromView: mapView)
        
        if UIGestureRecognizerState.Began == gestureRecognizer.state {
            
            //initialize our Pin with our coordinates and the context from AppDelegate
            let pin = Pin(annotationLatitude: touchMapCoordinate.latitude, annotationLongitude: touchMapCoordinate.longitude, context: appDelegate.managedObjectContext!)
            
            //add the pin to the map
            mapView.addAnnotation(pin)
            
            //add photos to pin
            self.getPhotos(pin)
            
            //save our context.
            appDelegate.saveContext()
        }
    }
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if self.editing{
            //make view vissible
            self.deletePinView.hidden = false
        }
        else{
            self.deletePinView.hidden = true
        }
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        //cast pin
        let pin = view.annotation as! Pin
       
        if self.editing{
            
            //delete from our context
            sharedContext.deleteObject(pin)
            
            //remove the annotation from the map
            mapView.removeAnnotation(pin)
            
        }
        else{
            let latitude = pin.latitude as Double
            let longitude = pin.longitude as Double
            
            //pass pin to new controller
            let controller = self.storyboard!.instantiateViewControllerWithIdentifier("PhotoViewController") as! PhotoViewController
            controller.pin = self.fetchAPin(latitude, longitude: longitude).first
            self.navigationController?.pushViewController(controller, animated: true)
        }
        
        
        
    }
    func getPhotos(pin: Pin){
        let latitude = pin.latitude as Double
        let longitude = pin.longitude as Double
        
        
        Flicker.sharedInstance().getPictures(latitude, longitude: longitude){ (urls, success, error) in
            if success {
                for (index, url) in enumerate(urls!){
                    let dictionary = ["imageURL" : url]
                    let photo = Photos(dictionary: dictionary, context: self.appDelegate.managedObjectContext!)
                    photo.pin = pin
                    
                    //save our context
                    
                    Flicker.sharedInstance().downloadpics(photo.imageURL!, completionHandler: { (imageData, error) -> Void in
                        if let imageData = imageData {
                            Flicker.Caches.imageCache.storeImage(UIImage(data: imageData), withIdentifier: photo.imageURL!.lastPathComponent)
                            let image = UIImage(data: imageData)
                            photo.image = image
                            self.appDelegate.saveContext()
                        }
                    })
                   }
                
            }
            else {
                println("bad")
            }
        }
        
    }
    
    
    func fetchAllPins() -> [Pin] {
        
        let error: NSErrorPointer = nil
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        // Execute the Fetch Request
        let results = sharedContext.executeFetchRequest(fetchRequest, error: error)
        // Check for Errors
        if error != nil {
            println("Error in fectchAllActors(): \(error)")
        }
        // Return the results, cast to an array of Pin objects
        return results as! [Pin]
    }
    
    func fetchAPin(latitude: Double, longitude: Double) -> [Pin] {
        
        let error: NSErrorPointer = nil
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        //fetch pin with specific coordinates
        let predicate = NSPredicate(format:"latitude == %lf && longitude == %lf", latitude, longitude)
        fetchRequest.predicate = predicate
        
        // Execute the Fetch Request
        let results = self.sharedContext?.executeFetchRequest(fetchRequest, error: nil)
        
        // Check for Errors
        if error != nil {
            println("Error in fectchAllActors(): \(error)")
        }
        // Return the results, cast to an array of Pin objects
        return results as! [Pin]
    }
}

