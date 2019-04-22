//
//  SensorDispatchHandler.swift
//  BoseWearable
//
//  Created by Paul Calnan on 10/11/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

/**
 This protocol defines functions that are called by a `SensorDispatch` to notify a client application that sensor data has been received. Note that default implementations of each of these functions are already provided. Thus, you need only implement the functions corresponding to the sensors you are interested in.
 */
public protocol SensorDispatchHandler: class {

    /**
     Indicates that aggregated sensor data has been received. This is useful if you need to tie together the various readings received in a single update.
     */
    func receivedSensorData(_ data: SensorData)

    /// Indicates that an accelerometer reading has been received.
    func receivedAccelerometer(vector: Vector, accuracy: VectorAccuracy, timestamp: SensorTimestamp)

    /// Indicates that a gyroscope reading has been received.
    func receivedGyroscope(vector: Vector, accuracy: VectorAccuracy, timestamp: SensorTimestamp)

    /// Indicates that a rotation reading has been received.
    func receivedRotation(quaternion: Quaternion, accuracy: QuaternionAccuracy, timestamp: SensorTimestamp)

    /// Indicates that a game rotation reading has been received.
    func receivedGameRotation(quaternion: Quaternion, timestamp: SensorTimestamp)

    /// Indicates that an orientation reading has been received.
    func receivedOrientation(vector: Vector, accuracy: VectorAccuracy, timestamp: SensorTimestamp)

    /// Indicates that a magnetometer reading has been received.
    func receivedMagnetometer(vector: Vector, accuracy: VectorAccuracy, timestamp: SensorTimestamp)

    /// Indicates that an uncalibrated magnetometer reading has been received.
    func receivedUncalibratedMagnetometer(vector: Vector, bias: Vector, timestamp: SensorTimestamp)

    /// Indicates that a gesture has been received.
    func receivedGesture(type: GestureType, timestamp: SensorTimestamp)
}

extension SensorDispatchHandler {

    /// A default, empty implementation is provided.
    public func receivedSensorData(_ data: SensorData) { }

    /// A default, empty implementation is provided.
    public func receivedAccelerometer(vector: Vector, accuracy: VectorAccuracy, timestamp: SensorTimestamp) { }

    /// A default, empty implementation is provided.
    public func receivedGyroscope(vector: Vector, accuracy: VectorAccuracy, timestamp: SensorTimestamp) { }

    /// A default, empty implementation is provided.
    public func receivedRotation(quaternion: Quaternion, accuracy: QuaternionAccuracy, timestamp: SensorTimestamp) { }

    /// A default, empty implementation is provided.
    public func receivedGameRotation(quaternion: Quaternion, timestamp: SensorTimestamp) { }

    /// A default, empty implementation is provided.
    public func receivedOrientation(vector: Vector, accuracy: VectorAccuracy, timestamp: SensorTimestamp) { }

    /// A default, empty implementation is provided.
    public func receivedMagnetometer(vector: Vector, accuracy: VectorAccuracy, timestamp: SensorTimestamp) { }

    /// A default, empty implementation is provided.
    public func receivedUncalibratedMagnetometer(vector: Vector, bias: Vector, timestamp: SensorTimestamp) { }

    /// A default, empty implementation is provided.
    public func receivedGesture(type: GestureType, timestamp: SensorTimestamp) { }
}
