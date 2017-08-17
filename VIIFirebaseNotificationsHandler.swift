//
//  VIIFirebaseNotificationsHandler.swift
//  VII Tech Solutions
//
//  Created by VII Tech Solutions on 8/17/17.
//  Copyright © 2017 VII Tech Solutions. All rights reserved.
//

import Foundation
import Firebase
import FirebaseMessaging
import UserNotifications

// Type Alias
typealias notificationAction = ((application: UIApplication, userInfo: [String: AnyObject], completionHandler: (UIBackgroundFetchResult) -> Void)->Void)

class VIIFirebaseNotificationsHandler {
    
    // Variables
    static var topics: [String] = []
    static var notificationTypes: [String: notificationAction] = [:]
    private static var badgeCount = 0 {
        didSet {
            if (badgeCount == 0) {
                let ln = UILocalNotification()
                ln.applicationIconBadgeNumber = -1
                UIApplication.sharedApplication().presentLocalNotificationNow(ln)
            } else {
                UIApplication.sharedApplication().applicationIconBadgeNumber = badgeCount
            }
        }
    }
    
    static let shared = VIIFirebaseNotificationsHandler()
    
    //This prevents others from using the default '()' initializer for this class.
    private init() { }
    
    @objc private func connectToFCM() {
        // Won't connect unless there is a token
        if (UIApplication.sharedApplication().isRegisteredForRemoteNotifications()) {
            if let _ = FIRInstanceID.instanceID().token() {
                // Disconnect previous FCM connection if it exists.
                FIRMessaging.messaging().disconnect()
                
                FIRMessaging.messaging().connectWithCompletion({ (error) in
                    if error != nil {
                    } else {
                        self.firebaseSubscription()
                    }
                })
            }
        }
    }
    
    internal func firebaseSubscription() {
        for topic in VIIFirebaseNotificationsHandler.topics {
            print("SUBSCRIBING TO = \(topic)")
            FIRMessaging.messaging().subscribeToTopic("/topics/\(topic)")
        }
    }
    
    internal func firebaseUnsubscription() {
        for topic in VIIFirebaseNotificationsHandler.topics {
            print("UNSUBSCRIBING FROM = \(topic)")
            FIRMessaging.messaging().unsubscribeFromTopic("/topics/\(topic)")
        }
    }
    
    internal func refreshFirebaseSubscribing() {
        firebaseUnsubscription()
        firebaseSubscription()
    }
    
    @objc private func disconnectFromFCM() {
        if (UIApplication.sharedApplication().isRegisteredForRemoteNotifications()) {
            // Unsubscribe from registered topics
            firebaseUnsubscription()
            // Disconnnect
            FIRMessaging.messaging().disconnect()
        }
    }
    
    static func setBadgeCountExplicitly(count: Int) {
        badgeCount = count
    }
    
    static func incrementBadgeCount() {
        badgeCount += 1
    }
    
    static func setBadgeCountWithFunction(function: ()->Int) {
        badgeCount = function() // Returns Int
    }
    
    static func didFinishLaunchingWithOptions(application: UIApplication, isLoggedIn: Bool) {
        // Connect or Disconnect to FCM
        // Check if logged in and registered for notifications
        if (isLoggedIn) {
            // Connect to Firebase
            VIIFirebaseNotificationsHandler.shared.connectToFCM()
        } else if (!isLoggedIn) { // If not registered for notifications or logged out
            VIIFirebaseNotificationsHandler.shared.disconnectFromFCM()
        }
    }
    
    static func didRegisterForRemoteNotificationsWithDeviceToken(deviceToken: NSData) {
        FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: .Sandbox)
        FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: .Prod)
        // Connect to FCM.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(connectToFCM), name: "firInstanceIDTokenRefresh", object: nil)
        VIIFirebaseNotificationsHandler.shared.connectToFCM()
    }
    
    static func didReceiveRemoteNotificationWithCompletion(application: UIApplication, userInfo: [String : AnyObject], completionHandler: (UIBackgroundFetchResult) -> Void = {_ in}, isLoggedIn: Bool) {
        FIRMessaging.messaging().appDidReceiveMessage(userInfo)
        
        NSNotificationCenter.defaultCenter().postNotificationName("ReceivedNotification", object:userInfo)
        
        VIIFirebaseNotificationsHandler.handleNotifications(application, userInfo: userInfo, completionHandler: completionHandler, isLoggedIn: isLoggedIn)
    }
    
    static func didReceiveRemoteNotification(application: UIApplication, userInfo: [String : AnyObject], isLoggedIn: Bool) {
        FIRMessaging.messaging().appDidReceiveMessage(userInfo)
        if (application.applicationState != UIApplicationState.Active) {
            VIIFirebaseNotificationsHandler.handleNotifications(application, userInfo: userInfo, isLoggedIn: isLoggedIn)
        }
    }
    
    static func setupNotifications() {
        // Override point for customization after application launch.
        if #available(iOS 10.0, *) {
            let authOptions: UNAuthorizationOptions = [.Alert, .Badge, .Sound]
            UNUserNotificationCenter.currentNotificationCenter().requestAuthorizationWithOptions(authOptions, completionHandler: {_, _ in })
            
            // For iOS 10 data message (sent via FCM)
            FIRMessaging.messaging().remoteMessageDelegate = appDelegate
            UNUserNotificationCenter.currentNotificationCenter().delegate = appDelegate
            
        } else {
            let userNotificationTypes: UIUserNotificationType = [.Alert, .Badge, .Sound]
            let settings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
            UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        }
        
        if (!UIApplication.sharedApplication().isRegisteredForRemoteNotifications()) {
            UIApplication.sharedApplication().registerForRemoteNotifications()
        } else {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(connectToFCM), name: "firInstanceIDTokenRefresh", object: nil)
            VIIFirebaseNotificationsHandler.shared.connectToFCM()
        }
    }
    
    static func handleNotifications(application: UIApplication, userInfo: [String : AnyObject]?, completionHandler: (UIBackgroundFetchResult) -> Void = {_ in}, isLoggedIn: Bool) {
        if (!isLoggedIn) {
            return
        }
        
        if let userInfo = userInfo {
            let type = userInfo["type"]
            
            if let type = type as? String {
                for key in notificationTypes.keys {
                    if (type.lowercaseString == key.lowercaseString) {
                        notificationTypes[key]!(application: application, userInfo: userInfo, completionHandler: completionHandler)
                    }
                }
            }
        }
    }
}
