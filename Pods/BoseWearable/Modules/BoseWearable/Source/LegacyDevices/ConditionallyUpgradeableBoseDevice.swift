//
//  ConditionallyUpgradeableBoseDevice.swift
//  BoseWearable
//
//  Created by Paul Calnan on 11/5/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import BLECore
import CoreBluetooth
import Foundation
import Logging

/**
 Represents a Bose device that possibly could support connections from the Bose Wearable SDK. The product ID provided in the advertisement data suggests that this device may be supported. However, we need to connect to the device and query the serial number provided by the Device Information Service. If the serial number indicates this product can be supported with a firmware upgrade, we raise an error indicating this. If the serial number indicates this product cannot be supported even with a firmware upgrade, we raise an error indicating it is an unsupported device.

 Note that this class must implement `WearableDevice` as it needs to have a RemoteWearableDeviceSession associated with it. We establish a connection, retrieve the serial number from the Device Information Service, and then we raise an error indicating whether this device could be supported with a firmware upgrade or that the device is unsupported. This is done via the `WearableDevice.receivedAllStartupInformation()` function.
 */
class ConditionallyUpgradeableBoseDevice: Device, WearableDevice {

    // MARK: - BLECore

    let peripheral: CBPeripheral

    let services: ServiceSet

    required init(peripheral: CBPeripheral, services: ServiceSet) throws {
        self.peripheral = peripheral
        self.services = services
        self.deviceInformationService = try services.service(for: DeviceInformationService.self)

        deviceInformationService.delegate = self
        deviceInformationService.refresh()
    }

    /**
     Device identification:

     Required service: FEBE
     Forbidden service: FDD2
     Manufacturer advertisement data must start with [0x01, 0x09]
     */
    private struct Identification: DeviceIdentification {

        // To be a ConditionallyUpgradeableBoseDevice, it must provide the BMAP service...
        let requiredAdvertisedServiceUUIDs: Set<CBUUID> = Set(["FEBE".asUUID])

        // ...and it must not provide the Bose Wearable Sensor service.
        let forbiddenAdvertisedServiceUUIDs: Set<CBUUID> = Set([
            WearableSensorService.identification.identifier.asUUID
        ])

        let requiredServices: [ServiceIdentification] = [
            DeviceInformationService.identification
        ]

        func advertisementFilter(peripheral: CBPeripheral, advertisementData: [String: Any]) -> Bool {
            guard
                let manufData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
                let version: UInt8 = manufData.integer(.bigEndian, at: 0),
                let productID: UInt8 = manufData.integer(.bigEndian, at: 1)
            else {
                return false
            }
            // To be a ConditionallyUpgradeableBoseDevice, it must have a version of 0x01 and a product ID of 0x09.
            return version == 0x01 && productID == 0x09
        }
    }

    static var identification: DeviceIdentification = Identification()

    // MARK: - Device Information

    /// The device information service is used to retrieve the serial number.
    private let deviceInformationService: DeviceInformationService

    private(set) var deviceInformation: DeviceInformation?

    func refreshDeviceInformation() {
        deviceInformationService.refresh()
    }

    // MARK: - Serial number validation

    func deviceIsReady() throws -> Bool {
        // If we haven't received the device information or serial number yet, keep waiting.
        guard let info = deviceInformation, let serial = info.serialNumber else {
            Log.device.info("Device information or serial number not yet available.")
            return false
        }

        // Check the serial number to see if it indicates the device is upgradeable to support the SDK.
        if isUpgradeable(serial) {
            Log.device.info("Device with serial number \(serial) is upgradeable")
            throw BoseWearableError.firmwareUpdateRequired
        }
        else {
            Log.device.info("Device with serial number \(serial) is not upgradeable")
            throw BoseWearableError.unsupportedDevice
        }
    }

    /// Returns `true` if the device's serial number indicates that it can be upgradeable.
    private func isUpgradeable(_ serialNumber: String) -> Bool {

        // A device with a serial number ending in AZ is upgradeable.
        return serialNumber.hasSuffix("AZ")
    }
}

// MARK: - DeviceInformationServiceDelegate

extension ConditionallyUpgradeableBoseDevice: DeviceInformationServiceDelegate {

    func deviceInformationService(_ sender: DeviceInformationService, didUpdateDeviceInformation value: DeviceInformation) {
        deviceInformation = value
        NotificationCenter.default.post(WearableDeviceEvent.didUpdateDeviceInformation(value), from: self)
    }
}

// MARK: - WearableDevice Stubs

extension ConditionallyUpgradeableBoseDevice {

    // The remaining properties and functions are required for WearableDevice conformance. However, they will never be usable as we will always raise an error during the connection process. So all properties are nil and the functions do nothing.

    /// :nodoc:
    var name: String? { return nil }

    /// :nodoc:
    var wearableDeviceInformation: WearableDeviceInformation? { return nil }

    /// :nodoc:
    func refreshWearableDeviceInformation() { }

    /// :nodoc:
    var sensorInformation: SensorInformation? { return nil }

    /// :nodoc:
    func refreshSensorInformation() { }

    /// :nodoc:
    var sensorConfiguration: SensorConfiguration? { return nil }

    /// :nodoc:
    func refreshSensorConfiguration() { }

    /// :nodoc:
    func changeSensorConfiguration(_ newConfiguration: SensorConfiguration) { }

    /// :nodoc:
    var gestureInformation: GestureInformation? { return nil }

    /// :nodoc:
    func refreshGestureInformation() { }

    /// :nodoc:
    var gestureConfiguration: GestureConfiguration? { return nil }

    /// :nodoc:
    func refreshGestureConfiguration() { }

    /// :nodoc:
    func changeGestureConfiguration(_ newConfiguration: GestureConfiguration) { }
}
