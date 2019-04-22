//
//  BoseWearable.swift
//  BoseWearable
//
//  Created by Paul Calnan on 8/13/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import BLECore
import Foundation
import Logging

/**
 Top-level interface to the BoseWearable library. Note that you must call `BoseWearable.configure(_:)` before using the `BoseWearable.shared` singleton instance. Failing to do so results in a fatal error.
 */
public class BoseWearable {

    /// Keys for the options dictionary passed to the `BoseWearable.configure(_:)` function.
    public enum ConfigOption: String {
        /// The minimum RSSI value for discovered devices. Default is -50.
        case rssiCutoff
    }

    /// The singleton instance created by `BoseWearable.configure(_:)`.
    private static var singleton: BoseWearable?

    /// The Bluetooth manager handles device discovery and session creation. Client applications can use this object to perform a device search with a custom user interface.
    public let bluetoothManager: BluetoothManager

    /// The RSSI cutoff to use if not specified in the options dictionary.
    private static let defaultRssiCutoff = -50

    /// Creates a new instance of the `BoseWearable` class with the specified options. This initializer is marked private, requiring clients to use the static `configure(_:)` function and `shared` property.
    private init(_ options: [ConfigOption: Any] = [:]) {
        let rssiCutoff = options[.rssiCutoff] as? Int ?? BoseWearable.defaultRssiCutoff
        bluetoothManager = BluetoothManager(rssiCutoff: rssiCutoff)

        bluetoothManager.registerDevice(type: BoseWearableDevice.self)
        bluetoothManager.registerDevice(type: UpgradeableBoseDevice.self)
        bluetoothManager.registerDevice(type: ConditionallyUpgradeableBoseDevice.self)
        bluetoothManager.registerService(type: WearableSensorService.self)
    }

    /// The BoseWearable bundle.
    static var bundle: Bundle {
        return Bundle(for: BoseWearable.self)
    }

    /// Creates a `WearableDeviceSession` that uses the iOS device's internal IMU to simulate the sensor data that would be received from a Bose Wearable device. *For testing purposes only.*
    public func createSimulatedWearableDeviceSession() -> WearableDeviceSession {
        return SimulatedWearableDeviceSession(device: SimulatedWearableDevice())
    }

    /// Retrieves an array of connected wearable devices. The list of connected peripherals providing the `WearableSensorService` is first retrieved. Then, the `BluetoothManager` is queried to determine which peripherals have a `Session` associated with them. If a `Session` exists and its device is a `WearableDevice` that `WearableDevice` is included in the returned array.
    func retrieveConnectedWearableDevices() -> [WearableDevice] {
        let peripherals = bluetoothManager.retrieveConnectedPeripherals(withServices: [WearableSensorService.identification.identifier])

        return peripherals.compactMap { peripheral -> WearableDevice? in
            guard let session = bluetoothManager.session(for: peripheral) else {
                return nil
            }

            return session.device as? WearableDevice
        }
    }

    /// Returns `true` if the specified discovered device's peripheral is associated with a `WearableDevice` that is returned by `retrieveConnectedWearableDevices()`.
    func isDeviceConnected(_ device: DiscoveredDevice) -> Bool {
        let connectedUUIDs =
            retrieveConnectedWearableDevices()
                .compactMap { $0 as? BoseWearableDevice }
                .map { $0.peripheral.identifier }
        return connectedUUIDs.contains(device.identifier)
    }
}

// MARK: - Static interface

extension BoseWearable {

    /// Initializes and configures the `BoseWearable` library with the specified options (if provided, otherwise default values will be used). Note this function can only be called once. Subsequent calls will result in a fatal error.
    public static func configure(_ options: [ConfigOption: Any] = [:]) {
        guard singleton == nil else {
            fatalError("BoseWearable library is already configured")
        }

        singleton = BoseWearable(options)
    }

    /// The shared singleton `BoseWearable` instance. Note that the `configure(_:)` method must be called before referencing this variable. Otherwise, a fatal error will be raised.
    public static var shared: BoseWearable {
        guard let value = singleton else {
            fatalError("BoseWearble library is not yet configured")
        }

        return value
    }
}
