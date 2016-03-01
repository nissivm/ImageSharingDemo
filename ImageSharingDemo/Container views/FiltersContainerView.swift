//
//  FiltersContainerView.swift
//  ImageSharingDemo
//
//  Created by Nissi Vieira Miranda on 2/26/16.
//  Copyright © 2016 Nissi Vieira Miranda. All rights reserved.
//

import UIKit

class FiltersContainerView: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var originalImageButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonsStackViewHeightConstraint: NSLayoutConstraint!
    
    let kinveyBackend = KinveyBackend()
    let filters = ["Sepia", "Instant", "Noir", "Process", "Transfer", "Halftone", "Gloom"]
    var filter: Filter?
    var multiplier: CGFloat = 1
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "filterPhoto:",
                                                                name: "FilterPhoto", object: nil)
        
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
    }
    
    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Notifications
    //-------------------------------------------------------------------------//
    
    func filterPhoto(notification: NSNotification)
    {
        let imageToFilter = notification.object as? UIImage
        imageView.image = imageToFilter
        filter = Filter(original: imageToFilter)
        savedImg = nil
    }
    
    //-------------------------------------------------------------------------//
    // MARK: IBActions
    //-------------------------------------------------------------------------//
    
    @IBAction func cancelButtonTapped(sender: UIButton)
    {
        closeContainerView()
    }
    
    @IBAction func originalImageButtonTapped(sender: UIButton)
    {
        let originalImg = filter!.applyFilterWithIndex(7)
        imageView.image = originalImg
    }
    
    var savedImg: Image? = nil
    
    @IBAction func shareButtonTapped(sender: UIButton)
    {
        Auxiliar.showLoadingHUDWithText("Publishing image...", forView: self.view)
        
        kinveyBackend.saveImage(imageView.image!, completion: {
            
            [unowned self](status, savedImg, errorMessage) -> Void in
            
            if status == "Error"
            {
                Auxiliar.hideLoadingHUDInView(self.view)
                Auxiliar.presentAlertControllerWithTitle(status,
                    andMessage: errorMessage, forViewController: self)
                return
            }
            
            self.savedImg = savedImg
            let entityId = savedImg!.entityId!
            
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                appDelegate.sendPushNotification(entityId, completion: {
                
                    (status) -> Void in
                
                    Auxiliar.hideLoadingHUDInView(self.view)
                    
                    self.promptUserForSuccessfulImageSharing(status,
                        message: "Image successfully published!")
                })
        })
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Prompt user for successfull image sharing
    //-------------------------------------------------------------------------//
    
    private func promptUserForSuccessfulImageSharing(title: String, message: String)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "Ok", style: .Default)
        {
            [unowned self](action: UIAlertAction!) -> Void in
                
            self.closeContainerView()
        }
        
        alert.addAction(okAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Close container view
    //-------------------------------------------------------------------------//
    
    private func closeContainerView()
    {
        NSNotificationCenter.defaultCenter().postNotificationName("CloseFiltersContainerView", object: savedImg)
        imageView.image = nil
        filter = nil
    }
    
    //-------------------------------------------------------------------------//
    // MARK: UICollectionViewDataSource
    //-------------------------------------------------------------------------//
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return filters.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FilterCell",
            forIndexPath: indexPath) as! FilterCell
        
        let filter = filters[indexPath.item]
        cell.filterName.text = filter
        let fontSize = 17.0 * multiplier
        cell.filterName.font =  UIFont(name: "HelveticaNeue", size: fontSize)
        
        return cell
    }
    
    //-------------------------------------------------------------------------//
    // MARK: UICollectionViewDelegateFlowLayout
    //-------------------------------------------------------------------------//
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        Auxiliar.showLoadingHUDWithText("Applying filter...", forView: self.view)
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0))
        {
            let index = indexPath.item
            let filteredImg = self.filter!.applyFilterWithIndex(index)
            
            dispatch_async(dispatch_get_main_queue())
            {
                Auxiliar.hideLoadingHUDInView(self.view)
                
                if filteredImg != nil
                {
                    self.imageView.image = filteredImg
                }
                else
                {
                    Auxiliar.presentAlertControllerWithTitle("Error",
                        andMessage: "Error on image filtering", forViewController: self)
                }
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        let cellWidth = self.view.frame.size.width/2
        var cellHeight: CGFloat = 40
        
        if Device.IS_IPHONE_6
        {
            cellHeight *= Constants.multiplier6
        }
        else if Device.IS_IPHONE_6_PLUS
        {
            cellHeight *= Constants.multiplier6plus
        }
        
        return CGSizeMake(cellWidth, cellHeight)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat
    {
        return 1
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Ajust for bigger screen
    //-------------------------------------------------------------------------//
    
    private func adjustForBiggerScreen()
    {
        collectionViewHeightConstraint.constant *= multiplier
        buttonsStackViewHeightConstraint.constant *= multiplier
        
        let fontSize = 15.0 * multiplier
        cancelButton.titleLabel!.font =  UIFont(name: "HelveticaNeue", size: fontSize)
        originalImageButton.titleLabel!.font =  UIFont(name: "HelveticaNeue", size: fontSize)
        shareButton.titleLabel!.font =  UIFont(name: "HelveticaNeue", size: fontSize)
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
