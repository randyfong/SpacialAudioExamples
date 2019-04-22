//
//  BluetoothManager.swift
//  BLECore
//
//  Created by Paul Calnan on 8/13/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import CoreBluetooth
import Foundation
import Logging

/**
 The `BluetoothManager` class is used to discover devices
 */
public class BluetoothManager: NSObject {

    // MARK: - Constants

    /// Options passed to the `CBCentralManager` initializer
    private let centralManagerOptions: [String: Any]? = [
        CBCentralManagerOptionShowPowerAlertKey: true
    ]

    /// Options passed to `CBCentralManager.scanForPeripherals(withServices:options:)`
    private let scanOptions: [String: Any]? = [
        CBCentralManagerScanOptionAllowDuplicatesKey: true
    ]

    // MARK: - Properties

    /// Serial dispatch queue for central manager events
    private let queue = DispatchQueue(label: "com.bose.BLECore.BluetoothManager.queue", qos: .userInteractive, attributes: [])

    /// The RSSI cutoff provided to the initializer
    private let rssiCutoff: Int

    /// The wrapped CBCentralManager
    private(set) var centralManager: CBCentralManager!

    /// Registered device types
    private var deviceTypes: [Device.Type] = []

    /// Registered service types
    private var serviceTypes: [Service.Type] = []

    /// The most recently specified timeout provided to `startScanning(removeAfter:callback:)`
    private var removeTimeout: TimeInterval!

    /// The most recently specified discovery callback provided to `startScanning(removeAfter:callback:)`. This value is used to indicate whether a scan is already in progress. It must be set to `nil` when a scan is stopped in order for subsequent scans to be allowed.
    private var discoveryCallback: ((DiscoveryEvent) -> Void)?

    /// Maps peripherals to the `DiscoveredDevice` objects that wrap them.
    private var deviceMap: [CBPeripheral: DiscoveredDevice] = [:]

    /// Discovered devices are removed if not seen before their corresponding timer fires. These timers are created from a serial `DispatchQueue` without a run loop attached to it. Consequently, we need to use a `DispatchSourceTimer` instead of an ordinary `Timer`.
    private var peripheralRemovalTimers: [CBPeripheral: DispatchSourceTimer] = [:]

    /// Used to route peripheral events to sessions.
    private var sessions: [CBPeripheral: Session] = [:]

    /// Abbreviating type alias
    private typealias AdvertisementData = [String: Any]

    /// Cache advertisement data here when received for a given peripheral
    private var advertisements: [CBPeripheral: AdvertisementData] = [:]

    /**
     Creates a new `BluetoothManager` instance. The specified `rssiCutoff` value is used during device discovery to filter out devices that fall below this threshold.

     - parameter rssiCutoff: discovered peripherals with an RSSI below this value are ignored
     */
    public init(rssiCutoff: Int) {
        self.rssiCutoff = rssiCutoff
        super.init()

        centralManager = CBCentralManager(delegate: self, queue: queue, options: centralManagerOptions)
        registerService(type: DeviceInformationService.self)
    }
}

// MARK: - Registration

extension BluetoothManager {

    /// Prior to scanning for devices, client applications must register their supported `Device` types with this function.
    public func registerDevice<T: Device>(type: T.Type) {
        deviceTypes.append(type)
    }

    /// Prior to scanning for devices, client applications must register their supported `Service` types with this function.
    public func registerService<T: Service>(type: T.Type) {
        serviceTypes.append(type)
    }
}

// MARK: - Scanning

extension BluetoothManager {

    /// A flattened array of all of the advertisement UUIDs from all of the registered device types.
    private var scanServices: [CBUUID] {
        var uuids = Set<CBUUID>()

        deviceTypes.forEach { type in
            type.identification.requiredAdvertisedServiceUUIDs.forEach { uuid in
                uuids.insert(uuid.asUUID)
            }
        }

        return Array(uuids)
    }

