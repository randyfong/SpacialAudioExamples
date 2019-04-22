//
//  SensorInformation.swift
//  BoseWearable
//
//  Created by Paul Calnan on 9/27/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation
import Logging

/// Provides detailed information about available sensors.
public struct SensorInformation {

    /// Payload indicating information about a particular sensor.
    struct Entry: CustomDebugStringConvertible {

        /// The identifier for this sensor. For forward compatibility, we can't use a SensorType here as we need to support sensors with IDs not yet contained in the enum.
        let sensorId: UInt8

        /// The scaled value range.
        let scaledValueRange: Range<Int16>

        /// The raw value range.
        let rawValueRange: Range<Int16>

        /// The set of available sample periods.
        let availableSamplePeriods: Set<SamplePeriod>

        /// The length of the payload for this sensor's samples.
        let sampleLength: UInt8

        /// Scale factor based on scaledValueRange and rawValueRange used in the scaling computation for this sensor.
        private let scaleFactor: Double

        /// Creates a new entry with the specified values.
        init(sensorId: UInt8,
             scaledValueRange: Range<Int16>,
             rawValueRange: Range<Int16>,
             availableSamplePeriods: Set<SamplePeriod>,
             sampleLength: UInt8) {

            self.sensorId = sensorId
            self.scaledValueRange = scaledValueRange
            self.rawValueRange = rawValueRange
            self.availableSamplePeriods = availableSamplePeriods
            self.sampleLength = sampleLength

            scaleFactor =
                (Double(scaledValueRange.upperBound) - Double(scaledValueRange.lowerBound)) /
                (Double(rawValueRange.upperBound) - Double(rawValueRange.lowerBound))
        }

        /// Parses an entry from the specified payload.
        init?(payload data: Data?) {
            guard
                let sensorId: UInt8 = data?.integer(.bigEndian, at: 0),
                let minScaled: Int16 = data?.integer(.bigEndian, at: 1),
                let maxScaled: Int16 = data?.integer(.bigEndian, at: 3),
                minScaled <= maxScaled,
                let minRaw: Int16 = data?.integer(.bigEndian, at: 5),
                let maxRaw: Int16 = data?.integer(.bigEndian, at: 7),
                minRaw <= maxRaw,
                let availableSamplePeriods = SamplePeriod.set(fromBitmask: data?.integer(.bigEndian, at: 9)),
                let sampleLength: UInt8 = data?.integer(.bigEndian, at: 11)
            else {
                return nil
            }

            let scaledValueRange = Range(uncheckedBounds: (lower: minScaled, upper: maxScaled))
            let rawValueRange = Range(uncheckedBounds: (lower: minRaw, upper: maxRaw))

            self.init(sensorId: sensorId,
                      scaledValueRange: scaledValueRange,
                      rawValueRange: rawValueRange,
                      availableSamplePeriods: availableSamplePeriods,
                      sampleLength: sampleLength)
        }

        /// Uses the ranges and scale factor to return a scale function.
        var scaleFunction: ScaleFunction {
            let minRaw = Double(rawValueRange.lowerBound)
            let minScaled = Double(scaledValueRange.lowerBound)
            let scaleFactor = self.scaleFactor

            return { value -> Double in
                return ((Double(value) - minRaw) * scaleFactor) + minScaled
            }
        }

        var debugDescription: String {
            let samplePeriods = availableSamplePeriods.map {
                $0.description
            }.joined(separator: ",")

            let sensor = SensorType(rawValue: sensorId)?.description ?? "UnknownSensor(\(sensorId))"
            let raw = rawValueRange.debugDescription
            let scaled = scaledValueRange.debugDescription

            return "\(sensor): (raw=\(raw) scaled=\(scaled) samplePeriods=(\(samplePeriods)) sampleLength=\(sampleLength))"
        }
    }

    /// The information entries.
    var entries: [Entry]

    /// Creates a new `SensorInformation` object with the specified entries.
    init(entries: [Entry]) {
        self.entries = entries
    }

    /// Parses a `SensorInformation` object from the specified payload.
    init?(payload data: Data?) {
        guard let data = data else {
            return nil
        }

        var offset = 0
        let length = 12

        var entries = [Entry]()

        while offset + length <= data.count {
            let subdata = data.subdata(at: offset, length: length)
            if let info = Entry(payload: subdata) {
                entries.append(info)
            }

            offset += length
        }

        self.init(entries: entries)
    }

    /// Returns the entry for the specified sensor ID, or `nil` if none can be found.
    private func information(forSensorId sensorId: UInt8) -> Entry? {
        return entries.filter {
            $0.sensorId == sensorId
        }
        .first
    }

    /// Returns the entry for the specified sensor type, or `nil` if none can be found.
    private func information(for sensor: SensorType) -> Entry? {
        return information(forSensorId: sensor.rawValue)
    }
}

extension SensorInformation: SensorMetadata {

    func sampleLength(forSensorId sensorId: UInt8) -> UInt8? {
        return information(forSensorId: sensorId)?.sampleLength
    }

    func scaleFunction(for sensor: SensorType) -> ScaleFunction {
        guard let info = information(for: sensor) else {
            Log.sensor.error("Could not find sensor information for \(sensor); will use unscaled values as a result")
            return IdentityScaling
        }

        return info.scaleFunction
    }
}

extension SensorInformation {

    /// An array of sensors that are available on this wearable device.
    public var availableSensors: [SensorType] {
        return entries.compactMap { SensorType(rawValue: $0.sensorId) }
    }

    /// The range of scaled values for the specified sensor. Used in conjunction with the `rawValueRange` to convert incoming sensor values from integral values to floating-point values.
    public func scaledValueRange(for sensor: SensorType) -> Range<Int16>? {
        return information(for: sensor)?.scaledValueRange
    }

    /// The range of raw values for the specified sensor. Used in conjunction with the `scaledValueRange` to convert incoming sensor values from integral values to floating-point values.
    public func rawValueRange(for sensor: SensorType) -> Range<Int16>? {
        return information(for: sensor)?.rawValueRange
    }

    /// Identifies which sample periods are available for use with the specified sensor.
    public func availableSamplePeriods(for sensor: SensorType) -> Set<SamplePeriod> {
        return information(for: sensor)?.availableSamplePeriods ?? []
    }

    /// Identifies which sample periods are available for use with all available sensors
    public var availableSamplePeriods: [SamplePeriod] {
        var periods = Set(SamplePeriod.all)

        for entry in entries {
            periods.formIntersection(entry.availableSamplePeriods)
        }

        return Array(periods).sorted(by: { $0.milliseconds > $1.milliseconds })
    }
}

extension SensorInformation: CustomDebugStringConvertible {
    public var debugDescription: String {
        let entries = self.entries.map({ $0.debugDescription }).joined(separator: ", ")
        return "SensorInformation: [\(entries)]"
    }
}
