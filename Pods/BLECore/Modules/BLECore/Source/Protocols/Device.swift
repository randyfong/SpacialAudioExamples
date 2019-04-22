//
//  Device.swift
//  BLECore
//
//  Created by Paul Calnan on 8/28/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import CoreBluetooth
import Foundation

/**
 Instances of the `Device` protocol correspond to a particular type of device supported by an application. The BLECore library identifies a device based upon the values provided by the `identification` property. See `DeviceIdentification` for further details.

 A set of device types (i.e., types implementing the `Device` protocol) must be registered with the `BluetoothManager`. This is used to filter discovered devices allowing applications to consider only devices that provide the required services.

 During device discovery, only peripherals that match an `identification` object on a registered `Device` type are considered. See `DeviceInformation` for more details.

 When a session is opened with a peripheral, an instance of the matching device type (i.e., the type implementing the `Device` protocol) is created.
 */
public protocol Device {

    /// Information identifying this device type.
    static var identification: DeviceIdentification { get }

    /// The remote peripheral that this device represents.
    var peripheral: CBPeripheral { get }

    /// The services associated with this device.
    var services: ServiceSet { get }

    /**
     Creates a new device instance with the specified remote peripheral and its services.

     - parameter peripheral: The remote peripheral.
     - parameter services: The services for this device.
     - throws: `BLECoreError.missingService` if a required service is missing
     - throws: `BLECoreError.incorrectServiceType` if an incorrect service is provided
     */
    init(peripheral: CBPeripheral, services: ServiceSet) throws
}
