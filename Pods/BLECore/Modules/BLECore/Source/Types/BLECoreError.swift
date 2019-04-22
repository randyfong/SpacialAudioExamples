//
//  BLECoreError.swift
//  BLECore
//
//  Created by Paul Calnan on 8/29/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import CoreBluetooth
import Foundation

/// Indicates an error that occurred in the `BLECore` library.
public enum BLECoreError: Error {

    /// A new scan cannot be started because one is already in progress.
    case scanAlreadyInProgress

    /// Raised to indicate that a service with the specified UUID cannot be found.
    case missingService(CBUUID)

    /// Raised to indicate that a `Service` object cannot be converted to the requested type that implements `Service`.
    case incorrectServiceType

    /// Raised to indicate that a session failed to open because a matching device type could not be found.
    case noMatchingDeviceTypesFound
}

extension BLECoreError: LocalizedError {

    /// Provides a localized error message.
    public var errorDescription: String? {
        switch self {
        case .scanAlreadyInProgress:
            return NSLocalizedString("BLECoreError.scanAlreadyInProgress", bundle: BLECore.bundle, comment: "")

        case .missingService(let uuid):
            return String(format: NSLocalizedString("BLECoreError.missingService", bundle: BLECore.bundle, comment: ""), uuid)

        case .incorrectServiceType:
            return NSLocalizedString("BLECoreError.incorrectServiceType", bundle: BLECore.bundle, comment: "")

        case .noMatchingDeviceTypesFound:
            return NSLocalizedString("BLECoreError.noMatchingDeviceTypesFound", bundle: BLECore.bundle, comment: "")
        }
    }
}
