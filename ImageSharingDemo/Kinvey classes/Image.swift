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
    var entityId: String? //Kinvey entity _id
    var image: UIImage!
    var date: NSDate!
    
    override func hostToKinveyPropertyMapping() -> [NSObject : AnyObject]!
    {
        return [
            "entityId" : KCSEntityKeyId, //the required _id field
            "image" : "imageLink",
            "date" : "date"
        ]
    }
    
    // Creates a relationship between "imageLink" column, in the Images collection,
    // and the Files collection.
    // Every time a new Image obj is saved to the Images collection, a new file (representing
    // the actual image) is created in the Files collection and a link to this file is
    // created in the "imageLink" column.
    static override func kinveyPropertyToCollectionMapping() -> [NSObject : AnyObject]!
    {
        return ["imageLink" : KCSFileStoreCollectionName]
    }
    
    // Makes the image be saved in the Files collection whenever a new Image obj is
    // saved in Images collection.
    override func referenceKinveyPropertiesOfObjectsToSave() -> [AnyObject]!
    {
        return ["imageLink"]
    }
}