//
//  WearableDeviceSession.swift
//  BoseWearable
//
//  Created by Paul Calnan on 10/13/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

/// Represents a connection with a wearable device. A `WearableDeviceSession` must be retained for as long as you are interested in the connection. Once a `WearableDeviceSession` is deallocated, the connection automatically closed and disposed.
public protocol WearableDeviceSession {

    /// The delegate gets notified of connection-related events.
    var delegate: WearableDeviceSessionDelegate? { get set }

    /// The wearable device. If there was an error opening the session, this will be `nil`.
    var device: WearableDevice? { get }

    /// Opens the connection and establishes communications with the wearable device.
    func open()

    /// Closes the connection and terminates communications with the wearable device.
    func close()
}
