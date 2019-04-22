//
//  WearableDeviceEvent.swift
//  BoseWearable
//
//  Created by Paul Calnan on 10/8/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import BLECore
import Foundation

/// Notifications of this type are fired to indicate various events related to a wearable device.
public enum WearableDeviceEvent: TypedNotification {

    /// Indicates that the `deviceInformation` property was updated.
    case didUpdateDeviceInformation(DeviceInformation)

    /// Indicates that the `wearableDeviceInformation` property was updated.
    case didUpdateWearableDeviceInformation(WearableDeviceInformation)

    /// Indicates that the `sensorInformation` property was updated.
    case didUpdateSensorInformation(SensorInformation)

    /// Indicates that the `sensorConfiguration` property was updated.
    case didUpdateSensorConfiguration(SensorConfiguration)

    /// Indicates that a requested change to the device's sensor configuration failed with the associated error.
    case didFailToWriteSensorConfiguration(Error)

    /// Indicates that sensor data was received. While it is possible to listen for these events to get sensor data, using a `SensorDispatch` object is recommended instead.
    case didReceiveSensorData(SensorData)

    /// Indicates that the `gestureInformation` property was updated.
    case didUpdateGestureInformation(GestureInformation)

    /// Indicates that the `gestureConfiguration` property was updated.
    case didUpdateGestureConfiguration(GestureConfiguration)

    /// Indicates that a requested change to the device's gesture configuration failed with the associated error.
    case didFailToWriteGestureConfiguration(Error)

    /// Indicates that gesture data was received. While it is possible to listen for these events to get gesture data, using a `SensorDispatch` object is recommended instead.
    case didReceiveGestureData(GestureData)
}
