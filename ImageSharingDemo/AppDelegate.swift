//
//  AppDelegate.swift
//  ImageSharingDemo
//
//  Created by Nissi Vieira Miranda on 2/18/16.
//  Copyright © 2016 Nissi Vieira Miranda. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var oneSignal: OneSignal!
    let kinveyBackend = KinveyBackend()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        // One Signal initialization (Calls registerForRemoteNotifications):
        
        oneSignal = OneSignal(launchOptions: launchOptions,
                                      appId: Constants.appId,
                         handleNotification: nil,
                               autoRegister: false)
        
        oneSignal.enableInAppAlertNotification(false)
        
        // Kinvey initialization:
        
        KCSClient.sharedClient().initializeKinveyServiceForAppKey(Constants.appKey,
                                                withAppSecret: Constants.appSecret,
                                                    usingOptions: nil)
        
        return true
    }
    
    // Called after a call to registerForRemoteNotifications
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData)
    {
        
    }
    
    func registerUserForPushNotifications()
    {
        oneSignal.registerForPushNotifications() // Calls registerUserNotificationSettings:
    }
    
    // Called after a call to registerUserNotificationSettings:
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings)
    {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if defaults.objectForKey("RegisteredNotificationSettings") == nil
        {
            defaults.setObject("true", forKey: "RegisteredNotificationSettings")
            defaults.synchronize()
            
            oneSignal.IdsAvailable({
                
                (userId, pushToken) in
                
                let user = KCSUser.activeUser()
                    user.setValue(userId, forAttribute: "userId")
                user.saveWithCompletionBlock({
                
                    (user, error) -> Void in
                    
                    NSNotificationCenter.defaultCenter().postNotificationName("UserRegistered", object: nil)
                })
            })
        }
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Sends push notifications
    //-------------------------------------------------------------------------//
    
    func sendPushNotification(fileId: String, completion:(status: String, message: String) -> Void)
    {
        kinveyBackend.fetchUsers({
            
            [unowned self](status, fetchedUsers) -> Void in
            
            guard status == "Success" else
            {
                completion(status: "Error", message: "Users fetching failed")
                return
            }
            
            var userIds = [String]()
            let activeUserId = KCSUser.activeUser().getValueForAttribute("userId") as! String
            
            for user in fetchedUsers!
            {
                let userId = user.getValueForAttribute("userId") as! String
                
                if userId != activeUserId
                {
                    userIds.append(userId)
                }
            }
            
            guard userIds.count > 0 else
            {
                completion(status: "No users", message: "No users to notify")
                return
            }
            
            let params = ["contents": ["en": "New photo!"],
                "include_player_ids": userIds,
                     "ios_badgeType": "Increase",
                    "ios_badgeCount": 1,
                 "content_available": true,
                         "ios_sound": "notification.caf",
                              "data": ["EntityId": fileId]]
            
            self.oneSignal.postNotification(params as [NSObject : AnyObject],
                onSuccess: {
                    (result) in
                    print("Push notification sent!")
                    completion(status: "Success", message: "Notification successfully sent!")
                },
                onFailure: {
                    (error) in
                    print("Error pushing notification.")
                    completion(status: "Error", message: "Notification failed")
            })
        })
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Receives push notifications
    //-------------------------------------------------------------------------//
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject],
        fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void)
    {
        if let custom = userInfo["custom"] as? [String : AnyObject]
        {
            let a = custom["a"] as! [String : String]
            let entityId = a["EntityId"]!
            
            var found = false
            for photoId in Auxiliar.newPhotosIds
            {
                if photoId == entityId
                {
                    found = true
                    break
                }
            }
            
            if found == false
            {
                Auxiliar.newPhotosIds.append(entityId)
                NSNotificationCenter.defaultCenter().postNotificationName("NewPhoto", object: nil)
            }
        }
        
        completionHandler(UIBackgroundFetchResult.NewData)
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Unused
    //-------------------------------------------------------------------------//

    func applicationWillResignActive(application: UIApplication) {}

    func applicationDidEnterBackground(application: UIApplication) {}

    func applicationWillEnterForeground(application: UIApplication) {}

    func applicationDidBecomeActive(application: UIApplication) {}

    func applicationWillTerminate(application: UIApplication) {}
}

