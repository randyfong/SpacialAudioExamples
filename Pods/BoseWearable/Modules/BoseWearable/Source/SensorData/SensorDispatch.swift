//
//  SensorDispatch.swift
//  BoseWearable
//
//  Created by Paul Calnan on 10/12/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import BLECore
import Foundation
import Logging
import simd

/**
 A `SensorDispatch` object is used to receive sensor readings. A `SensorDispatch` object listens for the underlying `WearableDeviceEvent` notifications indicating that sensor data has been received. It then unpacks the individual values from the data and dispatches each to its appropriate callback block and to its handler (a `SensorDispatchHandler` object).

 An app can have arbitrarily many `SensorDispatch` objects. This allows multiple handlers inside an app all to listen to the same sensor. Each `SensorDispatch` automatically registers and deregisters for the appropriate `WearableDeviceEvent` notifications.

 A `SensorDispatch` object is created with an associated `OperationQueue`. Specifying the `.main` queue is suitable for when the app's user interface should be updated in response to the event. Otherwise, a background `OperationQueue` can be provided.

 When a `WearableDeviceEvent.didReceiveSensorData(SensorData)` notification is received, the `SensorDispatch` object does the following on the `OperationQueue` provided to the `SensorDispatch` initializer:

 - Dispatches the `SensorData` object to `sensorDataCallback` and to `SensorDispatchHandler.receivedSensorData(_:)`.
 - Each of the values in the `SensorData` object is dispatched to the appropriate handler:
    - Accelerometer values are dispatched to `accelerometerCallback` and to  `SensorDispatchHandler.receivedAccelerometer(vector:accuracy:timestamp:)`
    - Gyroscope values are dispatched to `gyroscopeCallback` and to  `SensorDispatchHandler.receivedGyroscope(vector:accuracy:timestamp:)`
    - Rotation values are dispatched to `rotationCallback` and to `SensorDispatchHandler.receivedRotation(quaternion:accuracy:timestamp:)`.
    - Game rotation values are dispatched to `gameRotationCallback` and to `SensorDispatchHandler.receivedGameRotation(quaternion:timestamp:)`.
    - Orientation values are dispatched to `orientationCallback` and to  `SensorDispatchHandler.receivedOrientation(vector:accuracy:timestamp:)`
    - Magnetometer values are dispatched to `magnetometerCallback` and to  `SensorDispatchHandler.receivedMagnetometer(vector:accuracy:timestamp:)`
    - Uncalibrated magnetometer values are dispatched to `uncalibratedMagnetometerCallback` and to  `SensorDispatchHandler.receivedUncalibratedMagnetometer(vector:bias:timestamp:)`

 Callbacks are only invoked if they are non-nil. Thus you need only provide callback blocks for sensors you are interested in. Similarly, the `SensorDispatchHandler` protocol provides default implementation of all of its handler functions. Thus you need only provide implementations for sensors you are interested in. A `SensorDispatchHandler` and callback blocks can co-exist. Each callback is invoked before the corresponding `SensorDispatchHandler` function.
 */
public class SensorDispatch {

    /// Notification token that represents the `WearableDeviceEvent` listener.
    private var token: NotificationToken?

    /// The sensor dispatch handler. This is invoked in response to any incoming sensor data.
    public weak var handler: SensorDispatchHandler?

    /// Creates a new `SensorDispatch` object that will dispatch incoming sensor data on the specified operation queue.
    public init(queue: OperationQueue) {
        token = NotificationCenter.default.addObserver(for: WearableDeviceEvent.self, queue: queue, using: { [weak self] event in
            self?.wearableDeviceEvent(event)
        })
    }

    /// Called whenever a `WearableDeviceEvent` is received.
    private func wearableDeviceEvent(_ event: WearableDeviceEvent) {
        switch event {
        case .didReceiveSensorData(let data):
            receivedSensorData(data)

        case .didReceiveGestureData(let data):
            receivedGestureData(data)

        default:
            break
        }
    }

    // MARK: - SensorData

    /// Called when sensor data is received. Iterates over the contained values and passes each sample to the appropriate dispatch function.
    private func receivedSensorData(_ data: SensorData) {
        dispatchSensorData(data)

        data.values.forEach { value in
            let timestamp = value.timestamp

            switch value.sample {
            case .accelerometer(let value, let accuracy):
                dispatchAccelerometer(vector: value, accuracy: accuracy, timestamp: timestamp)

            case .gyroscope(let value, let accuracy):
                dispatchGyroscope(vector: value, accuracy: accuracy, timestamp: timestamp)

            case .rotation(let value, let accuracy):
                dispatchRotation(quaternion: value, accuracy: accuracy, timestamp: timestamp)

            case .gameRotation(let value):
                dispatchGameRotation(quaternion: value, timestamp: timestamp)

            case .orientation(let value, let accuracy):
                dispatchOrientation(vector: value, accuracy: accuracy, timestamp: timestamp)

            case .magnetometer(let value, let accuracy):
                dispatchMagnetometer(vector: value, accuracy: accuracy, timestamp: timestamp)

            case .uncalibratedMagnetometer(let value, let bias):
                dispatchUncalibratedMagnetometer(vector: value, bias: bias, timestamp: timestamp)
            }
        }
    }

