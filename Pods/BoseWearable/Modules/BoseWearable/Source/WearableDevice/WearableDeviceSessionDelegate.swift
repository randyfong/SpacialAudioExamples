//
//  WearableDeviceSessionDelegate.swift
//  BoseWearable
//
//  Created by Paul Calnan on 10/18/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

/// A wearable device session delegate gets notified of connection-related events.
public protocol WearableDeviceSessionDelegate: class {

    /// Indicates that the session was opened.
    func sessionDidOpen(_ session: WearableDeviceSession)

    /// Indicates that the session failed to open.
    func session(_ session: WearableDeviceSession, didFailToOpenWithError error: Error?)

    /// Indicates that the session was closed. If the specified error is `nil`, the session closed normally. Otherwise, the error indicates the cause for the closure.
    func session(_ session: WearableDeviceSession, didCloseWithError error: Error?)
}
