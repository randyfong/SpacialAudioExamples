//
//  DeviceSearchTaskUserInterface.swift
//  BoseWearable
//
//  Created by Paul Calnan on 11/6/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import BLECore
import Foundation

/**
 Objects conforming to this protocol provide a user interface to show devices as they are discovered and allow the user to select a device.

 A `DeviceSearchTask` is initialized with an object conforming to the `DeviceSearchTaskUserInterface` protocol and calls these functions to show, hide, and update the user interface. The user interface calls back to the device search task via the `DeviceSearchTaskUserInterfaceDelegate` protocol.
 */
public protocol DeviceSearchTaskUserInterface {

    /// The delegate gets called by the user interface to notify when devices are selected or when the search has been cancelled.
    var delegate: DeviceSearchTaskUserInterfaceDelegate? { get set }

    /// Show the user interface.
    func show()

    /// Dismiss the user interface.
    func dismiss()

    /// Add the specified device with the specified signal strength to the user interface.
    func add(device: DiscoveredDevice, signalStrength: SignalStrength)

    /// Update the specified device with the specified signal strength to the user interface.
    func update(device: DiscoveredDevice, signalStrength: SignalStrength)

    /// Remove the specified device from the user interface.
    func remove(device: DiscoveredDevice)
}
