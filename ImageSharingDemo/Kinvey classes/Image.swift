//
//  Image.swift
//  ImageSharingDemo
//
//  Created by Nissi Vieira Miranda on 2/23/16.
//  Copyright © 2016 Nissi Vieira Miranda. All rights reserved.
//

import Foundation

class Image : NSObject
{
    var fileId: String!
    var image: UIImage? = nil
    
    init(fileId: String, imageData: NSData?)
    {
        self.fileId = fileId
        
        if let data = imageData
        {
            image = UIImage(data: data)
        }
    }
}