//
//  DeviceSearchTask.swift
//  BoseWearable
//
//  Created by Paul Calnan on 9/19/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import BLECore
import CoreBluetooth
import Foundation
import Logging

/// Internal data structure to support a low-pass filter of RSSI values.
private struct RSSIFilter {

    /// The period of the low-pass filter.
    private static let samples: Double = 8

    /// The scale factor for new values.
    private static let factor: Double = (samples - 1.0) / samples

    /// The current filtered RSSI value.
    var rssi: Int

    /// Update the `rssi` value with the specified reading.
    mutating func addNewRSSI(_ value: Int) {
        let weightedVal = Double(value) / RSSIFilter.samples
        let newAverage = (Double(rssi) * RSSIFilter.factor) + weightedVal
        rssi = Int(newAverage.rounded())
    }

    /// Convert the filtered RSSI value to a `SignalStrength`.
    var signalStrength: SignalStrength? {
        return SignalStrength.fromRSSI(rssi)
    }
}

/**
 The `DeviceSearchTask` class encapsulates the device search functionality. It requires a `DeviceSearchUserInterface` object that gets called to show and update the device picker which allows users to select a discovered device. The `DeviceSearchUserInterface` calls back into the `DeviceSearchTask` via the `DeviceSearchUserInterfaceDelegate` protocol.
 */
public class DeviceSearchTask {

    /// The Bluetooth managed used to perform the device search.
    private let bluetoothManager: BluetoothManager

    /// The timeout value passed to `BluetoothManager.startScanning(removeAfter:)`.
    private let removeTimeout: TimeInterval

    /// The search mode.
    private let mode: DeviceSearchMode

    /// The user interface object used to display and select discovered devices.
    private var userInterface: DeviceSearchTaskUserInterface

    /// The callback to receive the result of the device search task.
    private let completionHandler: (CancellableResult<WearableDeviceSession>) -> Void

    /// A timer that fires when the auto-select timeout elapses. The user interface will be displayed in response to this.
    private var autoSelectTimeout: Timer?

    /// Maps discovered device UUIDs to the RSSI LPF for that device.
    private var rssiValues: [UUID: RSSIFilter] = [:]

    /// Flag that tracks whether the auto-select timeout has elapsed. Devices are not auto-selected after this timeout has elapsed.
    private var hasAutoSelectTimeoutElapsed = false

    /**
     Creates a new device search task. This initializer sets `self` as the `delegate` property on the `userInterface` object.

     - parameter bluetoothManager: the Bluetooth manager used to perform the device search
     - parameter removeTimeout: the timeout value passed to `BluetoothManager.startScanning(removeAfter:)`
     - parameter mode: the search mode
     - parameter userInterface: the user interface object used to display and select discovered devices
     - parameter completionHandler: the callback to receive the result of the device search task
     */
    public init(bluetoothManager: BluetoothManager = BoseWearable.shared.bluetoothManager,
                removeTimeout: TimeInterval = 15,
                mode: DeviceSearchMode,
                userInterface: DeviceSearchTaskUserInterface,
                completionHandler: @escaping (CancellableResult<WearableDeviceSession>) -> Void) {

        self.bluetoothManager = bluetoothManager
        self.removeTimeout = removeTimeout
        self.mode = mode
        self.userInterface = userInterface
        self.completionHandler = completionHandler

        self.userInterface.delegate = self
    }

    /**
     Starts the task.
     */
    public func start() {
        do {
            try bluetoothManager.startScanning(removeAfter: removeTimeout) { [weak self] event in
                DispatchQueue.main.async {
                    self?.handleDiscoveryEvent(event)
                }
            }
        }
        catch {
            finish(with: .failure(error))
        }

        switch mode {
        case .alwaysShowUI:
            hasAutoSelectTimeoutElapsed = true
            userInterface.show()

        case .automaticallySelectMostRecentlyConnectedDevice(let timeout):
            hasAutoSelectTimeoutElapsed = false
            autoSelectTimeout = Timer.scheduledTimer(timeInterval: timeout,
                                                     target: self,
                                                     selector: #selector(autoSelectTimeoutElapsed),
                                                     userInfo: nil, repeats: false)
        }
    }

    /// This is the target of the `autoSelectTimeout` timer. Shows the user interface.
    @objc private func autoSelectTimeoutElapsed() {
        hasAutoSelectTimeoutElapsed = true
        userInterface.show()
    }