    /**
     Callback to receive aggregated sensor data. This is useful if you need to tie together the various readings received in a single update.
     */
    public var sensorDataCallback: ((SensorData) -> Void)?

    /// Dispatch sensor data to the callback and handler.
    private func dispatchSensorData(_ data: SensorData) {
        sensorDataCallback?(data)
        handler?.receivedSensorData(data)
    }

    // MARK: - GestureData

    /// Called when gesture data is received. Passes the value to the appropriate dispatch function.
    private func receivedGestureData(_ data: GestureData) {
        dispatchGestureData(type: data.gesture, timestamp: data.timestamp)
    }

    /// Callback to receive gesture data.
    public var gestureDataCallback: ((GestureType, SensorTimestamp) -> Void)?

    /// Dispatches the gesture data to the callback and handler.
    private func dispatchGestureData(type: GestureType, timestamp: SensorTimestamp) {
        gestureDataCallback?(type, timestamp)
        handler?.receivedGesture(type: type, timestamp: timestamp)
    }

    // MARK: - Accelerometer

    /// Callback to receive accelerometer readings.
    public var accelerometerCallback: ((Vector, VectorAccuracy, SensorTimestamp) -> Void)?

    /// Dispatches the accelerometer reading to the callback and handler.
    private func dispatchAccelerometer(vector: Vector, accuracy: VectorAccuracy, timestamp: SensorTimestamp) {
        accelerometerCallback?(vector, accuracy, timestamp)
        handler?.receivedAccelerometer(vector: vector, accuracy: accuracy, timestamp: timestamp)
    }

    // MARK: - Gyroscope

    /// Callback to receive gyroscope readings.
    public var gyroscopeCallback: ((Vector, VectorAccuracy, SensorTimestamp) -> Void)?

    /// Dispatches the gyroscope reading to the callback and handler.
    private func dispatchGyroscope(vector: Vector, accuracy: VectorAccuracy, timestamp: SensorTimestamp) {
        gyroscopeCallback?(vector, accuracy, timestamp)
        handler?.receivedGyroscope(vector: vector, accuracy: accuracy, timestamp: timestamp)
    }

    // MARK: - Rotation

    /// Callback to receive rotation readings.
    public var rotationCallback: ((Quaternion, QuaternionAccuracy, SensorTimestamp) -> Void)?

    /// Dispatches the rotation reading to the callback and handler.
    private func dispatchRotation(quaternion: Quaternion, accuracy: QuaternionAccuracy, timestamp: SensorTimestamp) {
        rotationCallback?(quaternion, accuracy, timestamp)
        handler?.receivedRotation(quaternion: quaternion, accuracy: accuracy, timestamp: timestamp)
    }

    // MARK: - Game Rotation

    /// Callback to receive game rotation readings.
    public var gameRotationCallback: ((Quaternion, SensorTimestamp) -> Void)?

    /// Dispatches the game rotation reading to the callback and handler.
    private func dispatchGameRotation(quaternion: Quaternion, timestamp: SensorTimestamp) {
        gameRotationCallback?(quaternion, timestamp)
        handler?.receivedGameRotation(quaternion: quaternion, timestamp: timestamp)
    }

    // MARK: - Orientation

    /// Callback to receive orientation readings.
    public var orientationCallback: ((Vector, VectorAccuracy, SensorTimestamp) -> Void)?

    /// Dispatches the orientation reading to the callback and handler.
    private func dispatchOrientation(vector: Vector, accuracy: VectorAccuracy, timestamp: SensorTimestamp) {
        orientationCallback?(vector, accuracy, timestamp)
        handler?.receivedOrientation(vector: vector, accuracy: accuracy, timestamp: timestamp)
    }

    // MARK: - Magnetometer

    /// Callback to receive magnetometer readings.
    public var magnetometerCallback: ((Vector, VectorAccuracy, SensorTimestamp) -> Void)?

    /// Dispatches the magnetometer reading to the callback and handler.
    private func dispatchMagnetometer(vector: Vector, accuracy: VectorAccuracy, timestamp: SensorTimestamp) {
        magnetometerCallback?(vector, accuracy, timestamp)
        handler?.receivedMagnetometer(vector: vector, accuracy: accuracy, timestamp: timestamp)
    }

    // MARK: - Uncalibrated Magnetometer

    /// Callback to receive uncalibrated magnetometer readings.
    public var uncalibratedMagnetometerCallback: ((Vector, Vector, SensorTimestamp) -> Void)?

    /// Dispatches the uncalibrated magnetometer reading to the callback and handler.
    private func dispatchUncalibratedMagnetometer(vector: Vector, bias: Vector, timestamp: SensorTimestamp) {
        uncalibratedMagnetometerCallback?(vector, bias, timestamp)
        handler?.receivedUncalibratedMagnetometer(vector: vector, bias: bias, timestamp: timestamp)
    }
}
