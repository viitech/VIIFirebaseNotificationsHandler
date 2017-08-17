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
typealias notificationAction = ((_ application: UIApplication, _ userInfo: [String: AnyObject], _ completionHandler: @escaping (UIBackgroundFetchResult) -> Void)->Void)

class VIIFirebaseNotificationsHandler {
    
    // Variables
    static var topics: [String] = []
    static var notificationTypes: [String: notificationAction] = [:]
    private static var badgeCount = 0 {
        didSet {
            if (badgeCount == 0) {
                let ln = UILocalNotification()
                ln.applicationIconBadgeNumber = -1
                UIApplication.shared.presentLocalNotificationNow(ln)
            } else {
                UIApplication.shared.applicationIconBadgeNumber = badgeCount
            }
        }
    }
    
    static let shared = VIIFirebaseNotificationsHandler()
    
    //This prevents others from using the default '()' initializer for this class.
    private init() { }
    
    @objc private func connectToFCM() {
        // Won't connect unless there is a token
        if (UIApplication.shared.isRegisteredForRemoteNotifications) {
            if let _ = FIRInstanceID.instanceID().token() {
                // Disconnect previous FCM connection if it exists.
                FIRMessaging.messaging().disconnect()
                
                FIRMessaging.messaging().connect(completion: { (error) in
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
            FIRMessaging.messaging().subscribe(toTopic: "/topics/\(topic)")
        }
    }
    
    internal func firebaseUnsubscription() {
        for topic in VIIFirebaseNotificationsHandler.topics {
            print("UNSUBSCRIBING FROM = \(topic)")
            FIRMessaging.messaging().unsubscribe(fromTopic: "/topics/\(topic)")
        }
    }
    
    internal func refreshFirebaseSubscribing() {
        firebaseUnsubscription()
        firebaseSubscription()
    }
    
    @objc private func disconnectFromFCM() {
        if (UIApplication.shared.isRegisteredForRemoteNotifications) {
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
    
    static func didRegisterForRemoteNotificationsWithDeviceToken(deviceToken: Data) {
        FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: .sandbox)
        FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: .prod)
        // Connect to FCM.
        NotificationCenter.default.addObserver(self, selector: #selector(connectToFCM), name: NSNotification.Name(rawValue: "firInstanceIDTokenRefresh"), object: nil)
        VIIFirebaseNotificationsHandler.shared.connectToFCM()
    }
    
    static func didReceiveRemoteNotificationWithCompletion(application: UIApplication, userInfo: [String : AnyObject], completionHandler: @escaping (UIBackgroundFetchResult) -> Void = {_ in}, isLoggedIn: Bool) {
        FIRMessaging.messaging().appDidReceiveMessage(userInfo)
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ReceivedNotification"), object:userInfo)
        
        VIIFirebaseNotificationsHandler.handleNotifications(application: application, userInfo: userInfo, completionHandler: completionHandler, isLoggedIn: isLoggedIn)
    }
    
    static func didReceiveRemoteNotification(application: UIApplication, userInfo: [String : AnyObject], isLoggedIn: Bool) {
        FIRMessaging.messaging().appDidReceiveMessage(userInfo)
        if (application.applicationState != UIApplicationState.active) {
            VIIFirebaseNotificationsHandler.handleNotifications(application: application, userInfo: userInfo, isLoggedIn: isLoggedIn)
        }
    }
    
    static func setupNotifications() {
        // Override point for customization after application launch.
        if #available(iOS 10.0, *) {
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in })
            
            // For iOS 10 data message (sent via FCM)
            FIRMessaging.messaging().remoteMessageDelegate = appDelegate
            UNUserNotificationCenter.current().delegate = appDelegate
            
        } else {
            let userNotificationTypes: UIUserNotificationType = [.alert, .badge, .sound]
            let settings = UIUserNotificationSettings(types: userNotificationTypes, categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
        
        if (!UIApplication.shared.isRegisteredForRemoteNotifications) {
            UIApplication.shared.registerForRemoteNotifications()
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(connectToFCM), name: NSNotification.Name(rawValue: "firInstanceIDTokenRefresh"), object: nil)
            VIIFirebaseNotificationsHandler.shared.connectToFCM()
        }
    }
    
    static func handleNotifications(application: UIApplication, userInfo: [String : AnyObject]?, completionHandler: @escaping (UIBackgroundFetchResult) -> Void = {_ in}, isLoggedIn: Bool) {
        if (!isLoggedIn) {
            return
        }
        
        if let userInfo = userInfo {
            let type = userInfo["type"]
            
            if let type = type as? String {
                for key in notificationTypes.keys {
                    if (type.lowercased() == key.lowercased()) {
                        notificationTypes[key]!(application, userInfo, completionHandler)
                    }
                }
            }
        }
    }
}
