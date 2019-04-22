//
//  SensorData.swift
//  BoseWearable
//
//  Created by Paul Calnan on 10/10/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation
import Logging

/// Represents a collection of sensor values received in a single update from the remote wearable device.
public struct SensorData {

    /// The sensor values that were contained in this update.
    public var values: [SensorValue]

    /// Creates a new `SensorData` value with the specified sensor value array.
    init(values: [SensorValue]) {
        self.values = values
    }

    /// Convenience initializer to create a new `SensorData` value with the specified single sensor value.
    init(value: SensorValue) {
        self.values = [value]
    }

    /// Parses a `SensorData` value from the specified payload using the specified metadata.
    init?(payload: Data?, metadata: SensorMetadata) {
        guard let payload = payload else {
            return nil
        }

        self.init(values: SensorValue.parse(payload: payload, metadata: metadata))
    }
}

extension SensorData: CustomDebugStringConvertible {
    public var debugDescription: String {
        let values = self.values.map({ $0.debugDescription }).joined(separator: ", ")
        return "SensorData: [\(values)]"
    }
}
