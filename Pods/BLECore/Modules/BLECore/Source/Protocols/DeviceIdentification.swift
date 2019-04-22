//
//  DeviceIdentification.swift
//  BLECore
//
//  Created by Paul Calnan on 8/28/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import CoreBluetooth
import Foundation
import Logging

/**
 The `DeviceIdentification` protocol provides the information necessary to identify a particular device type based upon its advertised services, its advertisement data, and the services a peripheral provides.

 ### Matching Algorithm

 The union of the `requiredAdvertisedServiceUUIDs` across all `Device` types registered in the `BluetoothManager` is passed as the `serviceUUIDs` argument to `CBCentralManager.scanForPeripherals(withServices:options:)`.

 When devices are discovered, the list of registered `Device` types is queried. To be considered a match, the following must be true of a discovered peripheral in order for it to be converted to a `DiscoveredDevice` and emitted as a `DiscoveryEvent`:

 - The advertised service UUIDs contained in the advertisement data (under `CBAdvertisementDataServiceUUIDsKey`):
     - Must contain all of the elements in `requiredAdvertisedServiceUUIDs`.
     - Must not contain any of the elements in `forbiddenAdvertisedServiceUUIDs`.
 - `advertisementFilter(peripheral:advertisementData:)` must return true.

 After selecting a `DiscoveredDevice` to connect to, we attempt to instantiate the `Device` type. The list of matching `Device` types are iterated over in order. If the peripheral provides the services specified in `requiredServices`, we attempt to instantiate that `Device` type for this peripheral. We return the first successfully instantiated `Device` type.
 */
public protocol DeviceIdentification {

    /**
     The services that are required to be advertised by devices of this type. Used by the `BluetoothManager` class when scanning for peripherals. Also used when determining whether a particular peripheral and its advertisement data match this device type.
     */
    var requiredAdvertisedServiceUUIDs: Set<CBUUID> { get }

    /**
     The services that must not be advertised by devices of this type. Used when determining whether a particular peripheral and its advertisement data match this device type.
     */
    var forbiddenAdvertisedServiceUUIDs: Set<CBUUID> { get }

    /// The services required by devices of this type. During the process of opening a `Session`, the services provided by a peripheral are discovered. Once the services are discovered, a `Device` object is instantiated. Each of the registered `Device` types are checked against the peripheral to see if the peripheral provides the required services. If it does, that peripheral is used to instantiate that `Device` type.
    var requiredServices: [ServiceIdentification] { get }

    /**
     Allows a device type to use advertisement data to augment the device identification process. The `BluetoothManager` class scans for peripherals using the `requiredAdvertisedServiceUUIDs` field to specify the advertised services. When a `BluetoothManager` is notified that a peripheral has been discovered, it calls this function with the received advertisement data to allow the device type the opportunity to say whether the discovered device is in fact the target type.

     In simple cases where there is a single device type that is adequately identified by the `requiredAdvertisedServiceUUIDs` field, this function can immediately return `true`.

     - parameter peripheral: the discovered peripheral
     - parameter advertisementData: a dictionary containing any advertisement data
     - returns: `true` if this discovered peripheral and advertisement represents a device of this type, `false` otherwise
     */
    func advertisementFilter(peripheral: CBPeripheral, advertisementData: [String: Any]) -> Bool
}

extension DeviceIdentification {

    /// Tests whether the specified discovered peripheral and its associated advertisement data match this `DeviceInformation` object. First, the advertisement's service UUIDs are unpacked and compared against the `requiredAdvertisedServiceUUIDs`. If there are any `requiredAdvertisedServiceUUIDs` that are not in the advertisement, this function returns `false`. If all of the `requiredAdvertisedServiceUUIDs` are in the advertisement, the `advertisementFilter(peripheral:advertisementData:)` function is called and its result is returned by this function.
    func matches(peripheral: CBPeripheral, advertisementData: [String: Any]) -> Bool {
        guard let uuids = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] else {
            return false
        }

        let advertisedServiceUUIDs = Set(uuids)
        guard
            requiredAdvertisedServiceUUIDs.isSubset(of: advertisedServiceUUIDs),
            advertisedServiceUUIDs.isDisjoint(with: forbiddenAdvertisedServiceUUIDs)
        else {
            return false
        }

        return advertisementFilter(peripheral: peripheral, advertisementData: advertisementData)
    }
}
