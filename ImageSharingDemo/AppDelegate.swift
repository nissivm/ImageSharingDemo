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
        
        oneSignal = OneSignal(launchOptions: launchOptions, appId: Constants.appId, handleNotification: {
            
                (message, additionalData, isActive) in
            
                let entityId = additionalData["EntityId"] as! String
                print("Entity ID = \(entityId)")
            },
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
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings)
    {
        let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setObject("true", forKey: "RegisteredNotificationSettings")
            defaults.synchronize()
        
        NSNotificationCenter.defaultCenter().postNotificationName("SessionStarted", object: nil)
    }
    
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
    
    func sendPushNotification(entityId: String, completion:(status: String) -> Void)
    {
        let params = ["contents": ["en": "New photo!"],
                      "tags": ["key": "RegisteredForPushes", "relation": "=", "value": "true"],
                      "data": ["EntityId": entityId]]
        
        oneSignal.postNotification(params,
            onSuccess: {(result) in
                completion(status: "Success")
            },
            onFailure: {(error) in
                completion(status: "Error")
            })
    }

    func applicationWillResignActive(application: UIApplication) {}

    func applicationDidEnterBackground(application: UIApplication) {}

    func applicationWillEnterForeground(application: UIApplication) {}

    func applicationDidBecomeActive(application: UIApplication) {}

    func applicationWillTerminate(application: UIApplication) {}
}

