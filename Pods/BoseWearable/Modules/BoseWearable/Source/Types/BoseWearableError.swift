//
//  BoseWearableError.swift
//  BoseWearable
//
//  Created by Paul Calnan on 10/8/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import CoreBluetooth
import Foundation

/// Unified error type for the BoseWearable SDK.
public enum BoseWearableError: Error {

    /// Indicates an error code received from a wearable device.
    public enum ErrorCode: UInt8, Error, LocalizedError {

        /// The specified request is not the correct length.
        case invalidRequestLength = 128

        /// The requested sample period is not valid.
        case invalidSamplePeriod = 129

        /// The requested sensor configuration is not valid.
        case invalidSensorConfiguration = 130

        /// The requested configuration exceeds the maximum available throughput.
        case configExceedsMaxThroughput = 131

        /// The wearable sensor service is currently unavailable.
        case wearableSensorServiceUnavailable = 132

        /// The specified sensor is invalid.
        case invalidSensor = 133

        /// The operation timed out.
        case timeout = 134

        /// Attempts to convert a generic `Error` to an `ErrorCode`. This is used to decode an attribute error reported by the firmware in response to a GATT request.
        fileprivate static func from(_ error: Error) -> ErrorCode? {
            let nsError = error as NSError

            guard nsError.domain == CBATTErrorDomain, nsError.code <= UInt8.max else {
                return nil
            }

            return ErrorCode(rawValue: UInt8(nsError.code))
        }

        public var errorDescription: String? {
            switch self {
            case .invalidRequestLength:
                return NSLocalizedString("ErrorCode.invalidRequestLength", bundle: BoseWearable.bundle, comment: "")

            case .invalidSamplePeriod:
                return NSLocalizedString("ErrorCode.invalidSamplePeriod", bundle: BoseWearable.bundle, comment: "")

            case .invalidSensorConfiguration:
                return NSLocalizedString("ErrorCode.invalidSensorConfiguration", bundle: BoseWearable.bundle, comment: "")

            case .configExceedsMaxThroughput:
                return NSLocalizedString("ErrorCode.configExceedsMaxThroughput", bundle: BoseWearable.bundle, comment: "")

            case .wearableSensorServiceUnavailable:
                return NSLocalizedString("ErrorCode.wearableSensorServiceUnavailable", bundle: BoseWearable.bundle, comment: "")

            case .invalidSensor:
                return NSLocalizedString("ErrorCode.invalidSensor", bundle: BoseWearable.bundle, comment: "")

            case .timeout:
                return NSLocalizedString("ErrorCode.timeout", bundle: BoseWearable.bundle, comment: "")
            }
        }
    }

    /// Indicates an error response was received from a wearable device.
    case wearableDeviceError(code: ErrorCode, underlyingError: Error)

    /// Indicates an invalid response was received from a wearable device.
    case invalidResponse

    /// Indicates the device requires a firmware update to enable its usage.
    case firmwareUpdateRequired

    /// Indicates the device is not supported
    case unsupportedDevice

    /// Indicates that required gesture information has not yet been received from the device
    case missingGestureInformation

    /// Attempts to convert a generic `Error` value into a `BoseWearableError` value. If successful, returns the corresponding `BoseWearableError`. Otherwise, returns the original unmodified `error` argument.
    static func from(_ error: Error) -> Error {
        if let errorCode = ErrorCode.from(error) {
            return BoseWearableError.wearableDeviceError(code: errorCode, underlyingError: error)
        }
        return error
    }
}

extension BoseWearableError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .wearableDeviceError(let code, _):
            return String(format: NSLocalizedString("BoseWearableError.wearableDeviceError", bundle: BoseWearable.bundle, comment: ""), code.errorDescription ?? "(nil)")

        case .invalidResponse:
            return NSLocalizedString("BoseWearableError.invalidResponse", bundle: BoseWearable.bundle, comment: "")

        case .firmwareUpdateRequired:
            return NSLocalizedString("BoseWearableError.firmwareUpdateRequired", bundle: BoseWearable.bundle, comment: "")

        case .unsupportedDevice:
            return NSLocalizedString("BoseWearableError.unsupportedDevice", bundle: BoseWearable.bundle, comment: "")

        case .missingGestureInformation:
            return NSLocalizedString("BoseWearableError.missingGestureInformation", bundle: BoseWearable.bundle, comment: "")
        }
    }
}
