//
//  ServiceIdentification.swift
//  BLECore
//
//  Created by Paul Calnan on 8/28/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

/// Identifies a `Service` that is provided by a `Device`.
public protocol ServiceIdentification {

    /// The UUID that identifies this service.
    var identifier: CBUUIDConvertible { get }

    /// A sequence of UUIDs that identify characteristics that are required for instances of this service.
    var requiredCharacteristics: [CBUUIDConvertible] { get }

    /// A sequence of UUIDs that identify characteristics that are optional for instances of this service.
    var optionalCharacteristics: [CBUUIDConvertible] { get }
}
