//
//  TypedNotification.swift
//  BLECore
//
//  Created by Paul Calnan on 3/13/18.
//  Copyright © 2018 Rocket Insights, Inc. All rights reserved.
//

import Foundation

// Roughly based on https://github.com/alexjohnj/TypedNotification

/// The actual TypedNotification object is passed in the Foundation `Notification` object's `userInfo` dictionary under this key.
let kNotificationKey = "notification"

/// The `TypedNotification` protocol defines the properties of a strongly typed notification. The `name` property will be automatically generated from the type's name, but can be modified if needed.
public protocol TypedNotification {
    /// The name of the notification to be used as an identifier
    static var name: String { get }
}

extension TypedNotification {
    /// The name of the notification, defaulting to the type name
    public static var name: String {
        return "\(Self.self)"
    }

    /// The name of the notification for Foundation methods. Defaults to the value of the static `name` field.
    static var notificationName: Notification.Name {
        return Notification.Name(Self.name)
    }

    /// Creates a Foundation `Notification` with the specified sender.
    func notification(withSender sender: Any) -> Notification {
        return Notification(name: Self.notificationName, object: sender, userInfo: [kNotificationKey: self])
    }
}

/// An opaque `NotificationToken` used to add and remove observers of typed notifications. The object retains the token returned by `NotificationCenter.addObserver(for:object:queue:)` as well as the `NotificationCenter`. When the object is deallocated, we deregister the observer from the retained `NotificationCenter` using the retained token.
public class NotificationToken {

    /// The token returned by `NotificationCenter`
    fileprivate let token: NSObjectProtocol

    /// The `NotificationCenter` that the handler was registered with.
    fileprivate let center: NotificationCenter

    /// Creates a new `NotificationToken` with the specified values.
    fileprivate init(token: NSObjectProtocol, center: NotificationCenter) {
        self.token = token
        self.center = center
    }

    /// Deregisters the observer from the retained notification center using the retained token.
    deinit {
        center.removeObserver(token: self)
    }
}

extension NotificationCenter {

    /**
     Post a `TypedNotification` from the specified sender.

     - Parameters:
         - notification: the notification to post
         - sender: the sender of the notification
     */
    public func post<T: TypedNotification>(_ notification: T, from sender: Any) {
        post(notification.notification(withSender: sender))
    }

    /**
     Register a block to be executed when the specified `TypedNotification` type is posted.

     The API works like `NotificationCenter.addObserver(forName:object:queue:using:)`. Note that the returned `NotificationToken` must be retained. Once it is deallocated, the observer is deregistered.

     If the closure passed to this function references `self`, you must add `[weak self]` to the closure's capture list.

     Example:

     ```
     struct MyNotification: TypedNotification { ... }

     class MyViewController: UIViewController {
         private var notificationToken: NotificationToken?

         override func viewDidLoad() {
             super.viewDidLoad()

             notificationToken = NotificationCenter.default.addObserver(for: MyNotification.self) { [weak self] (notification) in
                 self?.received(notification)
             }
         }

         private func received(_ notification: MyNotification) {
             ...
         }
     }
     ```

     In the example, `MyViewController` retains the `NotificationToken` returned by `NotificationCenter.addObserver()`. When the `MyViewController` instance is deallocated, the `NotificationToken` is deallocated and the observer is deregistered. The `[weak self]` capture list is important. Without it, there will be a retain cycle.

     - Parameters:
         - for: the `TypedNotification` subtype
         - object: The object from which you want to receive notifications. Pass `nil` to receive all notifications.
         - queue: The queue on which to execute the block. Per `NotificationCenter` documentation, if you pass `nil`, the block is run synchronously on the posting thread.
         - block: The block to be executed when the notification is received. The block takes a single instance of the `type` as an argument.

     - Returns:
         A `NotificationToken` object. The observer is automatically deregistered when this token object is deallocated, so be sure to retain a reference to it.
     */

    public func addObserver<T: TypedNotification>(for type: T.Type,
                                                  object: Any? = nil,
                                                  queue: OperationQueue? = nil,
                                                  using block: @escaping (T) -> Void) -> NotificationToken {

        let token = addObserver(forName: T.notificationName, object: object, queue: queue) { (notification) in
            guard let typedNotification = notification.userInfo?[kNotificationKey] as? T else {
                return
            }

            block(typedNotification)
        }

        return NotificationToken(token: token, center: self)
    }

    /**
     Deregisters the observer associated with the specified token.

     - Parameters:
         - token: the token returned when adding the observer
     */
    public func removeObserver(token: NotificationToken) {
        removeObserver(token.token)
    }
}
