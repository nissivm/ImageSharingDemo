//
//  KinveyBackend.swift
//  ImageSharingDemo
//
//  Created by Nissi Vieira Miranda on 2/23/16.
//  Copyright © 2016 Nissi Vieira Miranda. All rights reserved.
//

import Foundation

class KinveyBackend
{
    //-------------------------------------------------------------------------//
    // MARK: User Sign up
    //-------------------------------------------------------------------------//
    
    func signUpUser(firstName: String, lastName: String, email: String,
                     username: String, password: String,
                    completion:(status: String, errorMessage: String) -> Void)
    {
        if emailIsValid(email) == false
        {
            completion(status: "Error", errorMessage: "Invalid email")
            return
        }
        
        verifyUsernameExistence(username, completion: {
            
            (taken) -> Void in
            
            if taken
            {
                completion(status: "Error", errorMessage: "Username taken")
                return
            }
            
            KCSUser.userWithUsername(username, password: password,
                fieldsAndValues: [
                    KCSUserAttributeEmail : email,
                    KCSUserAttributeGivenname : firstName,
                    KCSUserAttributeSurname : lastName
                ],
                withCompletionBlock: {
                    
                    (user, errorOrNil, result) -> Void in
                    
                    if errorOrNil == nil
                    {
                        // The created user is automatically logged in as the active user.
                        completion(status: "Success", errorMessage: "")
                    }
                    else
                    {
                        print("Error on sign up: \(errorOrNil)")
                        completion(status: "Error", errorMessage: "Error signing up")
                    }
                }
            )
        })
    }
    
    private func emailIsValid(var email: String) -> Bool
    {
        email = email.lowercaseString
        let checkOne = NSString(string: email).containsString("@")
        let checkTwo = NSString(string: email).containsString(".com")
        if checkOne && checkTwo
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    private func verifyUsernameExistence(username: String, completion:(taken: Bool) -> Void)
    {
        KCSUser.checkUsername(username,
            withCompletionBlock: {
                
                (username, usernameAlreadyTaken, error) -> Void in
                
                guard error == nil else
                {
                    completion(taken: true)
                    return
                }
                
                completion(taken: usernameAlreadyTaken)
            }
        )
    }
    
    //-------------------------------------------------------------------------//
    // MARK: User Sign in
    //-------------------------------------------------------------------------//
    
    func signInUser(username: String, password: String,
        completion:(status: String, errorMessage: String) -> Void)
    {
        KCSUser.loginWithUsername(username, password: password,
            withCompletionBlock: {
                
                (user, errorOrNil, result) -> Void in
                
                if errorOrNil == nil
                {
                    //The user is now the active user and credentials were saved
                    completion(status: "Success", errorMessage: "")
                }
                else
                {
                    print("Error on sign in: \(errorOrNil)")
                    completion(status: "Error", errorMessage: "Error signing in")
                }
            }
        )
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Fetches all KCSUsers
    //-------------------------------------------------------------------------//
    
    func fetchUsers(completion:(status: String, fetchedUsers: [KCSUser]?) -> Void)
    {
        let userCollection = KCSCollection.userCollection()
        let userStore = KCSAppdataStore(collection: userCollection, options: nil)
        
        userStore.queryWithQuery(KCSQuery(),
            withCompletionBlock: {
                
                (objectsOrNil, errorOrNil) -> Void in
                
                guard errorOrNil == nil else
                {
                    completion(status: "Error", fetchedUsers: nil)
                    return
                }
                
                let users = objectsOrNil as! [KCSUser]
                completion(status: "Success", fetchedUsers: users)
            },
            withProgressBlock: nil
        )
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Fetches images using a query
    //-------------------------------------------------------------------------//
    
    var skip: Int = 0
    
    func fetchImages(completion:(status: String, fetchedImages: [Image]?) -> Void)
    {
        let query = KCSQuery()
            query.limitModifer = KCSQueryLimitModifier(limit: 8)
            query.skipModifier = KCSQuerySkipModifier(withcount: skip)
        
        KCSFileStore.downloadDataByQuery(query,
            completionBlock: {
                
                (downloadedResources, error) -> Void in
                
                guard error == nil else
                {
                    completion(status: "Error", fetchedImages: nil)
                    return
                }
                
                guard downloadedResources.count > 0 else
                {
                    completion(status: "No results", fetchedImages: nil)
                    return
                }
                
                var images = [Image]()
                
                for resource in downloadedResources
                {
                    let file = resource as! KCSFile
                    let imgObj = Image(fileId: file.fileId, imageData: file.data)
                    images.append(imgObj)
                }
                
                self.skip += 8
                completion(status: "Success", fetchedImages: images)
            },
            progressBlock: nil
        )
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Fetches one image using it's id
    //-------------------------------------------------------------------------//
    
    func fetchNewImage(fileId: String,
        completion:(status: String, fetchedImage: Image?) -> Void)
    {
        KCSFileStore.downloadData(fileId,
            completionBlock: {
                
                (downloadedResources, error) -> Void in
                
                guard error == nil else
                {
                    completion(status: "Error", fetchedImage: nil)
                    return
                }
                
                let file = downloadedResources[0] as! KCSFile
                let imgObj = Image(fileId: file.fileId, imageData: file.data)
                
                completion(status: "Success", fetchedImage: imgObj)
            },
            progressBlock: nil
        )
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Saves an image to the backend
    //-------------------------------------------------------------------------//
    
    func saveImage(imageToSave: UIImage,
        completion:(status: String, savedImg: Image?, errorMessage: String) -> Void)
    {
        let data = UIImageJPEGRepresentation(imageToSave, 1.0)
        
        let metadata = KCSMetadata()
            metadata.setGloballyReadable(true)
        
        KCSFileStore.uploadData(data,
            options: [
                KCSFileMimeType : "image/jpeg",
                KCSFileACL : metadata
            ],
            completionBlock: {
                
                (uploadInfo, error) -> Void in
                
                guard error == nil else
                {
                    completion(status: "Error", savedImg: nil, errorMessage: "Error saving image")
                    return
                }
                
                let imgObj = Image(fileId: uploadInfo.fileId, imageData: nil)
                    imgObj.image = imageToSave
                
                completion(status: "Success", savedImg: imgObj, errorMessage: "")
            },
            progressBlock: nil
        )
    }
}