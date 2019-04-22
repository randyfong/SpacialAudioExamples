//
//  DeviceSearchTaskUserInterfaceDelegate.swift
//  BoseWearable
//
//  Created by Paul Calnan on 11/6/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import BLECore
import Foundation

/// This protocol allows a `DeviceSearchTaskUserInterface` to call back to the internal device search task indicating that the user selected a device or cancelled the operation.
public protocol DeviceSearchTaskUserInterfaceDelegate: class {

    /// Indicates that the user selected the specified device.
    func selected(device: DiscoveredDevice)

    /// Indicates that the user cancelled the device search.
    func cancelled()
}
