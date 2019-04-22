//
//  ServiceSet.swift
//  BLECore
//
//  Created by Paul Calnan on 8/28/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import CoreBluetooth
import Foundation
import Logging

/// A collection of `Service` instances associated with a `Device`.
public struct ServiceSet {

    /// The backing map from CBUUID to Service instance
    private var services: [CBUUID: Service]

    /// Creates a new `ServiceSet` with the specified mapping from `CBUUID` to `Service` instance.
    init(services: [CBUUID: Service]) {
        self.services = services
    }

    /**
     Returns the service instance with the specified type. Uses the UUID contained in `service.identification.identifier` to look up the service then conditionally casts it to the specified type.

     - parameter service: the type that implements `Service`
     - returns: an instance of the `service` type
     - throws: `BLECoreError.missingService` if no service can be found with the service's UUID
     - throws: `BLECoreError.incorrectServiceType` if a service can be found with the service's UUID but it cannot be converted to the specified type
     */
    public func service<T: Service>(for service: T.Type) throws -> T {
        let uuid = service.identification.identifier.asUUID

        guard let genericService = services[uuid] else {
            throw BLECoreError.missingService(uuid)
        }

        guard let typedService = genericService as? T else {
            throw BLECoreError.incorrectServiceType
        }

        return typedService
    }

    /**
     Returns the service instance with the specified UUID. Returns `nil` if one cannot be found.

     - parameter uuid: the UUID of the service to retrieve
     - returns: the service instance with the specified UUID, or `nil` of one cannot be found
     */
    func service(for uuid: CBUUID) -> Service? {
        guard let result = services[uuid] else {
            Log.service.error("Could not find service for uuid \(uuid)")
            return nil
        }

        return result
    }
}
