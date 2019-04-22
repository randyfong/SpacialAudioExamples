//
//  WearableDevice.swift
//  BoseWearable
//
//  Created by Paul Calnan on 10/12/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.61
//

import BLECore
import Foundation

/// Represents a wearable device instance.
public protocol WearableDevice {

    /// The name of the device.
    var name: String? { get }

    /// Device information, as reported by the GATT device information service. When this value is updated, a `WearableDeviceEvent.didUpdateDeviceInformation(DeviceInformation)` event is fired.
    var deviceInformation: DeviceInformation? { get }

    /// Refreshes the device information. When the new value is received, the `deviceInformation` property is updated.
    func refreshDeviceInformation()

    /// Wearable device information. When this value is updated, a `WearableDeviceEvent.didUpdateWearableDeviceInformation(WearableDeviceInformation)` event is fired.
    var wearableDeviceInformation: WearableDeviceInformation? { get }

    /// Refreshes the wearable device information. When the new value is received, the `wearableDeviceInformation` property is updated.
    func refreshWearableDeviceInformation()

    /// Information about the sensors provided by the wearable device. When this value is updated, a `WearableDeviceEvent.didUpdateSensorInformation(SensorInformation)` event is fired.
    var sensorInformation: SensorInformation? { get }

    /// Refreshes the sensor information. When the new value is received, the `sensorInformation` property is updated.
    func refreshSensorInformation()

    /// The configuration of the sensors provided by the wearable device. When this value is updated, a `WearableDeviceEvent.didUpdateSensorConfiguration(SensorConfiguration)` event is fired.
    var sensorConfiguration: SensorConfiguration? { get }

    /// Refreshes the sensor configuration. When a new value is received, the `sensorConfiguration` property is updated.
    func refreshSensorConfiguration()

    /// Requests a change to the current sensor configuration. When this function is called, the specified sensor configuration value is written to the remote device. If the remote device accepts the new configuration, the `sensorConfiguration` property is updated. If the remote device rejects the new configuration, a `WearableDeviceEvent.didFailToWriteSensorConfiguration(Error)` event is fired.
    func changeSensorConfiguration(_ newConfiguration: SensorConfiguration)

    /// Information about the gestures provided by the wearable device. When this value is updated, a `WearableDeviceEvent.didUpdateGestureInformation(GestureInformation)` event is fired.
    var gestureInformation: GestureInformation? { get }

    /// Refreshes the gesture information. When a new value is received, the `gestureInformation` property is updated.
    func refreshGestureInformation()

    /// The configuration of the gesture recognition facility provided by the wearable device. When this value is updated, a `WearableDeviceEvent.didUpdateGestureConfiguration(GestureConfiguration)` event is fired.
    var gestureConfiguration: GestureConfiguration? { get }

    /// Refreshes the gesture configuration. When a new value is received, the `gestureConfiguration` property is updated.
    func refreshGestureConfiguration()

    /// Requests a change to the current gesture configuration. When this function is called, the specified gesture configuration value is written to the remote device. If the remote device accepts the new configuration, the `gestureConfiguration` property is updated. If the remote device rejects the new configuration, a `WearableDeviceEvent.didFailToWriteGestureConfiguration(Error)` event is fired.
    func changeGestureConfiguration(_ newConfiguration: GestureConfiguration)

    /// For internal use only. Returns `true` if the necessary startup information has been received and the device is ready for operation, `false` otherwise. Throws an error if the device is not supported or if it requires a firmware update.
    func deviceIsReady() throws -> Bool
}

extension WearableDevice {

    /**
     Configure the sensors on a wearable device. The caller provides a block to this function that takes a `SensorConfiguration` value. The current `SensorConfiguration` is passed to the block which is executed synchronously on the calling thread. That `SensorConfiguration` value can be modified to match the desired configuration. Once the block returns, that updated configuration is then sent to the wearable device (via `WearableDevice.changeSensorConfiguration(_:)`).

     If the remote device accepts the new configuration, the `sensorConfiguration` property is updated. If the remote device rejects the new configuration, a `WearableDeviceEvent.didFailToWriteSensorConfiguration(Error)` event is fired.

     For example, to enable the accelerometer and gyroscope at 50 Hz (20 ms update period):

     ```
     device.configureSensors { config in
         // Reset the configuration so all other sensors are disabled.
         config.disableAll()

         // Enable the desired sensors.
         config.enable(.accelerometer, at: ._20ms)
         config.enable(.gyroscope, at: ._20ms)
     }
     ```
     */
    public func configureSensors(_ body: (inout SensorConfiguration) -> Void) {
        guard var modified = sensorConfiguration else {
            return
        }

        body(&modified)
        changeSensorConfiguration(modified)
    }

    /**
     Configure the gestures on a wearable device. The caller provides a block to this function that takes a `GestureConfiguration` value. The current `GestureConfiguration` is passed to the block which is executed synchronously on the calling thread. That `GestureConfiguration` value can be modified to match the desired configuration. Once the block returns, that updated configuration is then sent to the wearable device (via `WearableDevice.changeGestureConfiguration(_:)`).

     If the remote device accepts the new configuration, the `gestureConfiguration` property is updated. If the remote device rejects the new configuration, a `WearableDeviceEvent.didFailToWriteGestureConfiguration(Error)` event is fired.

     For example, to enable the double-tap gesture:

     ```
     device.configureGestures { config in
         // Reset the configuration so all other gestures are disabled.
         config.disableAll()

         // Enable the desired gestures.
         config.set(gesture: .doubleTap, enabled: true)
     }
     ```
     */
    public func configureGestures(_ body: (inout GestureConfiguration) -> Void) {
        guard var modified = gestureConfiguration else {
            return
        }

        body(&modified)
        changeGestureConfiguration(modified)
    }
}
