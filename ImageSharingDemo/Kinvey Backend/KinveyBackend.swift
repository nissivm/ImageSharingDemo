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
    // MARK: Fetches images using a query
    //-------------------------------------------------------------------------//
    
    var skip: Int = 0
    
    func fetchImages(completion:(status: String, objects: [Image]?) -> Void)
    {
        let store = KCSLinkedAppdataStore.storeWithOptions([
            KCSStoreKeyCollectionName : "Images",
            KCSStoreKeyCollectionTemplateClass : Image.self
            ])
        
        let query = KCSQuery(onField: "imageLink", usingConditional: .KCSNotEqual,
                            forValue: "dummylink")
            query.limitModifer = KCSQueryLimitModifier(limit: 8)
            query.skipModifier = KCSQuerySkipModifier(withcount: skip)
            query.addSortModifier(KCSQuerySortModifier(field: "date",
                                    inDirection: KCSSortDirection.Descending))
        
        store.queryWithQuery(query,
            withCompletionBlock: {
                
                [unowned self](objectsOrNil, errorOrNil) -> Void in
                
                guard errorOrNil == nil else
                {
                    completion(status: "Error", objects: nil)
                    return
                }
                
                guard let results = objectsOrNil as? [Image] else
                {
                    completion(status: "Error", objects: nil)
                    return
                }
                
                if results.count > 0
                {
                    self.skip += 8
                    completion(status: "Success", objects: results)
                }
                else
                {
                    completion(status: "No results", objects: nil)
                }
            },
            withProgressBlock: nil
        )
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Fetches images using their ids
    //-------------------------------------------------------------------------//
    
    func fetchNewImages(entitiesIds: [String],
        completion:(status: String, fetchedImages: [Image]?) -> Void)
    {
        let store = KCSLinkedAppdataStore.storeWithOptions([
            KCSStoreKeyCollectionName : "Images",
            KCSStoreKeyCollectionTemplateClass : Image.self
            ])
        
        store.loadObjectWithID(entitiesIds,
            withCompletionBlock: {
                
                (objectsOrNil, errorOrNil) -> Void in
                
                guard errorOrNil == nil else
                {
                    completion(status: "Error", fetchedImages: nil)
                    return
                }
                
                guard let results = objectsOrNil as? [Image] else
                {
                    completion(status: "Error", fetchedImages: nil)
                    return
                }
                
                completion(status: "Success", fetchedImages: results)
            },
            withProgressBlock: nil
        )
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Saves an image to the backend
    //-------------------------------------------------------------------------//
    
    func saveImage(imageToSave: UIImage,
        completion:(status: String, savedImg: Image?, errorMessage: String) -> Void)
    {
        let image = Image()
            image.image = imageToSave
            image.date = NSDate()
        
        let store = KCSLinkedAppdataStore.storeWithOptions([
            KCSStoreKeyCollectionName : "Images",
            KCSStoreKeyCollectionTemplateClass : Image.self
            ])
        
        store.saveObject(image,
            withCompletionBlock: {
                
                (objectsOrNil, errorOrNil) -> Void in
                
                guard errorOrNil == nil else
                {
                    completion(status: "Error", savedImg: nil, errorMessage: "Error saving image")
                    return
                }
                
                guard let results = objectsOrNil as? [Image] else
                {
                    completion(status: "Error", savedImg: nil, errorMessage: "Error saving image")
                    return
                }
                
                let savedImg = results[0]
                completion(status: "Success", savedImg: savedImg, errorMessage: "")
            },
            withProgressBlock: nil
        )
    }
}