    /**
     Begins scanning for devices. The specified callback is invoked on a background queue whenever:

     - a new device is discovered (receives a `DiscoveryEvent.added(DiscoveredDevice)`)
     - a previously discovered device is updated (receives a `DiscoveryEvent.updated(DiscoveredDevice)`)
     - a previously discovered device has been lost (receives a `DiscoveryEvent.removed(DiscoveredDevice)`)

     During the discovery process, advertising data is repeatedly received. Each time it is received, it is translated into one of these events. If advertising data is not received for a device within the specified `timeout`, that device is removed.

     No `DiscoveryEvent` will be emitted if:

     - If a discovered device does not match a registered device type, or
     - If the device's RSSI value does not meet the threshold provided to the initializer

     Only one scan can be in progress at a given. You application must call `BluetoothManager.stopScanning()` in order to end an in-progress scan. Failure to do so causes this function to throw a `BLECoreError.scanAlreadyInProgress` error.

     Note that a scan will continue indefinitely. It is the responsibility of the client to stop a scan after a device has been found.

     - parameter timeout: amount of time elapsed after an advertisement is received before considering the device lost and removing it
     - parameter callback: invoked on a background queue to indicate that a device has been added, updated, or removed
     - throws: `BLECoreError.scanAlreadyInProgress` if a scan is already in progress
     */
    public func startScanning(removeAfter timeout: TimeInterval, callback: @escaping (DiscoveryEvent) -> Void) throws {
        guard discoveryCallback == nil else {
            Log.discovery.error("Scan already in progress")
            throw BLECoreError.scanAlreadyInProgress
        }

        Log.discovery.info("Starting scan")

        self.removeTimeout = timeout
        discoveryCallback = callback

        startScanning()
    }

    /**
     Only start the scan if:
     A.) The callback has been set by startScanning(removeAfter:callback:) to
         avoid starting a scan in response to a .poweredOn state change
         without actually wanting to start a scan.
     B.) The central manager is in .poweredOn state, to prevent an error from
         being raised by CBCentralManager.
     Fails silently if these conditions are not met -- the error is raised by the caller
     */
    private func startScanning() {
        guard discoveryCallback != nil, centralManager.state == .poweredOn else {
            return
        }

        Log.discovery.info("Scan for peripherals with services: \(scanServices)")
        centralManager.scanForPeripherals(withServices: scanServices, options: scanOptions)
    }

    /// Stops scanning for devices. This must be called before a subsequent scan is performed.
    public func stopScanning() {
        Log.discovery.info("Stopping scan")

        centralManager.stopScan()

        queue.sync { [weak self] in
            self?.peripheralRemovalTimers = [:]
        }

        discoveryCallback = nil
    }
}

// MARK: - Peripheral list management

extension BluetoothManager {

    /**
     Finds the matching `Device` types for the specified peripheral using cached advertisement data. If no cached advertisement data is available, returns an empty array.

     - parameter peripheral: the peripheral being checked
     - returns: an array of `Device` types matching the specified peripheral
     */
    private func usingCachedAdvertisementDataFindDeviceTypes(for peripheral: CBPeripheral) -> [Device.Type] {
        guard let data = advertisements[peripheral] else {
            return []
        }
        return findDeviceTypes(for: peripheral, withAdvertisementData: data)
    }

    /**
     Finds the matching `Device` types for the specified peripheral using the specified advertisement data.

     - parameter peripheral: the peripheral being checked
     - parameter data: the advertising data for the peripheral
     - returns: an array of `Device` types matching the specified peripheral
     */
    private func findDeviceTypes(for peripheral: CBPeripheral, withAdvertisementData data: AdvertisementData) -> [Device.Type] {
        return deviceTypes.filter { type -> Bool in
            return type.identification.matches(peripheral: peripheral, advertisementData: data)
        }
    }

    /**
     This function is called whenever a peripheral is discovered. If the peripheral should be included in the search results, a `DiscoveredDevice` is returned. Otherwise, `nil` is returned.

     This method returns `nil` for discovered peripherals that are filtered out:

     - Peripherals that have an unknown RSSI value or have an RSSI value that does not meet the cutoff provided to the initializer are filtered out.
     - Peripherals that do not have a matching device type (i.e., `findDeviceTypes(for:withAdvertisementData:)` returns an empty array) are filtered out.

     If the peripheral is not included in the `deviceMap`, a new `DiscoveredDevice` is created, added to `deviceMap`, and returned. If the peripheral is included in the `deviceMap`, it is returned.
     */
    private func addOrUpdateDevice(for peripheral: CBPeripheral, advertisementData: [String: Any], rssi: Int) -> DiscoveredDevice? {

        Log.discovery.debug("addOrUpdate peripheral=\(peripheral) advertisement=\(advertisementData) rssi=\(rssi)")

        // Per IOBluetooth.IOBluetoothDevice documentation:
        // If the (RSSI) value cannot be read (e.g. the device is disconnected) or is not available on a module, a value of +127 will be returned.
        let unknownRSSI = 127

        // Filter out devices below the RSSI cutoff. Also filter out devices with an unknown RSSI.
        guard rssi > rssiCutoff && rssi != unknownRSSI else {
            Log.discovery.debug("Dropping device with low or unknown RSSI")
            return nil
        }

        // cache the advertisement data
        advertisements[peripheral] = advertisementData

        // If there is no matching device type, return nil.
        if findDeviceTypes(for: peripheral, withAdvertisementData: advertisementData).isEmpty {
            Log.discovery.debug("No matching device types found")
            return nil
        }

        // add or update the device
        if let device = deviceMap[peripheral] {
            Log.discovery.debug("Updating existing device")
            device.update(peripheral: peripheral, advertisementData: advertisementData, rssi: rssi)
            return device
        }
        else {
            Log.discovery.debug("Adding new device")
            let device = DiscoveredDevice(peripheral: peripheral, advertisementData: advertisementData, rssi: rssi)
            deviceMap[peripheral] = device
            return device
        }
    }

