//
//  GestureConfiguration.swift
//  BoseWearable
//
//  Created by Paul Calnan on 10/23/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

/// Internal protocol representing the common interface across the various configuration payload types.
protocol GestureConfigurationEntry: CustomDebugStringConvertible {

    /// The byte-buffer representation of the entry.
    var data: Data { get }
}

/**
 The gesture configuration indicates which gestures are enabled and which are disabled. The wearable device will send gesture configuration values as its configuration changes. Client applications can configure the wearable device by changing the gesture configuration.

 At startup all gesture detection is inactive. Clients will need to enable the desired gestures. Upon BLE disconnection all gestures enabled by a client are automatically disabled.
 */
public struct GestureConfiguration {

    /// Payload indicating whether a particular gesture is enabled.
    struct IsEnabledEntry: GestureConfigurationEntry {

        /// The gesture.
        var gesture: GestureType

        /// Indicates whether this gesture is enabled.
        var isEnabled: Bool

        /// Creates a new entry with the specified values.
        init(gesture: GestureType, isEnabled: Bool) {
            self.gesture = gesture
            self.isEnabled = isEnabled
        }

        /// Parses an entry from the payload. Returns `nil` if the payload cannot be parsed.
        init?(gesture: GestureType, payload data: Data) {
            guard let contents: UInt8 = data.integer(.bigEndian, at: 0) else {
                return nil
            }

            let isEnabled = contents & 0x01 == 0x01
            self.init(gesture: gesture, isEnabled: isEnabled)
        }

        var data: Data {
            let payload: UInt8 = isEnabled ? 0x01 : 0x00
            return Data.data(.bigEndian, for: gesture.rawValue) + Data.data(.bigEndian, for: payload)
        }

        var debugDescription: String {
            return "(\(gesture): isEnabled=\(isEnabled))"
        }
    }

    /// Variable-length payload for gestures not currently supported by the SDK.
    struct UnknownEntry: GestureConfigurationEntry {

        /// The gesture ID.
        let gestureId: UInt8

        /// The payload. We keep this here as we need to write it back verbatim when changing the gesture configuration.
        let payload: Data

        /// Creates a new entry with the specified values.
        init(gestureId: UInt8, payload: Data) {
            self.gestureId = gestureId
            self.payload = payload
        }

        var data: Data {
            return Data.data(.bigEndian, for: gestureId) + payload
        }

        var debugDescription: String {
            return "(UnknownGestureConfiguration: \(data.hexString))"
        }
    }

    /// The configuration entries.
    var entries: [GestureConfigurationEntry]

    /// Creates a new `GestureConfiguration` object with the specified entries.
    init(entries: [GestureConfigurationEntry]) {
        self.entries = entries
    }

    /// Parses a `GestureConfiguration` object from the specified payload, using the specified metadata to determine entry payload sizes.
    init?(payload: Data?, metadata: GestureMetadata) {
        guard let payload = payload else {
            return nil
        }

        // one byte for the header: gesture ID
        let headerLength = 1
        var offset = 0
        var entries: [GestureConfigurationEntry] = []

        while offset < payload.count {
            // Parse an individual gesture configuration value

            // We need to be able to get the gesture ID, the length of the gesture's configuration, and a slice of the payload of the appropriate length.
            // If we can't do any of this, we are done parsing this payload.
            guard
                // read the gesture ID
                let gestureId: UInt8 = payload.integer(.bigEndian, at: offset),
                // use the metadata to get the length of the configuration data
                let configLength = metadata.configurationPayloadLength(forGestureId: gestureId),
                // slice the configuration data starting at offset + headerLength
                // and using the configLength
                let configData = payload.subdata(at: offset + headerLength, length: Int(configLength))
            else {
                break
            }

            // We only know about gestures contained in the GestureType enum, and they all require a IsEnabledEntry config type.
            // Thus, if gesture ID is valid, create and append an IsEnabledEntry.
            if let gesture = GestureType(rawValue: gestureId), let entry = IsEnabledEntry(gesture: gesture, payload: configData) {
                entries.append(entry)
            }
            // Otherwise, it's an unknown entry.
            else {
                entries.append(UnknownEntry(gestureId: gestureId, payload: configData))
            }

            offset += (Int(configLength) + headerLength)
        }

        self.init(entries: entries)
    }

    /// A byte-buffer representation of this object. Suitable for writing to the remote device when changing configuration.
    var data: Data {
        let entries = self.entries.map { $0.data }
        return entries.reduce(Data(), { $0 + $1 })
    }
}

extension GestureConfiguration {

    /// Returns the entry for the specified gesture type. Note that we only support IsEnabledEntry objects at this time.
    private func configuration(for gestureType: GestureType) -> IsEnabledEntry? {
        return entries.compactMap {
            $0 as? IsEnabledEntry
        }
        .filter {
            $0.gesture == gestureType
        }
        .first
    }

    /// Enables all gestures.
    public mutating func enableAll() {
        entries = entries.map { entry -> GestureConfigurationEntry in
            guard var updated = entry as? IsEnabledEntry else {
                return entry
            }

            updated.isEnabled = true
            return updated
        }
    }

    /// Disables all gestures.
    public mutating func disableAll() {
        entries = entries.map { entry -> GestureConfigurationEntry in
            guard var updated = entry as? IsEnabledEntry else {
                return entry
            }

            updated.isEnabled = false
            return updated
        }
    }

    /// Returns `true` if the specified gesture is enabled. Returns `false` otherwise.
    public func isEnabled(gesture: GestureType) -> Bool {
        return configuration(for: gesture)?.isEnabled ?? false
    }

    /// Enables or disables the specified gesture.
    public mutating func set(gesture: GestureType, enabled: Bool) {
        entries = entries.map { entry -> GestureConfigurationEntry in
            guard var updated = entry as? IsEnabledEntry, updated.gesture == gesture else {
                return entry
            }

            updated.isEnabled = enabled
            return updated
        }
    }
}

extension GestureConfiguration: CustomDebugStringConvertible {
    public var debugDescription: String {
        let entries = self.entries.map({ $0.debugDescription }).joined(separator: ", ")
        return "GestureConfiguration: [\(entries)]"
    }
}
