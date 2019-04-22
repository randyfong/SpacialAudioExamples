//
//  Session.swift
//  BLECore
//
//  Created by Paul Calnan on 8/13/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import CoreBluetooth
import Foundation
import Logging

/**
 A session represents the communication between this device and a remote peripheral. It must be opened (via the `open()` function) to initiate a connection. It must be closed (via the `close()` function) to tear down the connection. It must be disposed (via the `dispose()` function) to remove it from the `BluetoothManager` that created it, allowing it to be deallocated.

  The session object is responsible for routing CoreBluetooth events coming in to the peripheral (via the `CBPeripheralDelegate` protocol) to the appropriate service on the device.

 Calling `open()` on a session begins the connection process. This is a multi-step process that ends successfully with an instantiated `Device` object and an open communication channel. The process is as follows:

 - `open()` calls `CBCentralManager.connect(_:options:)`, passing the peripheral provided to the session initializer.
 - If the connection was successful (the `BluetoothManager` received a call to `CBCentralManagerDelegate.centralManager(_:didConnect:)` indicating a successful connection), we begin discovering services on the peripheral (via `CBPeripheral.discoverServices(_:)`).
 - After services are discovered (the session received a call to `CBPeripheralDelegate.peripheral(_:error:)` indicating success), we begin discovering characteristics for the discovered services.
 - After all characteristics are discovered (the session received calls to `CBPeripheralDelegate.peripheral(_:service:error:)` indicating success), we attempt to instantiate a matching `Device` type by calling `BluetoothManager.instantiateDevice(for:)`.
 - If a matching `Device` type is found and successfully instantiated, the session was successfully opened and the `SessionDelegate` is notified.
 - If any of the steps above fail, the `SessionDelegate` is notified.
 */
public class Session: NSObject {

    /// The manager retains the session. This allows the manager to route events to this session based on its peripheral. Disposing of this session breaks this link -- the session is removed from the manager and the manager is set to nil.
    weak var manager: BluetoothManager?

    /// The remote device that this session represents.
    public let peripheral: CBPeripheral

    /// The session delegate that receives callbacks indicating connectivity events.
    public weak var delegate: SessionDelegate?

    /// The instantiated device. This is `nil` before the connection process successfully completes.
    public private(set) var device: Device?

    /// Creates a new session. Keeps a weak back-reference to the specified `manager`. It is assumed that the `manager` owns and retains this session.
    /// Assigns `self` as the delegate for the specified `peripheral`.
    init(manager: BluetoothManager, peripheral: CBPeripheral) {
        self.manager = manager
        self.peripheral = peripheral
        super.init()

        peripheral.delegate = self
    }

    /// Opens the session. Begins the connection process.
    public func open() {
        guard let manager = manager else {
            Log.session.error("Attempting to open a disposed session!")
            return
        }

        Log.session.info("Opening session with \(peripheral)")
        manager.centralManager.connect(peripheral, options: [:])
    }

    /// Closes the session and cancels the connection to the underlying peripheral.
    public func close() {
        guard let manager = manager else {
            Log.session.error("Attempting to close a disposed session!")
            return
        }

        Log.session.info("Closing session with \(peripheral)")
        manager.centralManager.cancelPeripheralConnection(peripheral)
    }

    /// Disposes the session and removes it from `BluetoothManager`. Once a session is disposed, it is no longer valid. Calls to `open()`, `dispose()`, and `close()` have no effect.
    public func dispose() {
        guard let manager = manager else {
            Log.session.error("Attempting to dispose a disposed session!")
            return
        }

        Log.session.info("Disposing session with \(peripheral)")
        manager.removeSession(self, for: peripheral)

        self.manager = nil
    }

    // MARK: - CBCentralManagerDelegate callbacks

    /// Called by `BluetoothManager` when routing `CBCentralManagerDelegate.centralManager(_:didConnect:)` to the appropriate session (this object).
    /// Once the connection occurs, begin service discovery.
    func didConnect() {
        Log.session.info("Connected to \(peripheral), starting service discovery")

        // OPTIMIZATION: narrow down the services we want to discover
        peripheral.discoverServices(nil)
    }

    /// Called by `BluetoothManager` when routing `CBCentralManagerDelegate.centralManager(_:didFailToConnect:error:)` to the appropriate session (this object).
    /// Routes this event to the delegate.
    func didFailToConnect(error: Error?) {
        Log.session.error("Failed to connect to \(peripheral), error=\(String(describing: error))")
        DispatchQueue.main.async {
            self.delegate?.session(self, didFailToOpenWithError: error)
        }
    }

    /// Called by `BluetoothManager` when routing `CBCentralManagerDelegate.centralManager(_:didDisconnectPeripheral:error:)` to the appropriate session (this object).
    /// Routes this event to the delegate.
    func didDisconnect(error: Error?) {
        if let error = error {
            Log.session.error("Disconnected from \(peripheral), error=\(error)")
        }
        else {
            Log.session.info("Disconnected from \(peripheral)")
        }

        DispatchQueue.main.async {
            self.delegate?.session(self, didCloseWithError: error)
        }
    }
}

