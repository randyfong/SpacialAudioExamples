//
//  VectorAccuracy.swift
//  BoseWearable
//
//  Created by Paul Calnan on 10/10/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

/// Indicates the accuracy of a given vector sample.
public enum VectorAccuracy: UInt8 {

    /// The sample is unreliable.
    case unreliable = 0

    /// The sample accuracy is low.
    case low = 1

    /// The sample accuracy is medium.
    case medium = 2

    /// The sample accuracy is high.
    case high = 3
}

extension VectorAccuracy: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unreliable:
            return NSLocalizedString("VectorAccuracy.unreliable", bundle: BoseWearable.bundle, comment: "")
        case .low:
            return NSLocalizedString("VectorAccuracy.low", bundle: BoseWearable.bundle, comment: "")
        case .medium:
            return NSLocalizedString("VectorAccuracy.medium", bundle: BoseWearable.bundle, comment: "")
        case .high:
            return NSLocalizedString("VectorAccuracy.high", bundle: BoseWearable.bundle, comment: "")
        }
    }
}
