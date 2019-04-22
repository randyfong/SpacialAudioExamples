//
//  DeviceInformation.swift
//  BLECore
//
//  Created by Paul Calnan on 8/15/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import CoreBluetooth
import Foundation

/// The device information provided by the device information service.
public struct DeviceInformation {

    /// A structure containing an Organizationally Unique Identifier (OUI) followed by a manufacturer-defined identifier and is unique for each individual instance of the product.
    public var systemID: Data?

    /// The model number that is assigned by the device vendor.
    public var modelNumber: String?

    /// The serial number for a particular instance of the device.
    public var serialNumber: String?

    /// The firmware revision for the firmware within the device.
    public var firmwareRevision: String?

    /// The hardware revision for the hardware within the device.
    public var hardwareRevision: String?

    /// The software revision for the software within the device.
    public var softwareRevision: String?

    /// The name of the manufacturer of the device.
    public var manufacturerName: String?

    /// Regulatory and certification information for the product in a list defined in IEEE 11073-20601.
    public var regulatoryCertificationDataList: Data?

    /// A set of values used to create a device ID value that is unique for this device.
    public var pnpID: Data?

    /// Creates a new `DeviceInformation` object with the specified values.
    public init(systemID: Data?,
                modelNumber: String?,
                serialNumber: String?,
                firmwareRevision: String?,
                hardwareRevision: String?,
                softwareRevision: String?,
                manufacturerName: String?,
                regulatoryCertificationDataList: Data?,
                pnpID: Data?) {

        self.systemID = systemID
        self.modelNumber = modelNumber
        self.serialNumber = serialNumber
        self.firmwareRevision = firmwareRevision
        self.hardwareRevision = hardwareRevision
        self.softwareRevision = softwareRevision
        self.manufacturerName = manufacturerName
        self.regulatoryCertificationDataList = regulatoryCertificationDataList
        self.pnpID = pnpID
    }
}
