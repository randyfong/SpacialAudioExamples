//
//  SimulatedWearableDevice.swift
//  BoseWearable
//
//  Created by Paul Calnan on 10/12/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import BLECore
import CoreBluetooth
import CoreMotion
import Logging
import UIKit

/// Simulates the WearableDevice interface using the iOS device's internal IMU.
class SimulatedWearableDevice: WearableDevice {

    /// Error codes specific to the SimulatedWearableDevice.
    enum SimulatedWearableDeviceError: Error {

        /// Gestures are not supported by a SimulatedWearableDevice. Any attempt to configure gestures will result in this error being thrown.
        case simulatedDeviceDoesNotSupportGestures
    }

    /// CoreMotion manager to get device IMU data.
    private let motionManager = CMMotionManager()

    /// The operation queue used for receiving callbacks from `motionManager` as well as posting `WearableDeviceEvent` events.
    private let queue: OperationQueue = {
        let q = OperationQueue()
        q.qualityOfService = .userInitiated
        return q
    }()

    var name: String? {
        return UIDevice.current.name
    }

    let deviceInformation: DeviceInformation? = DeviceInformation(
        systemID: UIDevice.current.name.data(using: .utf8),
        modelNumber: UIDevice.current.model,
        serialNumber: UIDevice.current.identifierForVendor?.uuidString,
        firmwareRevision: UIDevice.current.systemVersion,
        hardwareRevision: UIDevice.current.systemVersion,
        softwareRevision: UIDevice.current.systemVersion,
        manufacturerName: "Apple",
        regulatoryCertificationDataList: nil,
        pnpID: nil
    )

    func refreshDeviceInformation() {
        guard let di = deviceInformation else {
            return
        }
        post(.didUpdateDeviceInformation(di))
    }

    let wearableDeviceInformation: WearableDeviceInformation? = WearableDeviceInformation(
        majorVersion: 0,
        minorVersion: 0,
        productID: 0,
        variant: 0,
        availableSensors: Set([.accelerometer, .gyroscope, .rotation, .magnetometer]),
        availableGestures: Set(),
        transmissionPeriod: 0,
        maximumPayloadPerTransmissionPeriod: UInt16.max,
        maximumActiveSensors: 4,
        deviceStatus: DeviceStatus(rawValue: 0)
    )

    func refreshWearableDeviceInformation() {
        guard let wdi = wearableDeviceInformation else {
            return
        }
        post(.didUpdateWearableDeviceInformation(wdi))
    }

    var sensorInformation: SensorInformation? {
        return SensorInformation(entries: [
            SensorInformation.Entry(
                sensorId: SensorType.accelerometer.rawValue,
                scaledValueRange: -1..<1,
                rawValueRange: -1..<1,
                availableSamplePeriods: Set(SamplePeriod.all),
                sampleLength: 1
            ),
            SensorInformation.Entry(
                sensorId: SensorType.gyroscope.rawValue,
                scaledValueRange: -1..<1,
                rawValueRange: -1..<1,
                availableSamplePeriods: Set(SamplePeriod.all),
                sampleLength: 1
            ),
            SensorInformation.Entry(
                sensorId: SensorType.rotation.rawValue,
                scaledValueRange: -1..<1,
                rawValueRange: -1..<1,
                availableSamplePeriods: Set(SamplePeriod.all),
                sampleLength: 1
            ),
            SensorInformation.Entry(
                sensorId: SensorType.magnetometer.rawValue,
                scaledValueRange: -1..<1,
                rawValueRange: -1..<1,
                availableSamplePeriods: Set(SamplePeriod.all),
                sampleLength: 1
            )
        ])
    }

    func refreshSensorInformation() {
        guard let si = sensorInformation else {
            return
        }
        post(.didUpdateSensorInformation(si))
    }

    /// Converts the specified `TimeInterval` to milliseconds, capped at `UInt16.max`.
    private func milliseconds(_ interval: TimeInterval) -> UInt16 {
        let ms = interval * 1000
        return ms > Double(UInt16.max) ? UInt16.max : UInt16(ms)
    }

