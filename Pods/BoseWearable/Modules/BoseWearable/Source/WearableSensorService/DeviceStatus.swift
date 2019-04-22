//
//  DeviceStatus.swift
//  BoseWearable
//
//  Created by Paul Calnan on 9/28/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

/// Provides status information about a wearable device.
public struct DeviceStatus: OptionSet {
    public var rawValue: UInt16

    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }

    /// When set, indicates that pairing mode is currently enabled on the device.
    public static let pairingEnabled = DeviceStatus(rawValue: 1 << 0)

    /// When set, indicates that the device requires secure BLE pairing to be performed prior to accessing other encrypted characteristics.
    public static let secureBLEPairingRequired = DeviceStatus(rawValue: 1 << 1)

    /// When set, indicates that the device has been previously paired to the client reading this characteristic.
    public static let alreadyPairedToClient = DeviceStatus(rawValue: 1 << 2)

    /// When set, indicates that the wearable sensors service is temporarily suspended to allow other Bose services to send their data.
    public static let wearableSensorsServiceSuspended = DeviceStatus(rawValue: 1 << 3)
}
