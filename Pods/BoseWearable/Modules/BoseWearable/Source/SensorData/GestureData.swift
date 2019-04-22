//
//  GestureData.swift
//  BoseWearable
//
//  Created by Paul Calnan on 10/23/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

/// Represents a gesture event received from the remote wearable device.
public struct GestureData {

    /// The gesture that was detected.
    public var gesture: GestureType

    /// The wearable device's timestamp indicating when this gesture was detected.
    public var timestamp: SensorTimestamp

    /// Creates a new `GestureData` object with the specified values.
    init(gesture: GestureType, timestamp: SensorTimestamp) {
        self.gesture = gesture
        self.timestamp = timestamp
    }

    /// Parses a `GestureData` object from the specified payload. Returns `nil` if `data` is `nil` or if unable to parse any of the expected values.
    init?(payload data: Data?) {
        guard
            let id: UInt8 = data?.integer(.bigEndian, at: 0),
            let gesture = GestureType(rawValue: id),
            let timestamp: SensorTimestamp = data?.integer(.bigEndian, at: 1)
        else {
            return nil
        }

        self.init(gesture: gesture, timestamp: timestamp)
    }
}

extension GestureData: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "GestureData: (gesture=\(gesture.description), timestamp=\(timestamp))"
    }
}
