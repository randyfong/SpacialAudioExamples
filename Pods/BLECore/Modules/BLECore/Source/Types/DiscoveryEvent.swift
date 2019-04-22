//
//  DiscoveryEvent.swift
//  BLECore
//
//  Created by Paul Calnan on 8/13/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import CoreBluetooth
import Foundation

/// Indicates when a device is added, updated, or removed during discovery.
public enum DiscoveryEvent {

    /// A new device was discovered.
    case added(DiscoveredDevice)

    /// An already-discovered device was updated.
    case updated(DiscoveredDevice)

    /// An already-discovered device was removed. This occurs when advertising data for this device has not been seen within the timeout provided to `BluetoothManager.startScanning(removeAfter:callback:)`.
    case removed(DiscoveredDevice)
}
