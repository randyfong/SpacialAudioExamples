//
//  SensorType.swift
//  BoseWearable
//
//  Created by Paul Calnan on 9/25/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

/// Identifies a sensor in a wearable device.
public enum SensorType: UInt8 {

    /// An accelerometer sensor.
    case accelerometer = 0

    /// A gyroscope sensor.
    case gyroscope = 1

    /// A rotation sensor.
    case rotation = 2

    /// A game rotation sensor.
    case gameRotation = 3

    /// An orientation sensor.
    case orientation = 4

    /// A magnetometer sensor.
    case magnetometer = 5

    /// An uncalibrated magnetometer sensor.
    case uncalibratedMagnetometer = 6

    /// The set of sensors supported by the SDK. See `WearableDeviceInformation.availableSensors` and `SensorInformation.availableSensors` for the set of sensors supported by a given wearable device.
    public static var all: [SensorType] = [
        .accelerometer,
        .gyroscope,
        .rotation,
        .gameRotation,
        .orientation,
        .magnetometer,
        .uncalibratedMagnetometer
    ]

    /// Bit mask representation of this sensor type.
    private var mask: UInt32 {
        return 1 << rawValue
    }

    /// Converts the specified bit mask to a set of sensor types.
    static func set(fromBitmask mask: UInt32?) -> Set<SensorType>? {
        guard let mask = mask else {
            return nil
        }
        return Set(all.filter { mask & $0.mask != 0 })
    }
}

extension SensorType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .accelerometer:
            return NSLocalizedString("SensorType.accelerometer", bundle: BoseWearable.bundle, comment: "")
        case .gyroscope:
            return NSLocalizedString("SensorType.gyroscope", bundle: BoseWearable.bundle, comment: "")
        case .rotation:
            return NSLocalizedString("SensorType.rotation", bundle: BoseWearable.bundle, comment: "")
        case .gameRotation:
            return NSLocalizedString("SensorType.gameRotation", bundle: BoseWearable.bundle, comment: "")
        case .orientation:
            return NSLocalizedString("SensorType.orientation", bundle: BoseWearable.bundle, comment: "")
        case .magnetometer:
            return NSLocalizedString("SensorType.magnetometer", bundle: BoseWearable.bundle, comment: "")
        case .uncalibratedMagnetometer:
            return NSLocalizedString("SensorType.uncalibratedMagnetometer", bundle: BoseWearable.bundle, comment: "")
        }
    }
}
