//
//  PhotoViewController.swift
//  VirtualTourist
//
//  Created by Cesar Colorado on 9/17/15.
//  Copyright (c) 2015 Cesar Colorado. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    
    
    
    
    // Store Pin
    var pin: Pin!
    
    
    // Keep the changes. Keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    // Track selection
    var selectedIndexes = [NSIndexPath]()
    
    // Managed Object Context 
    var appDelegate: AppDelegate!
    var sharedContext: NSManagedObjectContext!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        //appDelegate for context save method
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        println(pin.photo.isEmpty)
        //initializing our context
        sharedContext = appDelegate.managedObjectContext
        
        // set coordinate from pin
        let coordinate = CLLocationCoordinate2D(latitude: pin.latitude  as Double, longitude: pin.longitude  as Double)
        
        var annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.75, longitudeDelta: 0.75))
        
        // add pin to mapview and region
        self.mapView.addAnnotation(annotation)
        self.mapView.setRegion(region, animated: true)
        
        // prevent user from making changes on mapView
        self.mapView.userInteractionEnabled = false
        
        // Set delegate and data source for collectionView
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        //Perform the fetch
        fetchedResultsController.performFetch(nil)
        
        //Set the delegate to this view controller
        fetchedResultsController.delegate = self
        
        updateBottomButton()
    }
    // Layout the collection view
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width,
        // with no space in between.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let width = floor(self.collectionView.frame.size.width/3)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }
    
    // Mark: - Fetched Results Controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photos")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "imageURL", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin);
        
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()
    
     // MARK: - Configure Cell
    func configureCell(cell: CollectionViewCell, photo: Photos){
        var flickerImage = UIImage(named: "flickerimage")
        
        if photo.image != nil {
            println("catch working")
            flickerImage = photo.image
        }else{
            Flicker.sharedInstance().downloadpics(photo.imageURL!, completionHandler: { (imageData, error) -> Void in
                if let data = imageData {
                    dispatch_async(dispatch_get_main_queue()) {
                        let image = UIImage(data: data)
                        photo.image = image
                        cell.flickerImage.image = image
                        self.appDelegate.saveContext()
                    }
                }            })
        }
        cell.flickerImage.image = flickerImage
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // Get Photos object
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photos
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCell", forIndexPath: indexPath) as! CollectionViewCell
        
        configureCell(cell, photo: photo)
        
        return cell
    }
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! CollectionViewCell
        
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        if let index = find(selectedIndexes, indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        if let index = find(selectedIndexes, indexPath) {
            cell.alpha = 0.5
        } else {
            cell.alpha = 1.0
        }
        
        // And update the buttom button
        updateBottomButton()
    }
    
    @IBAction func bottomButtonAction(sender: AnyObject) {
        if selectedIndexes.count > 0 {
            deleteSelectedPhotos()
        } else {
            fetchmorepics()
        }
    }
    func updateBottomButton() {
        if selectedIndexes.count > 0 {
            bottomButton.title = "Remove Picture"
        } else {
            bottomButton.title = "New Collection"
        }
    }
    func fetchmorepics(){
        
    }
    
    func deleteSelectedPhotos(){
        var photosToDelete = [Photos]()
        
        for indexPath in selectedIndexes {
            photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photos)
        }
        
        for items in photosToDelete {
            self.sharedContext?.deleteObject(items)
        }
        
        selectedIndexes = [NSIndexPath]()
    }
    
    // MARK: - NSFetchedResultsControllerDelegate Methods
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }
    
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            println("move an item")
            break
        default:
            break
        }
    }
    
    // Loop through arrays and perform changes
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        collectionView.performBatchUpdates({ () -> Void in
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            }, completion:nil)
    }

}
