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
        dispatch_async(dispatch_get_main_queue()) {
        self.sharedContext = self.appDelegate.managedObjectContext
        }
        // Adding UI buttons
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        //long press gesture recognizer allowing us call our "dropPin" method.
        var longPress = UILongPressGestureRecognizer(target: self, action: "dropPin:")
        longPress.minimumPressDuration = 0.5
        
        //add the recognizer to mapView
        mapView.addGestureRecognizer(longPress)
        
        //Set ViewController as mapView delegate
        mapView.delegate = self
        
        fetchAllPins()
        
    }
    
    func dropPin(gestureRecognizer: UIGestureRecognizer) {
        dispatch_async(dispatch_get_main_queue()) {
        let tapPoint: CGPoint = gestureRecognizer.locationInView(self.mapView)
        let touchMapCoordinate: CLLocationCoordinate2D = self.mapView.convertPoint(tapPoint, toCoordinateFromView: self.mapView)
        let annotation = MKPointAnnotation()
        
            if UIGestureRecognizerState.Began == gestureRecognizer.state {
            
                //initialize our Pin with our coordinates and the context from AppDelegate
                dispatch_async(dispatch_get_main_queue()) {
                    let pin = Pin(annotationLatitude: touchMapCoordinate.latitude, annotationLongitude: touchMapCoordinate.longitude, context: self.appDelegate.managedObjectContext!)
                    
                    //add photos to pin
                    self.getPhotos(pin)
                }
                //add the pin to the map
                annotation.coordinate = touchMapCoordinate
                self.mapView.addAnnotation(annotation)
            
                
            
                //save our context.
                self.appDelegate.saveContext()
            }
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
        dispatch_async(dispatch_get_main_queue()) {
        //cast pin
        let annotation = view.annotation as MKAnnotation
        let core = annotation.coordinate
        let pin = self.fetchAPin(core.latitude, longitude: core.longitude).first
       
        if self.editing{
            
            //delete from our context
            self.sharedContext.deleteObject(pin!)
            
            //remove the annotation from the map
            mapView.removeAnnotation(annotation)
            
        }
        else{
            let latitude = core.latitude
            let longitude = core.longitude
            
            //pass pin to new controller
            
                let controller = self.storyboard!.instantiateViewControllerWithIdentifier("PhotoViewController") as! PhotoViewController
                controller.pin = self.fetchAPin(latitude, longitude: longitude).first
                self.navigationController?.pushViewController(controller, animated: true)
            }
        
        
        }
        
    }
    func getPhotos(pin: Pin){
        let latitude = pin.latitude as Double
        let longitude = pin.longitude as Double
        dispatch_async(dispatch_get_main_queue()) {
            Flicker.sharedInstance().getPictures(latitude, longitude: longitude, pageNumber: 1){ (urls, success, error) in
                if success {
                    dispatch_async(dispatch_get_main_queue()) {

                    for (index, url) in enumerate(urls!){
                        let dictionary = ["imageURL" : url]
                        
                        let photo = Photos(dictionary: dictionary, context: self.appDelegate.managedObjectContext!)
                        photo.pin = pin
                    
                        //save our context
                    
                        Flicker.sharedInstance().downloadpics(photo.imageURL!, completionHandler: { (imageData, error) -> Void in
                            dispatch_async(dispatch_get_main_queue()) {
                            if let imageData = imageData {
                                Flicker.Caches.imageCache.storeImage(UIImage(data: imageData), withIdentifier: photo.imageURL!.lastPathComponent)
                                }}
                        })
                   }
                }
            }
            else {
                
            }
        }
        }
    }
    
    
    // Get all of the pins from core data
    func fetchAllPins() -> [Pin]  {
        let error: NSErrorPointer = nil
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        // Execute the Fetch Request
        let results = self.sharedContext?.executeFetchRequest(fetchRequest, error: nil)
        
        // Check for Errors
        if error != nil {
            println("Error in fectchAllActors(): \(error)")
        }
        // Return the results, cast to an array of Pin objects
        return results as! [Pin]
    }

    // fetch a pin from core data
    func fetchAPin(latitude: Double?, longitude: Double?) -> [Pin] {
        
        let error: NSErrorPointer = nil
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        if latitude != nil && longitude != nil {
            //fetch pin with specific coordinates
            let predicate = NSPredicate(format:"latitude == %lf && longitude == %lf", latitude!, longitude!)
            fetchRequest.predicate = predicate
        }
        
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

