# VIIFirebaseNotificationsHandler

VIIFirebaseNotificationsHandler is a library written in Swift that simplifies the handling of notifications using Firebase on iOS.

[![CocoaPods Compatible](https://img.shields.io/badge/Cocoapods-compatible-blue.svg)](https://img.shields.io/badge/Cocoapods-compatible-blue.svg)
[![License MIT](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://img.shields.io/badge/license-MIT-lightgrey.svg)
[![Platform iOS](https://img.shields.io/badge/platform-ios-yellow.svg)](https://img.shields.io/badge/platform-ios-yellow.svg)
[![Language Swift](https://img.shields.io/badge/language-swift-orange.svg)](https://img.shields.io/badge/language-swift-orange.svg)

## Features
- Provide easy calls for subscription and unsubscription to Firebase topics.
- Provide single calls for `didReceiveRemoteNotification`, `didRegisterForRemoteNotificationsWithDeviceToken`

## Requirements

- iOS 8.0+
- Xcode 8.2.1+
- Swift 2.3, 3.0

## Communication

- If you **found a bug**, open an issue.
- If you **have a request**, open an issue.
- Currently the project is not open for **contribution**.

## Installation
### Dependencies
This project depends on other Cocoapods libraries: `Firebase` and `FirebaseMessaging`.

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate VIIFirebaseNotificationsHandler into your Xcode project using CocoaPods, add the following line in your `Podfile`:

**Swift 3:**
```ruby
pod 'VIIFirebaseNotificationsHandler'
```

**Swift 2.3:**
```ruby
pod 'VIIFirebaseNotificationsHandler', :git => 'https://github.com/viitech/VIIFirebaseNotificationsHandler.git', :branch => 'Swift 2.3'
```

Then, run the following command:

```bash
$ pod install
```

### Manually

If you prefer not to use Cocoapods, you can integrate VIIFirebaseNotificationsHandler into your project manually.     
You only need to copy `VIIFirebaseNotificationsHandler.swift` into your project.


## Usage

### AppDelegate
#### didFinishLaunchingWithOptions

First, add this line to setup the topics you want to subscribe to.
```swift
VIIFirebaseNotificationsHandler.topics = ["topic1", "topic2", "topic3"]
```

Then, setup the `notificationTypes` variable with the notification types and the handler function for each type.
```swift
VIIFirebaseNotificationsHandler.notificationTypes = [
	"notificationType1": handler1,
	"notificationType2": handler2,
	"notificationType3": handler3
]
```

Following that, put the following line to handle the notification opening and connecting to FCM automatically for you!
All you need to change is the boolean indicating if the user is logged in (do your action or not).
```swift
VIIFirebaseNotificationsHandler.didFinishLaunchingWithOptions(application, isLoggedIn: true) // isLoggedIn always true if there's no login required.
```

#### didRegisterForRemoteNotificationsWithDeviceToken

Implement the `didRegisterForRemoteNotificationsWithDeviceToken` function in the AppDelegate.
The following line shown in the function will connect to FCM for you.
```swift
func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
	VIIFirebaseNotificationsHandler.didRegisterForRemoteNotificationsWithDeviceToken(deviceToken)
	// Any other action you want to do.
}
```

#### didReceiveRemoteNotification:userInfo:completionHandler

Implement the `didReceiveRemoteNotification:userInfo:completionHandler` function in the AppDelegate.
The following line shown in the function will handle the notifications for you based on the handlers you passed to the `notificationTypes` variable.
```swift
func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
	VIIFirebaseNotificationsHandler.didReceiveRemoteNotificationWithCompletion(application, userInfo: userInfo as! [String: AnyObject], completionHandler: completionHandler, isLoggedIn: true) // isLoggedIn always true if there's no login required.
}
```

#### didReceiveRemoteNotification:userInfo

Implement the `didReceiveRemoteNotification:userInfo` function in the AppDelegate.
The following line shown in the function will handle the notifications for you based on the handlers you passed to the `notificationTypes` variable.
```swift
func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
	VIIFirebaseNotificationsHandler.didReceiveRemoteNotification(application, userInfo: userInfo as! [String: AnyObject], isLoggedIn: true) // isLoggedIn always true if there's no login required.
}
```

### Login / AppDelegate (didFinishLaunchingWithOptions)
#### Setup Notifications
To register the app to receive remote notifications, the following function should be called:
```swift
VIIFirebaseNotificationsHandler.setupNotifications()
```
The above code will present the alert to the user for allowing notifications. It must be added where necessary:
- If users should receive notifications only after logging in, implement the code on success of the login process.
- If users should receive notifications without loggin in/app has no login, implement the code in `didFinishLaunchingWithOptions` before the [codes described above](#didFinishLaunchingWithOptions).

#### Refreshing Subscriptions
To refresh the subscriptions to Firebase based on new topics (after login or a specific action):
```swift
VIIFirebaseNotificationsHandler.topics.append("newTopic")
VIIFirebaseNotificationsHandler.shared.refreshFirebaseSubscribing()
```

### Other helpers
#### Subscribe / Unsubscribe to topics
In some cases, you may want to only subscribe or unsubscribe to topics e.g. on logout, you may want to unsubscribe from the topics:
```swift
// Subscribe to the topics
VIIFirebaseNotificationsHandler.shared.firebaseSubscription()

// Unsubscribe from the topics
VIIFirebaseNotificationsHandler.shared.firebaseUnsubscription()
```

#### Setting application badge number
The library provides a helper to setup the badge count of the application.
This function takes another function as a parameter. The function should do the needed calculations and return an `Int`.
```swift
VIIFirebaseNotificationsHandler.setBadgeCountWithFunction(badgeCountCalculation)
```

---

## Credits

Alamofire is owned and maintained by the [Vii Tech Solutions](http://viitech.net).

## License

VIIFirebaseNotificationsHandler is released under the MIT license. [See LICENSE](https://github.com/viitech/VIIFirebaseNotificationsHandler/blob/master/LICENSE.md) for details.