    /// Resets the removal timer for the specified peripheral. Returns `true` if this peripheral is new (i.e., it does not already have a timer). Returns `false` if this is a known peripheral (i.e., it already has a timer).
    private func resetTimer(for peripheral: CBPeripheral) -> Bool {
        let added: Bool

        if let timer = peripheralRemovalTimers[peripheral] {
            timer.cancel()
            added = false
        }
        else {
            added = true
        }

        // We can't use a Timer object as this is called from a serial DispatchQueue
        // without a run loop attached to it. Use a DispatchSourceTimer instead.

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + removeTimeout)
        timer.setEventHandler { [weak self] in
            self?.remove(peripheral)
        }
        timer.resume()

        peripheralRemovalTimers[peripheral] = timer

        return added
    }

    /// Removes the specified peripheral as a result of its associated timer firing.
    private func remove(_ peripheral: CBPeripheral) {
        Log.discovery.info("Removing peripheral \(peripheral) after timeout of \(String(describing: removeTimeout))")

        if let device = deviceMap[peripheral] {
            discoveryCallback?(.removed(device))
        }

        peripheralRemovalTimers[peripheral]?.cancel()
        peripheralRemovalTimers.removeValue(forKey: peripheral)
    }

    /**
     Returns a list of the peripherals containing any of the specified services currently connected to the system.

     The list of connected peripherals can include those that are connected by other apps and that will need to be connected locally before they can be used.

     This function simply passes through to call the corresponding function on the `CBCentralManager` instance.

     - parameter serviceUUIDs: a list of service UUIDs
     - returns: a list of the peripherals that are currently connected to the system and the contain any of the services specified in the `serviceUUIDs` parameter.
     */
    public func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUIDConvertible]) -> [CBPeripheral] {
        return centralManager.retrieveConnectedPeripherals(withServices: serviceUUIDs.map { $0.asUUID })
    }
}

// MARK: - Session management

extension BluetoothManager {

    /**
     This is going to be called by `Session` once service and characteristic discovery is complete for the specified peripheral. We check the registered device types and their cached advertisement data to find any matching device types (see `BluetoothManager.usingCachedAdvertisementDataFindDeviceTypes(for:)`. We attempt to instantiate the first device type for which this peripheral provides the required services. Any errors thrown by the `Device` initializer is passed up to the caller.

     If no matching device types were found for this peripheral or if the peripheral does not provide the required services for any of the matching device types, we throw `BLECoreError.noMatchingDeviceTypesFound`. This could be broken up into two errors if it is necessary to differentiate between these two error conditions.
     */
    func instantiateDevice(for peripheral: CBPeripheral) throws -> Device {

        // Find the matching device types. Log an error if there are multiple matching types
        let matchingDeviceTypes = usingCachedAdvertisementDataFindDeviceTypes(for: peripheral)
        if matchingDeviceTypes.count > 1 {
            let typeNames = matchingDeviceTypes.map({ String(describing: $0) }).joined(separator: ", ")
            Log.discovery.error("Warning: Multiple matching device types found: \(typeNames)")
        }

        // Loop over the matching device types...
        for type in matchingDeviceTypes {

            // If this peripheral provides the requires services for this device type...
            if self.peripheral(peripheral, providesRequiredServicesFor: type) {

                // Instantiate the services and try to instantiate the device type. Do not handle any thrown errors.
                let services = instantiateServices(for: peripheral)
                return try type.init(peripheral: peripheral, services: services)
            }
        }

        // There were no matching device types found
        // or
        // This peripheral does not provide the required services for any of the matching device types
        throw BLECoreError.noMatchingDeviceTypesFound
    }