    var sensorConfiguration: SensorConfiguration? {
        return SensorConfiguration(entries: [
            SensorConfiguration.Entry(
                sensor: .accelerometer,
                samplePeriod: isEnabled(sensor: .accelerometer)
                    ? milliseconds(motionManager.accelerometerUpdateInterval)
                    : 0),
            SensorConfiguration.Entry(
                sensor: .gyroscope,
                samplePeriod: isEnabled(sensor: .gyroscope)
                    ? milliseconds(motionManager.gyroUpdateInterval)
                    : 0),
            SensorConfiguration.Entry(
                sensor: .rotation,
                samplePeriod: isEnabled(sensor: .rotation)
                    ? milliseconds(motionManager.deviceMotionUpdateInterval)
                    : 0),
            SensorConfiguration.Entry(
                sensor: .magnetometer,
                samplePeriod: isEnabled(sensor: .magnetometer)
                    ? milliseconds(motionManager.magnetometerUpdateInterval)
                    : 0)
        ])
    }

    func refreshSensorConfiguration() {
        guard let sc = sensorConfiguration else {
            return
        }
        post(.didUpdateSensorConfiguration(sc))
    }

    /// Tracks whether the accelerometer is enabled.
    private var isAccelerometerEnabled = false

    /// Tracks whether the gyroscope is enabled.
    private var isGyroscopeEnabled = false

    /// Tracks whether the rotation sensor is enabled.
    private var isRotationEnabled = false

    /// Tracks whether the magnetometer is enabled.
    private var isMagnetometerEnabled = false

    func changeSensorConfiguration(_ newConfiguration: SensorConfiguration) {
        newConfiguration.entries.forEach { entry in
            let enabled = entry.isEnabled
            let updateInterval = TimeInterval(entry.samplePeriod?.milliseconds ?? 0) / 1000

            switch entry.sensor {
            case .accelerometer:
                if enabled {
                    motionManager.accelerometerUpdateInterval = updateInterval
                    motionManager.startAccelerometerUpdates(to: queue) { [weak self] (data, error) in
                        self?.post(self?.sensorData(from: data, error: error))
                    }
                }
                else {
                    motionManager.stopAccelerometerUpdates()
                }
                isAccelerometerEnabled = enabled

            case .gyroscope:
                if enabled {
                    motionManager.gyroUpdateInterval = updateInterval
                    motionManager.startGyroUpdates(to: queue) { [weak self] (data, error) in
                        self?.post(self?.sensorData(from: data, error: error))
                    }
                }
                else {
                    motionManager.stopGyroUpdates()
                }
                isGyroscopeEnabled = enabled

            case .rotation:
                if enabled {
                    motionManager.deviceMotionUpdateInterval = updateInterval
                    motionManager.startDeviceMotionUpdates(to: queue) { [weak self] (data, error) in
                        self?.post(self?.sensorData(from: data, error: error))
                    }
                }
                else {
                    motionManager.stopDeviceMotionUpdates()
                }
                isRotationEnabled = enabled

            case .magnetometer:
                if enabled {
                    motionManager.magnetometerUpdateInterval = updateInterval
                    motionManager.startMagnetometerUpdates(to: queue) { [weak self] (data, error) in
                        self?.post(self?.sensorData(from: data, error: error))
                    }
                }
                else {
                    motionManager.stopMagnetometerUpdates()
                }
                isMagnetometerEnabled = enabled

            default:
                return
            }
        }

        DispatchQueue.main.async {
            guard let sc = self.sensorConfiguration else {
                return
            }
            self.post(.didUpdateSensorConfiguration(sc))
        }
    }

    /// Helper function to see whether the specified sensor type is enabled.
    private func isEnabled(sensor: SensorType) -> Bool {
        switch sensor {
        case .accelerometer:
            return isAccelerometerEnabled

        case .gyroscope:
            return isGyroscopeEnabled

        case .rotation:
            return isRotationEnabled

        case .magnetometer:
            return isMagnetometerEnabled

        default:
            return false
        }
    }

    var gestureInformation: GestureInformation? {
        return GestureInformation(entries: [])
    }

    func refreshGestureInformation() {
        guard let gi = gestureInformation else {
            return
        }
        post(.didUpdateGestureInformation(gi))
    }

