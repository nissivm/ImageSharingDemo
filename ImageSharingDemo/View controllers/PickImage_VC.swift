//
//  PickImage_VC.swift
//  ImageSharingDemo
//
//  Created by Nissi Vieira Miranda on 2/19/16.
//  Copyright © 2016 Nissi Vieira Miranda. All rights reserved.
//

import UIKit

extension UIColor
{
    convenience init(red: Int, green: Int, blue: Int)
    {
        let newRed = CGFloat(red)/255
        let newGreen = CGFloat(green)/255
        let newBlue = CGFloat(blue)/255
        
        self.init(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
    }
}

class PickImage_VC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate
{
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var albumButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var signOutButton: UIButton!
    @IBOutlet weak var newImagesButton: UIButton!
    @IBOutlet weak var filtersContainerView: UIView!
    @IBOutlet weak var authenticationContainerView: UIView!
    
    @IBOutlet weak var buttonsStackViewHeightConstraint: NSLayoutConstraint!
    
    let kinveyBackend = KinveyBackend()
    let picker = UIImagePickerController()
    var images = [Image]()
    var multiplier: CGFloat = 1
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "willEnterForeground",
                                    name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sessionStarted",
                                                                name: "SessionStarted", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "newPhoto",
                                                                name: "NewPhoto", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "closeFiltersContainerView:",
                                                                name: "CloseFiltersContainerView", object: nil)

        picker.delegate = self
        prefersStatusBarHidden()
        setNeedsStatusBarAppearanceUpdate()
        
        if Device.IS_IPHONE_6
        {
            multiplier = Constants.multiplier6
            adjustForBiggerScreen()
        }
        else if Device.IS_IPHONE_6_PLUS
        {
            multiplier = Constants.multiplier6plus
            adjustForBiggerScreen()
        }
        
