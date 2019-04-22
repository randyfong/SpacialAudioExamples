//
//  WearableDeviceInformation.swift
//  BoseWearable
//
//  Created by Paul Calnan on 9/25/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

/// The wearable device information provides details about the capabilities available in a particular wearable device.
public struct WearableDeviceInformation {

    /// Indicates the major version of the wearable sensors specification supported by this product.
    public var majorVersion: UInt8

    /// Indicates the minor version of the wearable sensors specification supported by this product.
    public var minorVersion: UInt8

    /// Indicates the product.
    public var productID: UInt16

    /// Indicates the product variant.
    public var variant: UInt8

    /// Indicates which sensors are available in this product.
    public var availableSensors: Set<SensorType>

    /// Indicates which gestures are available in this product.
    public var availableGestures: Set<GestureType>

    /**
     Indicates how often samples are transmitted from the product over the air. This period is indicated in milliseconds.

     A special value of zero indicates that the samples are sent as soon as they are available.

     Multiple samples can be sent within a single transmission period. Together with the _maximum payload per transmission period_, this field allows the client to determine if a particular sensor configuration can meet the desired data throughput.
     */
    public var transmissionPeriod: UInt8

    /**
     Indicates the maximum payload size of all combined active sensors that can be sent every transmission period.

     Together with the _transmission period_, this field allows the client to determine if a particular sensor configuration can meet the desired data throughput.
     */
    public var maximumPayloadPerTransmissionPeriod: UInt16

    /// Indicates the maximum number of sensors that can be active simultaneously.
    public var maximumActiveSensors: UInt8

    /// Provides status information about the wearable device.
    public var deviceStatus: DeviceStatus

    /// Creates a new wearable device information value with the specified values.
    init(majorVersion: UInt8,
         minorVersion: UInt8,
         productID: UInt16,
         variant: UInt8,
         availableSensors: Set<SensorType>,
         availableGestures: Set<GestureType>,
         transmissionPeriod: UInt8,
         maximumPayloadPerTransmissionPeriod: UInt16,
         maximumActiveSensors: UInt8,
         deviceStatus: DeviceStatus) {

        self.majorVersion = majorVersion
        self.minorVersion = minorVersion
        self.productID = productID
        self.variant = variant
        self.availableSensors = availableSensors
        self.availableGestures = availableGestures
        self.transmissionPeriod = transmissionPeriod
        self.maximumPayloadPerTransmissionPeriod = maximumPayloadPerTransmissionPeriod
        self.maximumActiveSensors = maximumActiveSensors
        self.deviceStatus = deviceStatus
    }

    /// Parses a wearable device information value from the specified payload. Returns `nil` if the payload is `nil` or if the payload cannot be parsed.
    init?(payload data: Data?) {
        guard
            let majorVersion: UInt8 = data?.integer(.bigEndian, at: 0),
            let minorVersion: UInt8 = data?.integer(.bigEndian, at: 1),
            let productID: UInt16 = data?.integer(.bigEndian, at: 2),
            let variant: UInt8 = data?.integer(.bigEndian, at: 4),
            let availableSensors = SensorType.set(fromBitmask: data?.integer(.bigEndian, at: 5)),
            let availableGestures = GestureType.set(fromBitmask: data?.integer(.bigEndian, at: 9)),
            let transmissionPeriod: UInt8 = data?.integer(.bigEndian, at: 13),
            let maximumPayloadPerTransmissionPeriod: UInt16 = data?.integer(.bigEndian, at: 14),
            let maximumActiveSensors: UInt8 = data?.integer(.bigEndian, at: 16),
            let deviceStatusMask: UInt16 = data?.integer(.bigEndian, at: 17)
        else {
            return nil
        }

        let deviceStatus = DeviceStatus(rawValue: deviceStatusMask)

        self.init(majorVersion: majorVersion,
                  minorVersion: minorVersion,
                  productID: productID,
                  variant: variant,
                  availableSensors: availableSensors,
                  availableGestures: availableGestures,
                  transmissionPeriod: transmissionPeriod,
                  maximumPayloadPerTransmissionPeriod: maximumPayloadPerTransmissionPeriod,
                  maximumActiveSensors: maximumActiveSensors,
                  deviceStatus: deviceStatus)
    }
}
