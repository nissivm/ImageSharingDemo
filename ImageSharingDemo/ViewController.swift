//
//  ViewController.swift
//  ImageSharingDemo
//
//  Created by Nissi Vieira Miranda on 2/18/16.
//  Copyright © 2016 Nissi Vieira Miranda. All rights reserved.
//

import UIKit
import CoreImage

class ViewController: UIViewController
{
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var applyFilterButton: UIButton!
    
    var filter: Filter!

    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(true)
        
        filter = Filter(original: imageView.image)
    }
    
    var counter = 0
    
    @IBAction func applyFilterButtonTapped(sender: UIButton)
    {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0))
        {
            let filteredImg = self.filter.applyFilterWithIndex(self.counter)
            
            dispatch_async(dispatch_get_main_queue())
            {
                if filteredImg != nil
                {
                    self.imageView.image = filteredImg
                }
                
                self.counter++
            }
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

