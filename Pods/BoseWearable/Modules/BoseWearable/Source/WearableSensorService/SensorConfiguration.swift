//
//  SensorConfiguration.swift
//  BoseWearable
//
//  Created by Paul Calnan on 9/29/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

/**
 The sensor configuration indicates which sensors are enabled, which are disabled, and what the current sample period is. The wearable device will send sensor configuration values as its configuration changes. Client applications can configure the wearable device by changing the sensor configuration.

 At startup all available sensors are disabled. Clients will need to enable the desired sensors at the desired sample period. Upon BLE disconnection all sensors enabled by the client are automatically disabled.
 */
public struct SensorConfiguration {

    /// Payload indicating the configuration of a particular sensor.
    struct Entry: CustomDebugStringConvertible {

        /// The sensor.
        var sensor: SensorType

        /// The sample period in milliseconds.
        private var samplePeriodMS: UInt16

        /// Creates a new entry with the specified values.
        init(sensor: SensorType, samplePeriod: UInt16) {
            self.sensor = sensor
            self.samplePeriodMS = samplePeriod
        }

        /// Parses an entry from the specified payload. Returns `nil` if the payload is `nil` or if the payload cannot be parsed.
        init?(payload data: Data?) {
            guard
                let sensorId: UInt8 = data?.integer(.bigEndian, at: 0),
                let sensor = SensorType(rawValue: sensorId),
                let samplePeriod: UInt16 = data?.integer(.bigEndian, at: 1)
            else {
                return nil
            }

            self.init(sensor: sensor,
                      samplePeriod: samplePeriod)
        }

        /// A byte-buffer representation of this entry.
        var data: Data {
            return Data.data(.bigEndian, for: sensor.rawValue) + Data.data(.bigEndian, for: samplePeriodMS)
        }

        /// Indicates whether this sensor is enabled. A sensor is enabled if its sample period is not 0.
        var isEnabled: Bool {
            return samplePeriodMS != 0
        }

        /// The sample period for this sensor. Note that the sample period is expressed in the characteristic in milliseconds. This converts from milliseconds to an enum value.
        var samplePeriod: SamplePeriod? {
            get {
                return SamplePeriod.from(milliseconds: samplePeriodMS)
            }

            set {
                samplePeriodMS = newValue?.milliseconds ?? 0
            }
        }

        var debugDescription: String {
            return "(\(sensor): \(samplePeriodMS.description))"
        }
    }

    /// The configuration entries.
    var entries: [Entry]

    /// Creates a new `SensorConfiguration` object with the specified entries.
    init(entries: [Entry]) {
        self.entries = entries
    }

    /// Parses a `SensorConfiguration` object from the specified payload.
    init?(payload data: Data?) {
        guard let data = data else {
            return nil
        }

        var offset = 0
        let length = 3

        var entries = [Entry]()

        while offset + length <= data.count {
            let subdata = data.subdata(at: offset, length: length)

            // entry will be nil for unknown sensor IDs
            if let entry = Entry(payload: subdata) {
                entries.append(entry)
            }

            offset += length
        }

        self.init(entries: entries)
    }

    /// A byte-buffer representation of this object. Suitable for writing to the remote device when changing configuration.
    var data: Data {
        let entries = self.entries.map { $0.data }
        return entries.reduce(Data(), { $0 + $1 })
    }
}

extension SensorConfiguration {

    /// Returns the entry for the specified sensor type or `nil` if none can be found.
    private func configuration(for sensorType: SensorType) -> Entry? {
        return entries.filter {
            $0.sensor == sensorType
        }
        .first
    }

    /**
     Returns the sample period for enabled sensors, if any sensors are enabled. If no sensors are enabled, returns nil.

     Changing this value updates the sample period of all enabled sensors. If no sensors are enabled, changing this value has no effect. Changing this value to `nil` disables all enabled sensors.
     */
    public var enabledSensorsSamplePeriod: SamplePeriod? {
        get {
            return entries.compactMap({ $0.samplePeriod }).first
        }

        set {
            entries = entries.map { original -> Entry in
                if original.isEnabled {
                    var updated = original
                    updated.samplePeriod = newValue
                    return updated
                }
                else {
                    return original
                }
            }
        }
    }

    /// Returns `true` if the specified sensor is defined in this sensor configuration object and has a non-zero sample period. Returns `false` otherwise.
    public func isEnabled(sensor: SensorType) -> Bool {
        return configuration(for: sensor)?.isEnabled ?? false
    }

    /// Returns the sample period, in milliseconds, for the specified sensor. Returns 0 if the specified sensor is disabled or is not defined in this sensor configuration object.
    public func samplePeriod(for sensor: SensorType) -> SamplePeriod? {
        return configuration(for: sensor)?.samplePeriod
    }

    /// An array containing all of the sensors defined in this sensor configuration object.
    public var allSensors: [SensorType] {
        return entries.map { $0.sensor }
    }

    /// An array containing the currently enabled sensors.
    public var enabledSensors: [SensorType] {
        return entries.compactMap {
            $0.isEnabled ? $0.sensor : nil
        }
    }

    /// An array containing the currently disabled sensors.
    public var disabledSensors: [SensorType] {
        return entries.compactMap {
            $0.isEnabled ? nil : $0.sensor
        }
    }

    /// Disables all sensors.
    public mutating func disableAll() {
        enabledSensorsSamplePeriod = nil
    }

    /// Disables the specified sensor.
    public mutating func disable(sensor: SensorType) {
        entries = entries.map { original -> Entry in
            if original.sensor == sensor {
                var updated = original
                updated.samplePeriod = nil
                return updated
            }
            else {
                return original
            }
        }
    }

    /// Enables the specified sensor at the specified sample period. Note that all sensors must have the same sample period. Thus, if other sensors are enabled at a different sample period, this function changes _all_ enabled sensors to use the specified sample period.
    public mutating func enable(sensor: SensorType, at period: SamplePeriod) {
        entries = entries.map { original -> Entry in
            // Update this sensor as well as any other enabled sensors.
            if original.sensor == sensor || original.isEnabled {
                var updated = original
                updated.samplePeriod = period
                return updated
            }
            else {
                return original
            }
        }
    }
}

extension SensorConfiguration: CustomDebugStringConvertible {
    public var debugDescription: String {
        let entries = self.entries.map({ $0.debugDescription }).joined(separator: ", ")
        return "SensorConfiguration: [\(entries)]"
    }
}
