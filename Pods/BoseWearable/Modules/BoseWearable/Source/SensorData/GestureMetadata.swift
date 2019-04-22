//
//  GestureMetadata.swift
//  BoseWearable
//
//  Created by Paul Calnan on 11/8/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

/// Internal protocol providing a mechanism for the `GestureConfiguration` parser to determine the length of the configuration payload for a particular gesture ID. This is defined as a protocol to allow for easier unit testing of the parser.
protocol GestureMetadata {

    /// Returns the number of bytes in the configuration payload for the specified gesture ID, or `nil` if the gesture ID is unknown.
    func configurationPayloadLength(forGestureId gestureId: UInt8) -> UInt8?
}
