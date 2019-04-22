//
//  GestureInformation.swift
//  BoseWearable
//
//  Created by Paul Calnan on 11/1/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

/// Provides information about available gestures.
public struct GestureInformation {

    /// Payload indicating the information about a particular gesture.
    struct Entry: CustomDebugStringConvertible {

        /// The identifier for this gesture. For forward compatibility, we can't use a GestureType here as we need to support gestures with IDs not yet contained in the enum.
        let gestureId: UInt8

        /// The length of the gesture's configuration payload.
        let configurationPayloadLength: UInt8

        /// Creates a new entry with the specified values.
        init(gestureId: UInt8, configurationPayloadLength: UInt8) {
            self.gestureId = gestureId
            self.configurationPayloadLength = configurationPayloadLength
        }

        /// Parses an entry from the specified payload.
        init?(payload data: Data?) {
            guard
                let gestureId: UInt8 = data?.integer(.bigEndian, at: 0),
                let configurationPayloadLength: UInt8 = data?.integer(.bigEndian, at: 1)
            else {
                return nil
            }

            self.init(gestureId: gestureId, configurationPayloadLength: configurationPayloadLength)
        }

        var debugDescription: String {
            let gesture = GestureType(rawValue: gestureId)?.description ?? "UnknownGesture(\(gestureId))"
            return "\(gesture.description): configurationPayloadLength=\(configurationPayloadLength)"
        }
    }

    /// The information entries.
    var entries: [Entry]

    /// Creates a new `GestureInformation` object with the specified entries.
    init(entries: [Entry]) {
        self.entries = entries
    }

    /// Parses a `GestureInformation` object from the specified payload.
    init?(payload data: Data?) {
        guard let data = data else {
            return nil
        }

        var offset = 0
        let length = 2

        var entries = [Entry]()

        while offset + length < data.count {
            let subdata = data.subdata(at: offset, length: length)
            if let info = Entry(payload: subdata) {
                entries.append(info)
            }

            offset += length
        }

        self.init(entries: entries)
    }

    /// Returns the entry for the specified gesture type, or `nil` if none can be found.
    private func information(for gesture: GestureType) -> Entry? {
        return information(forGestureId: gesture.rawValue)
    }

    /// Returns the entry for the specified gesture ID, or `nil` if none can be found.
    private func information(forGestureId gestureId: UInt8) -> Entry? {
        return entries.filter {
            $0.gestureId == gestureId
        }
        .first
    }
}

extension GestureInformation: GestureMetadata {

    func configurationPayloadLength(forGestureId gestureId: UInt8) -> UInt8? {
        return information(forGestureId: gestureId)?.configurationPayloadLength
    }
}

extension GestureInformation {

    /// An array of gestures that are available on this wearable device.
    public var availableGestures: [GestureType] {
        return entries.compactMap { GestureType(rawValue: $0.gestureId) }
    }
}

extension GestureInformation: CustomDebugStringConvertible {
    public var debugDescription: String {
        let entries = self.entries.map({ $0.debugDescription }).joined(separator: ", ")
        return "GestureInformation: [\(entries)]"
    }
}
