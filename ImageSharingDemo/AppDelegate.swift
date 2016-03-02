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

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        // One Signal initialization (Calls registerForRemoteNotifications):
        
        oneSignal = OneSignal(launchOptions: launchOptions,
                                      appId: Constants.appId,
                         handleNotification: nil,
                               autoRegister: false)
        
        // Kinvey initialization:
        
        KCSClient.sharedClient().initializeKinveyServiceForAppKey(Constants.appKey,
                                                withAppSecret: Constants.appSecret,
                                                    usingOptions: nil)
        
        return true
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
            
            NSNotificationCenter.defaultCenter().postNotificationName("SessionStarted", object: nil)
        }
    }
    
    // Called after a call to registerForRemoteNotifications
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData)
    {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if defaults.objectForKey("RegisteredForPushes") == nil
        {
            oneSignal.sendTag("RegisteredForPushes", value: "true")
            
            defaults.setObject("true", forKey: "RegisteredForPushes")
            defaults.synchronize()
        }
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Sends push notifications
    //-------------------------------------------------------------------------//
    
    func sendPushNotification(fileId: String, completion:(status: String) -> Void)
    {
        let params = ["contents": ["en": "New photo!"],
                          "tags": ["key": "RegisteredForPushes", "relation": "=", "value": "true"],
                 "ios_badgeType": "Increase",
                "ios_badgeCount": 1,
             "content_available": true,
                     "ios_sound": "notification.caf",
                          "data": ["EntityId": fileId]]
        
        oneSignal.postNotification(params,
            onSuccess: {
                (result) in
                print("Push notification sent!")
                completion(status: "Success")
            },
            onFailure: {
                (error) in
                print("Error pushing notification.")
                completion(status: "Error")
            })
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Receives push notifications
    //-------------------------------------------------------------------------//
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject],
        fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void)
    {
        let entityId = userInfo["EntityId"] as! String
        Auxiliar.newPhotosIds.append(entityId)
        NSNotificationCenter.defaultCenter().postNotificationName("NewPhoto", object: nil)
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

