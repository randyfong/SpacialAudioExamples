//
//  DeviceSearchMode.swift
//  BoseWearable
//
//  Created by Paul Calnan on 9/19/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

/// Indicates the mode of operation for the device search.
public enum DeviceSearchMode {

    /// Always present a view controller to the user, allowing the user to select a device.
    case alwaysShowUI

    /**
     If the most-recently connected device is found before `timeout` elapses, this device is automatically selected. If no connected device is found before `timeout` elapses, the `DeviceSearchTask` will present user interface allowing the user to select a device.

     Note that if the most-recently connected device is found after the user interface has been shown, it will not be automatically selected.
     */
    case automaticallySelectMostRecentlyConnectedDevice(timeout: TimeInterval)
}