    /// When a `DiscoveryEvent.added(DiscoveredDevice)` occurs, this is called. If the auto-select timeout has not yet elapsed and this device is the most-recently connected device, automatically select it.
    private func automaticallyOpenSession(for device: DiscoveredDevice) {
        if !hasAutoSelectTimeoutElapsed && isMostRecentlyConnectedDevice(device) {
            openSession(for: device)
        }
    }

    /// Opens a session for the specified device. Saves this device as the most-recently connected device.
    private func openSession(for device: DiscoveredDevice) {
        mostRecentlyConnectedDeviceIdentifier = device.identifier

        let session = RemoteWearableDeviceSession(session: bluetoothManager.session(with: device))
        finish(with: .success(session))
    }

    /// Ends the task and invokes the completion handler with the specified result.
    private func finish(with result: CancellableResult<WearableDeviceSession>) {
        autoSelectTimeout?.invalidate()
        autoSelectTimeout = nil

        bluetoothManager.stopScanning()
        completionHandler(result)
        userInterface.dismiss()
    }
}

// MARK: - DiscoveryEvent Handling

extension DeviceSearchTask {

    /// Called when a `DiscoveryEvent` is received. Routes to per-event handler functions.
    private func handleDiscoveryEvent(_ event: DiscoveryEvent) {
        switch event {
        case .added(let device):
            automaticallyOpenSession(for: device)
            add(device: device)

        case .removed(let device):
            remove(device: device)

        case .updated(let device):
            update(device: device)
        }
    }

    /// Adds the specified device.
    private func add(device: DiscoveredDevice) {
        updateRSSI(for: device)

        if let ss = signalStrength(for: device) {
            userInterface.add(device: device, signalStrength: ss)
        }
    }

    /// Removes the specified device.
    private func remove(device: DiscoveredDevice) {
        removeRSSI(for: device)
        userInterface.remove(device: device)
    }

    /// Updates the specified device.
    private func update(device: DiscoveredDevice) {
        updateRSSI(for: device)

        if let ss = signalStrength(for: device) {
            userInterface.update(device: device, signalStrength: ss)
        }
    }
}

// MARK: - RSSI Low-pass filter update

extension DeviceSearchTask {

    /// Updates the RSSI LPF for this device.
    private func updateRSSI(for device: DiscoveredDevice) {
        if rssiValues[device.identifier] == nil {
            rssiValues[device.identifier] = RSSIFilter(rssi: device.rssi)
        }
        else {
            rssiValues[device.identifier]?.addNewRSSI(device.rssi)
        }
    }

    /// Removes the RSSI LPF entry for this device.
    private func removeRSSI(for device: DiscoveredDevice) {
        rssiValues.removeValue(forKey: device.identifier)
    }

    /// Returns the signal strength for this device.
    private func signalStrength(for device: DiscoveredDevice) -> SignalStrength? {
        return rssiValues[device.identifier]?.signalStrength
    }
}

// MARK: - DeviceSearchTaskUserInterfaceDelegate

extension DeviceSearchTask: DeviceSearchTaskUserInterfaceDelegate {

    public func selected(device: DiscoveredDevice) {
        openSession(for: device)
    }

    public func cancelled() {
        finish(with: .cancelled)
    }
}

// MARK: - Most-recently connected device

extension DeviceSearchTask {

    /// UserDefaults key for the most-recently connected device.
    private static let mostRecentlyConnectedDeviceIdentifierKey = "mru-device"

    /// The UUID of the most-recently connected device. This property is backed by the default `UserDefaults`. Setting the value writes to `UserDefaults` and getting the value reads from `UserDefaults`.
    private(set) var mostRecentlyConnectedDeviceIdentifier: UUID? {
        get {
            guard let string = UserDefaults.standard.string(forKey: DeviceSearchTask.mostRecentlyConnectedDeviceIdentifierKey) else {
                return nil
            }
            return UUID(uuidString: string)
        }

        set {
            guard let string = newValue?.uuidString else {
                UserDefaults.standard.removeObject(forKey: DeviceSearchTask.mostRecentlyConnectedDeviceIdentifierKey)
                return
            }

            UserDefaults.standard.set(string, forKey: DeviceSearchTask.mostRecentlyConnectedDeviceIdentifierKey)
        }
    }

    /// Returns `true` if the specified discovered device is the most-recently connected device.
    private func isMostRecentlyConnectedDevice(_ device: DiscoveredDevice) -> Bool {
        let mrc = mostRecentlyConnectedDeviceIdentifier
        let result = (mrc == device.identifier)
        Log.session.info("Discovered device id=\(device.identifier) mostRecentlyConnected=\(String(describing: mrc)), isMostRecent=\(result)")
        return result
    }
}
