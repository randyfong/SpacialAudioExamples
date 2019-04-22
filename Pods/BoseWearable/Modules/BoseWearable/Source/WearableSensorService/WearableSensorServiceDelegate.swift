//
//  WearableSensorServiceDelegate.swift
//  BoseWearable
//
//  Created by Paul Calnan on 10/23/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

/// Used by a `WearableSensorService` instance to notify when various events occur.
protocol WearableSensorServiceDelegate: class {

    /// The wearable device information characteristic was updated.
    func service(_ sender: WearableSensorService, didReceiveWearableDeviceInformation info: WearableDeviceInformation)

    /// The sensor information characteristic was updated.
    func service(_ sender: WearableSensorService, didReceiveSensorInformation info: SensorInformation)

    /// The sensor configuration characteristic was updated.
    func service(_ sender: WearableSensorService, didReceiveSensorConfiguration config: SensorConfiguration)

    /// The request to change the sensor configuration characteristic succeeded.
    func service(_ sender: WearableSensorService, didWriteSensorConfiguration config: SensorConfiguration)

    /// The request to change the sensor configuration characteristic failed with the specified error.
    func service(_ sender: WearableSensorService, didFailToWriteSensorConfiguration error: Error)

    /// The sensor data characteristic was updated.
    func service(_ sender: WearableSensorService, didReceiveSensorData data: SensorData)

    /// The gesture information characteristic was updated.
    func service(_ sender: WearableSensorService, didReceiveGestureInformation info: GestureInformation)

    /// The gesture configuration characteristic was updated.
    func service(_ sender: WearableSensorService, didReceiveGestureConfiguration config: GestureConfiguration)

    /// The request to change the gesture configuration characteristic succeeded.
    func service(_ sender: WearableSensorService, didWriteGestureConfiguration config: GestureConfiguration)

    /// The request to change the gesture configuration characteristic failed with the specified error.
    func service(_ sender: WearableSensorService, didFailToWriteGestureConfiguration error: Error)

    /// The gesture data characteristic was updated.
    func service(_ sender: WearableSensorService, didReceiveGestureData data: GestureData)
}
