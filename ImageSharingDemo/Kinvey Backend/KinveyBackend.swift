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
    // MARK: Fetching from Images collection
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
}