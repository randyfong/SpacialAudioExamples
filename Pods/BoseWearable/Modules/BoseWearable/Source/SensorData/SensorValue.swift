//
//  SensorValue.swift
//  BoseWearable
//
//  Created by Paul Calnan on 10/10/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation
import Logging

/// An individual sensor reading received from a wearable device.
public struct SensorValue {

    /// The sensor that generated this reading.
    public var sensor: SensorType

    /// The wearable device's timestamp indicating when this reading was generated.
    public var timestamp: SensorTimestamp

    /// The actual IMU sample for this reading.
    public var sample: SensorSample

    /// Creates a new sensor value.
    public init(sensor: SensorType, timestamp: SensorTimestamp, sample: SensorSample) {
        self.sensor = sensor
        self.timestamp = timestamp
        self.sample = sample
    }

    /// Parses an array of `SensorValue` values from the specified payload using the specified metadata to determine payload lengths and scaling.
    static func parse(payload: Data, metadata: SensorMetadata) -> [SensorValue] {
        // three bytes for the header: sensor ID, timestamp
        let headerLength = 3

        var offset = 0
        var result: [SensorValue] = []

        while offset < payload.count {
            // Parse an individual sensor value

            // We need to be able to get the sensor ID, the length of this sample, and a slice of the payload of the appropriate length.
            // If we can't do any of this, we are done parsing this payload.
            guard
                // read the sensor ID and timestamp
                let sensorId: UInt8 = payload.integer(.bigEndian, at: offset),
                let timestamp: SensorTimestamp = payload.integer(.bigEndian, at: offset + 1),
                // use the metadata to get the length of the value data
                let valueLength = metadata.sampleLength(forSensorId: sensorId),
                // slice the value data starting at offset + headerLength
                // and using valueLength
                let valueData = payload.subdata(at: offset + headerLength, length: Int(valueLength))
            else {
                Log.sensorData.error("Unable to get sensor value buffer at offset \(offset) in payload \(payload.hexString)")
                break
            }

            // Try parsing the value. If this fails, it's because of either malformed data or an unknown sensor. In this case, we'll skip past the data and continue along.
            if let value = parseValue(sensorId: sensorId, timestamp: timestamp, payload: valueData, metadata: metadata) {
                result.append(value)
            }
            else {
                Log.sensorData.error("Unable to parse sensor value \(valueData.hexString)")
            }

            offset += (Int(valueLength) + headerLength)
        }

        return result
    }

    /**
     Parses an individual `SensorValue` from the specified payload. The sensor ID and timestamp are parsed and provided by the caller.
     */
    private static func parseValue(sensorId: UInt8, timestamp: SensorTimestamp, payload: Data, metadata: SensorMetadata) -> SensorValue? {
        guard
            let sensor = SensorType(rawValue: sensorId),
            let sample = SensorSample.parse(sensor: sensor, payload: payload, scale: metadata.scaleFunction(for: sensor))
        else {
            return nil
        }

        return SensorValue(sensor: sensor, timestamp: timestamp, sample: sample)
    }
}

extension SensorValue: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "SensorValue: (sensor=\(sensor) timestamp=\(timestamp) sample=\(sample.debugDescription))"
    }
}