    var gestureConfiguration: GestureConfiguration? {
        return GestureConfiguration(entries: [])
    }

    func refreshGestureConfiguration() {
        guard let gc = gestureConfiguration else {
            return
        }
        post(.didUpdateGestureConfiguration(gc))
    }

    func changeGestureConfiguration(_ newConfiguration: GestureConfiguration) {
        post(.didFailToWriteGestureConfiguration(SimulatedWearableDeviceError.simulatedDeviceDoesNotSupportGestures))
    }

    /// Posts the specified `WearableDeviceEvent` on the internal `queue`.
    private func post(_ event: WearableDeviceEvent) {
        queue.addOperation {
            NotificationCenter.default.post(event, from: self)
        }
    }

    /// Posts the specified sensor data as a `WearableDeviceEvent.didReceiveSensorData`. This is not performed on the internal `queue` as the callback from `CMMotionManager` that triggers this call is already on that `queue`.
    private func post(_ sensorData: SensorData?) {
        guard let sensorData = sensorData else {
            return
        }
        NotificationCenter.default.post(WearableDeviceEvent.didReceiveSensorData(sensorData), from: self)
    }

    /// Converts `CMAccelerometerData` to `SensorData`.
    private func sensorData(from accel: CMAccelerometerData?, error: Error?) -> SensorData? {
        guard let accel = accel else {
            Log.sensor.error("Accelerometer update error: \(String(describing: error))")
            return nil
        }

        let vector = Vector(accel.acceleration.x, accel.acceleration.y, accel.acceleration.z)
        let sample = SensorSample.accelerometer(value: vector, accuracy: .high)

        return SensorData(value: SensorValue(sensor: .accelerometer, timestamp: timestamp(accel), sample: sample))
    }

    /// Converts `CMGyroData` to `SensorData`.
    private func sensorData(from gyro: CMGyroData?, error: Error?) -> SensorData? {
        guard let gyro = gyro else {
            Log.sensor.error("Gyroscope update error: \(String(describing: error))")
            return nil
        }

        let vector = Vector(gyro.rotationRate.x, gyro.rotationRate.y, gyro.rotationRate.z)
        let sample = SensorSample.gyroscope(value: vector, accuracy: .high)

        return SensorData(value: SensorValue(sensor: .gyroscope, timestamp: timestamp(gyro), sample: sample))
    }

    /// Converts `CMDeviceMotion` to `SensorData`.
    private func sensorData(from motion: CMDeviceMotion?, error: Error?) -> SensorData? {
        guard let motion = motion else {
            Log.sensor.error("Motion update error: \(String(describing: error))")
            return nil
        }

        let quaternion = Quaternion(ix: motion.attitude.quaternion.x,
                                    iy: motion.attitude.quaternion.y,
                                    iz: motion.attitude.quaternion.z,
                                    r: motion.attitude.quaternion.w)
        let sample = SensorSample.rotation(value: quaternion, accuracy: QuaternionAccuracy(estimatedAccuracy: 0))

        return SensorData(value: SensorValue(sensor: .rotation, timestamp: timestamp(motion), sample: sample))
    }

    /// Converts `CMMagnetometerData` to `SensorData`.
    private func sensorData(from mag: CMMagnetometerData?, error: Error?) -> SensorData? {
        guard let mag = mag else {
            Log.sensor.error("Magnetometer update error: \(String(describing: error))")
            return nil
        }

        let vector = Vector(mag.magneticField.x, mag.magneticField.y, mag.magneticField.z)
        let sample = SensorSample.magnetometer(value: vector, accuracy: .high)

        return SensorData(value: SensorValue(sensor: .magnetometer, timestamp: timestamp(mag), sample: sample))
    }

    /// Converts a CoreMotion timestamp to a `SensorTimestamp`.
    private func timestamp(_ sample: CMLogItem) -> SensorTimestamp {
        let ts = (sample.timestamp * 1000).truncatingRemainder(dividingBy: TimeInterval(SensorTimestamp.max)).rounded()
        return SensorTimestamp(ts)
    }

    func deviceIsReady() throws -> Bool {
        return true
    }
}
