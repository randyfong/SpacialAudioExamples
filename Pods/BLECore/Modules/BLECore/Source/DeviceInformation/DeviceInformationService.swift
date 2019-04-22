//
//  DeviceInformationService.swift
//  BLECore
//
//  Created by Paul Calnan on 8/16/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import CoreBluetooth
import Foundation
import Logging

/// The Device Information Service exposes manufacturer and/or vendor information about a device.
public class DeviceInformationService: Service {

    /// Service identification
    private struct Identification: ServiceIdentification {

        /// The UUID for the Device Information Service
        let identifier: CBUUIDConvertible = "180A"

        /// The required characteristics for the Device Information Service.
        let requiredCharacteristics: [CBUUIDConvertible] = [
            Characteristic.systemID,
            Characteristic.modelNumberString,
            Characteristic.serialNumberString,
            Characteristic.firmwareRevisionString,
            Characteristic.hardwareRevisionString,
            Characteristic.softwareRevisionString,
            Characteristic.manufacturerNameString,
            Characteristic.pnpID
        ]

        /// The optional characteristics for the Device Information Service.
        let optionalCharacteristics: [CBUUIDConvertible] = [
            Characteristic.regulatoryCertificationDataList
        ]
    }

    /// Service identification for the Device Information Service.
    public static let identification: ServiceIdentification = Identification()

    /// Characteristics and associated UUIDs for the Device Information Service.
    private enum Characteristic: String, CBUUIDConvertible {

        /// System ID characteristic
        case systemID = "2A23"

        /// Model number characteristic
        case modelNumberString = "2A24"

        /// Model number characteristic
        case serialNumberString = "2A25"

        /// Firmware revision characteristic
        case firmwareRevisionString = "2A26"

        /// Hardware revision characteristic
        case hardwareRevisionString = "2A27"

        /// Software revision characteristic
        case softwareRevisionString = "2A28"

        /// Manufacturer name characteristic
        case manufacturerNameString = "2A29"

        /// Regulatory certification data list characteristic
        case regulatoryCertificationDataList = "2A2A"

        /// PnP ID characteristic
        case pnpID = "2A50"

        /// Converts the enum value to a `CBUUID`
        var asUUID: CBUUID {
            return rawValue.asUUID
        }

        /// All of the supported characteristics
        static var all: [Characteristic] = [
            .systemID,
            .modelNumberString,
            .serialNumberString,
            .firmwareRevisionString,
            .hardwareRevisionString,
            .softwareRevisionString,
            .manufacturerNameString,
            .regulatoryCertificationDataList,
            .pnpID
        ]
    }

    /// The underlying service object.
    public let service: CBService

    /// This delegate gets notified whenever the device information is updated.
    public weak var delegate: DeviceInformationServiceDelegate?

    /// Creates a new Device Information Service instance backed by the specified `CBService` object.
    public required init(service: CBService) {
        self.service = service
    }

    /**
     Notifies this service that one of its characteristics was updated. When this function is called, the delegate is notified that the device information was updated. A `DeviceInformation` object is passed to the delegate. This object may not be complete, as not all characteristic values may have been received.

     Note that this will be called once per characteristic. As a result, the delegate will be notified several times; once for each characteristic when that characteristic's value is received.
     */
    public func didUpdateValue(forCharacteristic uuid: CBUUID, error: Error?) {
        Log.device.debug("Device information service did update characteristic \(uuid)")
        delegate?.deviceInformationService(self, didUpdateDeviceInformation: deviceInformation)
    }

    /// Read the values for all of the characteristics.
    public func refresh() {
        for c in Characteristic.all {
            readValue(for: c)
        }
    }

    /// Utility function to allow retrieval of values based on  `DeviceInformationService.Characteristic` instead of on `CBUUIDConvertible`.
    private func value(for characteristic: Characteristic) -> Data? {
        return value(for: characteristic as CBUUIDConvertible)
    }

    /// The value for the system ID characteristic.
    private var systemID: Data? {
        return value(for: .systemID)
    }

    /// The value for the model number characteristic.
    private var modelNumber: String? {
        return string(from: value(for: .modelNumberString))
    }

    /// The value for the serial number characteristic.
    private var serialNumber: String? {
        return string(from: value(for: .serialNumberString))
    }

    /// The value for the firmware revision characteristic.
    private var firmwareRevision: String? {
        return string(from: value(for: .firmwareRevisionString))
    }

    /// The value for the hardware revision characteristic.
    private var hardwareRevision: String? {
        return string(from: value(for: .hardwareRevisionString))
    }

    /// The value for the software revision characteristic.
    private var softwareRevision: String? {
        return string(from: value(for: .softwareRevisionString))
    }

    /// The value for the manufacturer name characteristic.
    private var manufacturerName: String? {
        return string(from: value(for: .manufacturerNameString))
    }

    /// The value for the regulatory certification data list characteristic.
    private var regulatoryCertificationDataList: Data? {
        return value(for: .regulatoryCertificationDataList)
    }

    /// The value for the PnP ID characteristic.
    private var pnpID: Data? {
        return value(for: .pnpID)
    }

    /// Creates a new `DeviceInformation` object based on the current characteristic values.
    private var deviceInformation: DeviceInformation {
        return DeviceInformation(
            systemID: systemID,
            modelNumber: modelNumber,
            serialNumber: serialNumber,
            firmwareRevision: firmwareRevision,
            hardwareRevision: hardwareRevision,
            softwareRevision: softwareRevision,
            manufacturerName: manufacturerName,
            regulatoryCertificationDataList: regulatoryCertificationDataList,
            pnpID: pnpID
        )
    }
}
