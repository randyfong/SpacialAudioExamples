//
//  QuaternionAccuracy.swift
//  BoseWearable
//
//  Created by Paul Calnan on 10/10/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

/// The accuracy of a quaternion sensor reading, in radians.
public struct QuaternionAccuracy {

    /// The estimated accuracy of a quaternion reading, in radians.
    public var estimatedAccuracy: Double

    /// Creates a new `QuaternionAccuracy` instance with the specified estimated accuracy.
    public init(estimatedAccuracy: Double) {
        self.estimatedAccuracy = estimatedAccuracy
    }
}
