//
//  CBUUIDConvertible.swift
//  BLECore
//
//  Created by Paul Calnan on 8/16/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import CoreBluetooth
import Foundation

/// Types adopting the `CBUUIDConvertible` protocol can be used to construct `CBUUID` objects.
public protocol CBUUIDConvertible {

    /// Returns a CBUUID constructed from this object.
    var asUUID: CBUUID { get }
}

/// Extend `CBUUID` to implement `CBUUIDConvertible`.
extension CBUUID: CBUUIDConvertible {

    /// Returns this `CBUUID` as a `CBUUID`.
    public var asUUID: CBUUID {
        return self
    }
}

/// Extend `String` to implement `CBUUIDConvertible`.
extension String: CBUUIDConvertible {

    /// Converts this string to a `CBUUID`.
    public var asUUID: CBUUID {
        return CBUUID(string: self)
    }
}

/// Extend `CBUUIDConvertible` to support equality comparisons between `CBUUIDConvertible` objects and `CBUUID` objects.
extension CBUUIDConvertible {

    /// Compares two `CBUUIDConvertible` objects.
    public static func == (lhs: CBUUIDConvertible, rhs: CBUUIDConvertible) -> Bool {
        return lhs.asUUID == rhs.asUUID
    }

    /// Compares a `CBUUIDConvertible` object and a `CBUUID` object.
    public static func == (lhs: CBUUIDConvertible, rhs: CBUUID) -> Bool {
        return lhs.asUUID == rhs
    }

    /// Compares a `CBUUID` object and a `CBUUIDConvertible` object.
    public static func == (lhs: CBUUID, rhs: CBUUIDConvertible) -> Bool {
        return lhs == rhs.asUUID
    }
}
