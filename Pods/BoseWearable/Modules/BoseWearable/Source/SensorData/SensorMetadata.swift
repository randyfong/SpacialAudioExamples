//
//  SensorMetadata.swift
//  BoseWearable
//
//  Created by Paul Calnan on 10/15/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

/// Internal protocol providing a mechanism for the `SensorData` parser to determine the length of the data payload for a particular sensor ID as well as the scale factor for converting from integral to floating-point values. This is defined as a protocol to allow for easier unit testing of the parser.
protocol SensorMetadata {

    /// Returns the number of bytes in the data payload for the specified sensor ID, or `nil` if the sensor ID is unknown.
    func sampleLength(forSensorId sensorId: UInt8) -> UInt8?

    /// Returns the scale function for the specified sensor type.
    func scaleFunction(for sensor: SensorType) -> ScaleFunction
}