    /// Compares the available service IDs (the UUIDs of the services provided by the peripheral) with the required service IDs (declared by the device type). Returns true if all of the required service IDs are contained in the available service IDs.
    private func peripheral(_ peripheral: CBPeripheral, providesRequiredServicesFor type: Device.Type) -> Bool {
        let availableServiceIDs = Set(peripheral.services?.map { $0.uuid } ?? [])
        let requiredServiceIDs = Set(type.identification.requiredServices.map { $0.identifier.asUUID })

        return requiredServiceIDs.subtracting(availableServiceIDs).isEmpty
    }

    /// Attempts to instantiate a `Service` type for each of the `CBService` objects provided by the specified peripheral. Bundles them together into a `ServiceSet` object.
    private func instantiateServices(for peripheral: CBPeripheral) -> ServiceSet {
        var services = [CBUUID: Service]()

        for cbService in peripheral.services ?? [] {
            if let service = instantiateService(for: cbService) {
                services[cbService.uuid] = service
            }
        }

        return ServiceSet(services: services)
    }

    /// Attempts to instantiate a `Service` type for the specified `CBService` object. Finds the first `Service` type whose `identifier` matches the `CBService` object's `uuid` and instantiates it. Returns `nil` if one cannot be found.
    private func instantiateService(for service: CBService) -> Service? {
        for type in serviceTypes where type.identification.identifier.asUUID == service.uuid {
            return type.init(service: service)
        }

        return nil
    }

    /**
     Returns a session for the specified device. If a session already exists for this device, it is returned. Otherwise, a new session is created and returned.

     - parameter device: the device
     - returns: a session for that device
     */
    public func session(with device: DiscoveredDevice) -> Session {
        let peripheral = device.peripheral

        if let session = sessions[peripheral] {
            return session
        }

        let session = Session(manager: self, peripheral: peripheral)
        sessions[peripheral] = session

        Log.session.info("Added session for peripheral \(peripheral); \(sessions.count) session(s) exist")
        return session
    }

    /**
     Returns the `Session` associated with the specified peripheral, or `nil` of one does not exist.

     - parameter peripheral: the peripheral
     - returns: the session associated with the specified peripheral
     */
    public func session(for peripheral: CBPeripheral) -> Session? {
        return sessions[peripheral]
    }

    /// Called from `Session.dispose()` to remove the session from the peripheral-to-session table.
    func removeSession(_ session: Session, for peripheral: CBPeripheral) {
        sessions.removeValue(forKey: peripheral)
        Log.session.info("Removed session for peripheral \(peripheral); \(sessions.count) session(s) remain")
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {

    /// When the central manager updates state, begin scanning.
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Log.discovery.info("centralManager didUpdateState to: \(central.state.rawValue)")
        startScanning()
    }

    /// When a peripheral is discovered, add or update the device list and notify the discovery callback.
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let rssi = RSSI.intValue
        let msg = "peripheral: \(peripheral.identifier), name: \(peripheral.name ?? "nil"), rssi: \(rssi)"

        // If addOrUpdateDevice returns nil, it has filtered out the device and we are done
        guard let device = addOrUpdateDevice(for: peripheral, advertisementData: advertisementData, rssi: rssi) else {
            return
        }

        // It is slightly awkward to use resetTimer to make the determination of whether this peripheral is known or not. However, this simplifies addOrUpdateDevice, allowing it to return a single value (the DiscoveredDevice, or nil if filtered out).

        if resetTimer(for: peripheral) {
            Log.discovery.debug("Added \(msg)")
            discoveryCallback?(.added(device))
        }
        else {
            Log.discovery.debug("Updated \(msg)")
            discoveryCallback?(.updated(device))
        }
    }

    /// When a peripheral connects, notify the corresponding `Session`.
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard let session = sessions[peripheral] else {
            Log.discovery.info("Peripheral without a session connected")
            return
        }
        session.didConnect()
    }

    /// When a peripheral fails to connect, notify the corresponding `Session`.
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        guard let session = sessions[peripheral] else {
            Log.discovery.info("Peripheral without a session failed to connect, error=\(String(describing: error))")
            return
        }
        session.didFailToConnect(error: error)
    }

    /// When a peripheral is disconnected, notify the corresponding `Session`.
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard let session = sessions[peripheral] else {
            Log.discovery.info("Peripheral without a session disconnected, error=\(String(describing: error))")
            return
        }
        session.didDisconnect(error: error)
    }
}
