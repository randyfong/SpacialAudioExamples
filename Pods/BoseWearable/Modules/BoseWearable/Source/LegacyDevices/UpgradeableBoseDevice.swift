//
//  UpgradeableBoseDevice.swift
//  BoseWearable
//
//  Created by Paul Calnan on 11/5/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import BLECore
import CoreBluetooth
import Foundation

/**
 Represents a Bose device that, based upon the product ID provided in the advertisement data, requires a firmware update in order to support connections from the Bose Wearable SDK.

 Note that this class does not need to implement `WearableDevice`. Since no connection to the device is needed to make the determination that a firmware upgrade is needed (all necessary information is contained in the advertisement), we can simply throw the appropriate error in the initializer. This will cause the connection to fail before it is even opened.
 */
class UpgradeableBoseDevice: Device {

    // MARK: - BLECore

    let peripheral: CBPeripheral

    let services: ServiceSet

    required init(peripheral: CBPeripheral, services: ServiceSet) throws {
        throw BoseWearableError.firmwareUpdateRequired
    }

    /**
     Device identification:

     Required service: FEBE
     Forbidden service: FDD2
     Manufacturer advertisement data must start with [0x01, 0x16]
     */
    private struct Identification: DeviceIdentification {

        // To be an UpgradeableBoseDevice, it must provide the BMAP service...
        let requiredAdvertisedServiceUUIDs: Set<CBUUID> = Set(["FEBE".asUUID])

        // ...and it must not provide the Bose Wearable service.
        let forbiddenAdvertisedServiceUUIDs: Set<CBUUID> = Set([
            WearableSensorService.identification.identifier.asUUID
        ])

        let requiredServices: [ServiceIdentification] = []

        func advertisementFilter(peripheral: CBPeripheral, advertisementData: [String: Any]) -> Bool {
            guard
                let manufData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
                let version: UInt8 = manufData.integer(.bigEndian, at: 0),
                let productID: UInt8 = manufData.integer(.bigEndian, at: 1)
            else {
                return false
            }
            // To be an UpgradeableBoseDevice, it must have a version of 0x01 and a product ID of 0x16.
            return version == 0x01 && productID == 0x16
        }
    }

    static var identification: DeviceIdentification = Identification()
}