// MARK: - CBPeripheralDelegate

extension Session: CBPeripheralDelegate {

    /// Service discovery is started when we initially connect to a peripheral. Begin discovering characteristics for the discovered services.
    /// If error is not nil, report to the delegate that the session failed to open, then close the connection.
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {

        guard let manager = manager else {
            Log.session.error("Services discovered on disposed session (peripheral=\(peripheral), error=\(error?.localizedDescription ?? "nil")")
            return
        }

        // Route any error to the delegate indicating that the connection failed to open.
        if let error = error {
            Log.session.error("Error discovering services for \(peripheral), error=\(error)")
            DispatchQueue.main.async {
                self.delegate?.session(self, didFailToOpenWithError: error)
            }

            // Close the connection
            manager.centralManager.cancelPeripheralConnection(peripheral)
            return
        }

        Log.session.info("Discovered services for \(peripheral), starting characteristic discovery")

        // Discover characteristics for each of the discovered services,.
        for service in peripheral.services ?? [] {
            // OPTIMIZATION: narrow down the characteristics we want to discover
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    /// Characteristic discovery is started after services are successfully discovered.
    /// If error is not nil, report to the delegate that the session failed to open, then close the connection.
    /// If all services have had their characteristics discovered, attempt to instantiate the device for this peripheral. If this is successful, the session is open.
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let manager = manager else {
            Log.session.error("Characteristic discovered on disposed session (peripheral=\(peripheral) service=\(service), error=\(error?.localizedDescription ?? "nil"))")
            return
        }

        // Route any error to the delegate indicating that the connection failed to open.
        if let error = error {
            Log.session.error("Error discovering characteristics for \(service), error=\(error)")
            DispatchQueue.main.async {
                self.delegate?.session(self, didFailToOpenWithError: error)
            }

            // Close the connection
            manager.centralManager.cancelPeripheralConnection(peripheral)
            return
        }

        Log.session.info("Discovered characteristics for \(service)")

        // if we have finished scanning all services, attempt to instantiate the device
        if service == peripheral.services?.last {
            do {
                Log.session.info("Instantiating device")

                device = try manager.instantiateDevice(for: peripheral)

                Log.session.info("Session connect successful")
                DispatchQueue.main.async {
                    self.delegate?.sessionDidOpen(self)
                }
            }
            catch {
                Log.session.error("Error instantiating device, error=\(error)")
                DispatchQueue.main.async {
                    self.delegate?.session(self, didFailToOpenWithError: error)
                }
            }
        }
    }

    /// A characteristic was updated on this session's peripheral. Notify the appropriate service that this has occurred.
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        guard manager != nil else {
            Log.session.error("Characteristic value updated on disposed session " +
                "(peripheral=\(peripheral), characteristic=\(characteristic) error=\(error?.localizedDescription ?? "nil")")
            return
        }

        Log.traffic.info("peripheral didUpdateValue characteristic=\(characteristic) error=\(String(describing: error))")

        guard let service = device?.services.service(for: characteristic.service.uuid) else {
            return
        }

        #if BOSE_UNITY
        DispatchQueue.main.async {
            service.didUpdateValue(forCharacteristic: characteristic.uuid, error: error)
        }
        #else
            service.didUpdateValue(forCharacteristic: characteristic.uuid, error: error)
        #endif
    }

    /// The notification state of a characteristic was updated on this session's peripheral. Notify the appropriate service that this has occurred.
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {

        guard manager != nil else {
            Log.session.error("Notification state updated on disposed session " +
                "(peripheral=\(peripheral), characteristic=\(characteristic) error=\(error?.localizedDescription ?? "nil")")
            return
        }

        Log.traffic.info("peripheral didUpdateNotificationState characteristic=\(characteristic), state=\(characteristic.isNotifying) error=\(String(describing: error))")

        guard let service = device?.services.service(for: characteristic.service.uuid) else {
            return
        }

        #if BOSE_UNITY
        DispatchQueue.main.async {
            service.didUpdateNotificationState(forCharacteristic: characteristic.uuid, error: error)
        }
        #else
            service.didUpdateNotificationState(forCharacteristic: characteristic.uuid, error: error)
        #endif
    }

    /// A characteristic's value was written. Notify the appropriate service that this has occurred.
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {

        guard manager != nil else {
            Log.session.error("Did write value on disposed session (peripheral=\(peripheral), characteristic=\(characteristic) error=\(error?.localizedDescription ?? "nil")")
            return
        }

        Log.traffic.info("peripheral didWriteValue characteristic=\(characteristic) error=\(String(describing: error))")

        guard let service = device?.services.service(for: characteristic.service.uuid) else {
            return
        }

        #if BOSE_UNITY
        DispatchQueue.main.async {
            service.didWriteValue(forCharacteristic: characteristic.uuid, error: error)
        }
        #else
            service.didWriteValue(forCharacteristic: characteristic.uuid, error: error)
        #endif
    }
}
