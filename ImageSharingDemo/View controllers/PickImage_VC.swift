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
    @IBOutlet weak var background: UIImageView!
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
        
        var backImg = ""
        
        if Device.IS_IPHONE_4
        {
            backImg = "iphone4_back"
        }
        
        if Device.IS_IPHONE_5
        {
            backImg = "iphone5_back"
        }
        
        if Device.IS_IPHONE_6
        {
            backImg = "iphone6_back"
            multiplier = Constants.multiplier6
            adjustForBiggerScreen()
        }
        
        if Device.IS_IPHONE_6_PLUS
        {
            backImg = "iphone6plus_back"
            multiplier = Constants.multiplier6plus
            adjustForBiggerScreen()
        }
        
        let path = NSBundle.mainBundle().pathForResource(backImg, ofType:"jpg")
        background.image = UIImage(contentsOfFile: path!)
        
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
        newImagesButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        newImagesButton.enabled = true
    }
    
    func closeFiltersContainerView(notification : NSNotification)
    {
        filtersContainerView.hidden = true
        
        if notification.object != nil
        {
            let savedImg = notification.object as! Image
            incorporateNewImage(savedImg)
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
            
            Auxiliar.showLoadingHUDWithText("Loading new image...", forView: self.view)
            retrieveNewImage(Auxiliar.newPhotosIds.first!)
        }
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Retrieve new image
    //-------------------------------------------------------------------------//
    
    func retrieveNewImage(fileId: String)
    {
        kinveyBackend.fetchNewImage(fileId, completion: {
            
            [unowned self](status: String, fetchedImage: Image?) -> Void in
            
            guard status == "Success" else
            {
                Auxiliar.hideLoadingHUDInView(self.view)
                Auxiliar.presentAlertControllerWithTitle(status,
                    andMessage: "Error loading new image", forViewController: self)
                return
            }
            
            for (index, photoId) in Auxiliar.newPhotosIds.enumerate()
            {
                if photoId == fileId
                {
                    Auxiliar.newPhotosIds.removeAtIndex(index)
                    break
                }
            }
            
            if Auxiliar.newPhotosIds.count == 0
            {
                self.newImagesButton.setTitleColor(UIColor.darkGrayColor(), forState: .Normal)
                self.newImagesButton.enabled = false
            }
            
            self.incorporateNewImage(fetchedImage!)
        })
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Incorporate new image
    //-------------------------------------------------------------------------//
    
    func incorporateNewImage(img: Image)
    {
        let newIdx = collectionView.numberOfItemsInSection(0)
        let indexPath: NSIndexPath = NSIndexPath(forItem: newIdx, inSection: 0)
        let newItem = [indexPath]
        images.append(img)
        
        collectionView.performBatchUpdates({
            
            [unowned self]() -> Void in
            
            self.collectionView.insertItemsAtIndexPaths(newItem)
            }){
                completed in
                
                Auxiliar.hideLoadingHUDInView(self.view)
            }
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
            
            [unowned self](status: String, fetchedImages: [Image]?) -> Void in
            
            if status == "Success"
            {
                self.incorporateSearchedImages(fetchedImages!)
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
    
    func incorporateSearchedImages(imgs: [Image])
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
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ImageCell",
            forIndexPath: indexPath) as! ImageCell
        
        let imageObj = images[indexPath.item]
        
        if let img = imageObj.image
        {
            cell.imageView.image = img
        }
        else
        {
            print("imageObj.image == nil")
        }
        
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
    
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat
    {
        return 0
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Ajust for bigger screen
    //-------------------------------------------------------------------------//
    
    func adjustForBiggerScreen()
    {
        buttonsStackViewHeightConstraint.constant *= multiplier
        
        let fontSize = 14.0 * multiplier
        albumButton.titleLabel!.font =  UIFont(name: "HelveticaNeue", size: fontSize)
        cameraButton.titleLabel!.font =  UIFont(name: "HelveticaNeue", size: fontSize)
        signOutButton.titleLabel!.font =  UIFont(name: "HelveticaNeue", size: fontSize)
        newImagesButton.titleLabel!.font =  UIFont(name: "HelveticaNeue", size: fontSize)
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
