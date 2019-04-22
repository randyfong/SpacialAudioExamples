//
//  SamplePeriods.swift
//  BoseWearable
//
//  Created by Paul Calnan on 9/27/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

/// Indicates the sample period for a given sensor.
public enum SamplePeriod: UInt8 {

    /// Indicates that samples are sent every 320 ms (3.125 Hz)
    case _320ms = 0

    /// Indicates that samples are sent every 160 ms (6.25 Hz)
    case _160ms = 1

    /// Indicates that samples are sent every 80 ms (12.5 Hz)
    case _80ms = 2

    /// Indicates that samples are sent every 40 ms (25 Hz)
    case _40ms = 3

    /// Indicates that samples are sent every 20 ms (50 Hz)
    case _20ms = 4

    /// An array of all possible sample periods.
    public static let all: [SamplePeriod] = [
        ._320ms,
        ._160ms,
        ._80ms,
        ._40ms,
        ._20ms
    ]

    /// Bit mask representation of this sample period.
    private var mask: UInt16 {
        return 1 << rawValue
    }

    /// Converts the specified bit mask to a set of sample periods.
    static func set(fromBitmask mask: UInt16?) -> Set<SamplePeriod>? {
        guard let mask = mask else {
            return nil
        }
        return Set(all.filter { mask & $0.mask != 0 })
    }

    /// Converts the specified millisecond value to the corresponding sample period, or `nil` if no matching sample period can be found.
    static func from(milliseconds: UInt16) -> SamplePeriod? {
        return all.filter({ $0.milliseconds == milliseconds }).first
    }

    /// The sample period in milliseconds.
    public var milliseconds: UInt16 {
        switch self {
        case ._320ms: return 320
        case ._160ms: return 160
        case ._80ms: return 80
        case ._40ms: return 40
        case ._20ms: return 20
        }
    }
}

extension SamplePeriod: CustomStringConvertible {
    public var description: String {
        return String(format: NSLocalizedString("SamplePeriod.description", bundle: BoseWearable.bundle, comment: ""), milliseconds)
    }
}
