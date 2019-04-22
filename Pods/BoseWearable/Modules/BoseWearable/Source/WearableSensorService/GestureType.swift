//
//  GestureType.swift
//  BoseWearable
//
//  Created by Paul Calnan on 9/26/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

/// Identifies a gesture recognized by a wearable device.
public enum GestureType: UInt8 {

    /// A single-tap gesture.
    case singleTap = 0x80

    /// A double-tap gesture.
    case doubleTap = 0x81

    /// Indicates a head nod (up and down)
    case headNod = 0x82

    /// Indicates a head shake (left to right)
    case headShake = 0x83

    /// The set of gestures supported by the SDK. See `WearableDeviceInformation.availableGestures` and `GestureInformation.availableGestures` for the set of gestures supported by a given wearable device.
    public static var all: [GestureType] = [
        .singleTap,
        .doubleTap,
        .headNod,
        .headShake
    ]

    /// Bit mask representation of this gesture type.
    private var mask: UInt32 {
        switch self {
        case .singleTap:
            return 1 << 0

        case .doubleTap:
            return 1 << 1

        case .headNod:
            return 1 << 2

        case .headShake:
            return 1 << 3
        }
    }

    /// Converts the specified bit mask to a set of gesture types.
    static func set(fromBitmask mask: UInt32?) -> Set<GestureType>? {
        guard let mask = mask else {
            return nil
        }
        return Set(all.filter { mask & $0.mask != 0 })
    }

    /// Converts the specified set of gesture types to a bit mask.
    static func bitmask(from set: Set<GestureType>) -> UInt32 {
        var mask: UInt32 = 0

        set.forEach {
            mask |= $0.mask
        }

        return mask
    }
}

extension GestureType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .singleTap:
            return NSLocalizedString("GestureType.singleTap", bundle: BoseWearable.bundle, comment: "")
        case .doubleTap:
            return NSLocalizedString("GestureType.doubleTap", bundle: BoseWearable.bundle, comment: "")
        case .headNod:
            return NSLocalizedString("GestureType.headNod", bundle: BoseWearable.bundle, comment: "")
        case .headShake:
            return NSLocalizedString("GestureType.headShake", bundle: BoseWearable.bundle, comment: "")
        }
    }
}
