//
//  ListenerToken.swift
//  BoseWearable
//
//  Created by Paul Calnan on 10/25/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import BLECore
import Foundation

/// An opaque token used to add and remove listeners backed by `NotificationCenter`. A `ListenerToken` object retains the token returned by `NotificationCenter.addObserver(for:object:queue:)` as well as the `NotificationCenter`. When the object is deallocated, we automatically remove the observer from the retained `NotificationCenter` using the retained token.
public class ListenerToken {

    /// The underlying `NotificationToken` that we are wrapping.
    let notificationToken: NotificationToken

    /// Create a new `ListenerToken`, wrapping the specified `NotificationToken`.
    init(_ notificationToken: NotificationToken) {
        self.notificationToken = notificationToken
    }
}
