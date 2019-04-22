//
//  DiscoveredDevice.swift
//  BLECore
//
//  Created by Paul Calnan on 8/13/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import CoreBluetooth
import Foundation

/// Represents a peripheral that has been discovered.
public class DiscoveredDevice {

    // MARK: - Stored Properties

    /// The underlying peripheral.
    public let peripheral: CBPeripheral

    /// The advertisement data most recently received for this peripheral.
    public private(set) var advertisementData: [String: Any]

    /// The RSSI value most recently received for this peripheral.
    public private(set) var rssi: Int

    // MARK: - Initialize / Update

    /**
     Creates a new `DiscoveredDevice` object with the specified peripheral, advertisement data, and RSSI value.

     - parameter peripheral: the underlying peripheral
     - parameter advertisementData: the advertisement data received when this peripheral was discovered
     - parameter rssi: the RSSI value for this peripheral
     */
    init(peripheral: CBPeripheral, advertisementData: [String: Any], rssi: Int) {
        self.peripheral = peripheral
        self.advertisementData = advertisementData
        self.rssi = rssi
    }

    /**
     Updates this `DiscoveredDevice` with the specified advertisement data and RSSI value. Note that if the specified `peripheral` is not equal to `self.peripheral`, this function does nothing and returns immediately.

     - parameter peripheral: the peripheral to update
     - parameter advertisementData: the updated advertisement data
     - parameter rssi: the updated RSSI value
     */
    func update(peripheral: CBPeripheral, advertisementData: [String: Any], rssi: Int) {
        guard self.peripheral == peripheral else {
            return
        }

        self.advertisementData = advertisementData
        self.rssi = rssi
    }

    // MARK: - Computed Properties

    /// The peripheral's identifier.
    public var identifier: UUID {
        return peripheral.identifier
    }

    /// The peripheral's name.
    public var name: String? {
        return peripheral.name
    }

    /// The local name from the advertisement data.
    public var localName: String? {
        return advertisementData[CBAdvertisementDataLocalNameKey] as? String
    }

    /// The current connection state of the peripheral.
    public var state: CBPeripheralState {
        return peripheral.state
    }
}
