//
//  PickImage_VC.swift
//  ImageSharingDemo
//
//  Created by Nissi Vieira Miranda on 2/19/16.
//  Copyright © 2016 Nissi Vieira Miranda. All rights reserved.
//

import UIKit

class PickImage_VC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate
{
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var albumButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var signOutButton: UIButton!
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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "newPhoto:",
                                                                name: "NewPhoto", object: nil)

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
        retrieveImages()
    }
    
    func newPhoto(notification: NSNotification)
    {
        let entityId = notification.object as! String
        print("New photo with id = \(entityId)")
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
    // MARK: Incorporate new search items
    //-------------------------------------------------------------------------//
    
    func incorporateNewSearchItems(imgs : [Image])
    {
        var indexPath : NSIndexPath = NSIndexPath(forItem: 0, inSection: 0)
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
        
        let image = images[indexPath.row]
        cell.imageView.image = image.image
        
        return cell
    }
    
    //-------------------------------------------------------------------------//
    // MARK: UICollectionViewDelegateFlowLayout
    //-------------------------------------------------------------------------//
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        let cellWidth = self.view.frame.size.width/2
        return CGSizeMake(cellWidth, cellWidth)
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
        
        let fontSize = 17.0 * multiplier
        albumButton.titleLabel!.font =  UIFont(name: "HelveticaNeue", size: fontSize)
        cameraButton.titleLabel!.font =  UIFont(name: "HelveticaNeue", size: fontSize)
        signOutButton.titleLabel!.font =  UIFont(name: "HelveticaNeue", size: fontSize)
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