        if KCSUser.activeUser() != nil
        {
            authenticationContainerView.hidden = true
            retrieveImages()
        }
    }
    
    override func prefersStatusBarHidden() -> Bool
    {
        return true
    }
    
    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Notifications
    //-------------------------------------------------------------------------//
    
    func willEnterForeground()
    {
        if KCSUser.activeUser() == nil
        {
            authenticationContainerView.hidden = false
        }
    }
    
    func sessionStarted()
    {
        authenticationContainerView.hidden = true
        
        if images.count == 0
        {
            retrieveImages()
        }
    }
    
    func newPhoto()
    {
        let newTitle = "New (\(Auxiliar.newPhotosIds.count))"
        let green = UIColor(red: 42, green: 191, blue: 124)
        newImagesButton.setTitle(newTitle, forState: .Normal)
        newImagesButton.setTitleColor(green, forState: .Normal)
        newImagesButton.enabled = true
    }
    
    var currentUserImagesIds = [String]()
    
    func closeFiltersContainerView(notification : NSNotification)
    {
        filtersContainerView.hidden = true
        
        if notification.object != nil
        {
            let savedImg = notification.object as! Image
            let entityId = savedImg.entityId!
            currentUserImagesIds.append(entityId)
            
            incorporateNewItemsAtBeginning([savedImg])
        }
    }
    
    //-------------------------------------------------------------------------//
    // MARK: IBActions
    //-------------------------------------------------------------------------//
    
    @IBAction func albumButtonTapped(sender: UIButton)
    {
        picker.allowsEditing = true
        picker.sourceType = .PhotoLibrary
        presentViewController(picker, animated: true, completion: nil)
    }
    
    @IBAction func cameraButtonTapped(sender: UIButton)
    {
        if UIImagePickerController.availableCaptureModesForCameraDevice(.Rear) != nil
        {
            picker.allowsEditing = true
            picker.sourceType = .Camera
            picker.cameraCaptureMode = .Photo
            picker.modalPresentationStyle = .FullScreen
            presentViewController(picker, animated: true, completion: nil)
        }
        else
        {
            Auxiliar.presentAlertControllerWithTitle("No Camera",
                andMessage: "Sorry, this device has no camera", forViewController: self)
        }
    }
    
    @IBAction func signOutButtonTapped(sender: UIButton)
    {
        KCSUser.activeUser().logout()
        authenticationContainerView.hidden = false
    }
    
    @IBAction func newImagesButtonTapped(sender: UIButton)
    {
        if newImagesButton.enabled
        {
            guard Reachability.connectedToNetwork() else
            {
                Auxiliar.presentAlertControllerWithTitle("No Internet Connection",
                    andMessage: "Make sure your device is connected to the internet.",
                    forViewController: self)
                return
            }
            
            Auxiliar.showLoadingHUDWithText("Loading new images...", forView: self.view)
            filterImagesToRetrieve()
        }
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Filter images to retrieve
    //-------------------------------------------------------------------------//
    
    func filterImagesToRetrieve()
    {
        if currentUserImagesIds.count == 0
        {
            retrieveNewImages(Auxiliar.newPhotosIds)
        }
        else
        {
            for element in currentUserImagesIds
            {
                if Auxiliar.newPhotosIds.count == 0
                {
                    break
                }
                
                for (index, element2) in Auxiliar.newPhotosIds.enumerate()
                {
                    if element == element2
                    {
                        Auxiliar.newPhotosIds.removeAtIndex(index)
                        break
                    }
                }
            }
            
            currentUserImagesIds.removeAll()
            
            if Auxiliar.newPhotosIds.count > 0
            {
                retrieveNewImages(Auxiliar.newPhotosIds)
            }
            else
            {
                Auxiliar.hideLoadingHUDInView(self.view)
                Auxiliar.presentAlertControllerWithTitle("No new images",
                    andMessage: "No new images to load", forViewController: self)
            }
        }
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Retrieve new images
    //-------------------------------------------------------------------------//
    
    func retrieveNewImages(entitiesIds: [String])
    {
        kinveyBackend.fetchNewImages(entitiesIds, completion: {
            
            [unowned self](status: String, fetchedImages: [Image]?) -> Void in
            
            if status == "Success"
            {
                Auxiliar.newPhotosIds.removeAll()
                let newTitle = "New"
                let gray = UIColor(red: 102, green: 102, blue: 102)
                self.newImagesButton.setTitle(newTitle, forState: .Normal)
                self.newImagesButton.setTitleColor(gray, forState: .Normal)
                self.newImagesButton.enabled = false
                
                self.incorporateNewItemsAtBeginning(fetchedImages!)
            }
            else
            {
                Auxiliar.hideLoadingHUDInView(self.view)
                Auxiliar.presentAlertControllerWithTitle(status,
                    andMessage: "Error loading new images", forViewController: self)
            }
        })
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Retrieve images
    //-------------------------------------------------------------------------//
    
    func retrieveImages()
    {
        Auxiliar.showLoadingHUDWithText("Retrieving images...", forView: self.view)
        
        guard Reachability.connectedToNetwork() else
        {
            Auxiliar.hideLoadingHUDInView(self.view)
            return
        }
        
        kinveyBackend.fetchImages({
            
            [unowned self](status: String, objects: [Image]?) -> Void in
            
            if status == "Success"
            {
                self.incorporateNewSearchItems(objects!)
            }
            else
            {
                Auxiliar.hideLoadingHUDInView(self.view)
                
                if status == "No results"
                {
                    if self.images.count > 0
                    {
                        self.searchingMore = false
                        self.hasMoreToShow = false
                    }
                }
                else if self.images.count == 0
                {
                    Auxiliar.presentAlertControllerWithTitle("Error",
                        andMessage: "Could not retrieve images", forViewController: self)
                }
            }
        })
    }
    
    //-------------------------------------------------------------------------//
    // MARK: UIScrollViewDelegate
    //-------------------------------------------------------------------------//
    
    var searchingMore = false
    var hasMoreToShow = true
    
    func scrollViewDidScroll(scrollView: UIScrollView)
    {
        if collectionView.contentOffset.y >= (collectionView.contentSize.height - collectionView.bounds.size.height)
        {
            if (searchingMore == false) && hasMoreToShow
            {
                searchingMore = true
                retrieveImages()
            }
        }
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Incorporate new items at beginning
    //-------------------------------------------------------------------------//
    
    func incorporateNewItemsAtBeginning(imgs: [Image])
    {
        var indexPath: NSIndexPath = NSIndexPath(forItem: 0, inSection: 0)
        var counter = 0
        var newItems = [NSIndexPath]()
        
        for image in imgs
        {
            indexPath = NSIndexPath(forItem: counter, inSection: 0)
            newItems.append(indexPath)
            
            images.insert(image, atIndex: counter)
            
            counter++
        }
        
        collectionView.performBatchUpdates({
            
            [unowned self]() -> Void in
            
            self.collectionView.insertItemsAtIndexPaths(newItems)
            }){
                completed in
                
                Auxiliar.hideLoadingHUDInView(self.view)
            }
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Incorporate new search items
    //-------------------------------------------------------------------------//
    
    func incorporateNewSearchItems(imgs: [Image])
    {
        var indexPath: NSIndexPath = NSIndexPath(forItem: 0, inSection: 0)
        var counter = collectionView.numberOfItemsInSection(0)
        var newItems = [NSIndexPath]()
        
        for image in imgs
        {
            indexPath = NSIndexPath(forItem: counter, inSection: 0)
            newItems.append(indexPath)
            
            images.append(image)
            
            counter++
        }
        
        collectionView.performBatchUpdates({
            
            [unowned self]() -> Void in
            
            self.collectionView.insertItemsAtIndexPaths(newItems)
            }){
                completed in
                
                Auxiliar.hideLoadingHUDInView(self.view)
                self.searchingMore = false
            }
    }
    
    //-------------------------------------------------------------------------//
    // MARK: UIImagePickerControllerDelegate
    //-------------------------------------------------------------------------//
    
    func imagePickerController(picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        let chosenImage = info[UIImagePickerControllerEditedImage] as! UIImage
        dismissViewControllerAnimated(true, completion: nil)
        
        NSNotificationCenter.defaultCenter().postNotificationName("FilterPhoto", object: chosenImage)
        filtersContainerView.hidden = false
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController)
    {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    //-------------------------------------------------------------------------//
    // MARK: UICollectionViewDataSource
    //-------------------------------------------------------------------------//
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return images.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ItemForSaleCell",
            forIndexPath: indexPath) as! ImageCell
        
        let image = images[indexPath.item]
        cell.imageView.image = image.image
        
        return cell
    }
    
    //-------------------------------------------------------------------------//
    // MARK: UICollectionViewDelegateFlowLayout
    //-------------------------------------------------------------------------//
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        let cellSide = self.view.frame.size.width/2
        return CGSizeMake(cellSide, cellSide)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat
    {
        return 0
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Ajust for bigger screen
    //-------------------------------------------------------------------------//
    
    func adjustForBiggerScreen()
    {
        buttonsStackViewHeightConstraint.constant *= multiplier
        
        let fontSize = 15.0 * multiplier
        albumButton.titleLabel!.font =  UIFont(name: "HelveticaNeue", size: fontSize)
        cameraButton.titleLabel!.font =  UIFont(name: "HelveticaNeue", size: fontSize)
        signOutButton.titleLabel!.font =  UIFont(name: "HelveticaNeue", size: fontSize)
        newImagesButton.titleLabel!.font =  UIFont(name: "HelveticaNeue-Bold", size: fontSize)
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Memory Warning
    //-------------------------------------------------------------------------//

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
