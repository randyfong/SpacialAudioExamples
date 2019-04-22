//
//  BoseWearableDevice.swift
//  BoseWearable
//
//  Created by Paul Calnan on 9/25/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import BLECore
import CoreBluetooth
import Foundation
import Logging

/// Represents a default Bose wearable device that provides the `WearableSensorService`.
class BoseWearableDevice: WearableDevice, Device {

    let services: ServiceSet

    required init(peripheral: CBPeripheral, services: ServiceSet) throws {
        self.peripheral = peripheral
        self.services = services

        self.deviceInformationService = try services.service(for: DeviceInformationService.self)
        self.wearableSensorService = try services.service(for: WearableSensorService.self)

        deviceInformationService.delegate = self
        deviceInformationService.refresh()

        wearableSensorService.delegate = self

        // NOTE: Receiving responses in a different order than they were requested will cause data to be dropped:
        // - gestureConfiguration received before gestureInformation drops gestureConfiguration
        // - sensorData received before sensorInformation drops sensorData
        //
        // If this occurs, deviceIsReady() will not return true and the connection will fail.
        // We will need to use a state machine to make these requests and their responses arrive serially.
        wearableSensorService.refreshAll()
    }

    // MARK: - BLECore

    /**
     Device identification

     Required service: FDD2
     */
    private struct Identification: DeviceIdentification {

        // A BoseWearableDevice must provide the Bose Wearable Sensor service.
        let requiredAdvertisedServiceUUIDs: Set<CBUUID> = Set([
            WearableSensorService.identification.identifier.asUUID
        ])

        let forbiddenAdvertisedServiceUUIDs: Set<CBUUID> = []

        let requiredServices: [ServiceIdentification] = [
            DeviceInformationService.identification,
            WearableSensorService.identification
        ]

        func advertisementFilter(peripheral: CBPeripheral, advertisementData: [String: Any]) -> Bool {
            return true
        }
    }

    static let identification: DeviceIdentification = Identification()

    let peripheral: CBPeripheral

    // MARK: - Device Information

    var name: String? {
        return peripheral.name
    }

    /// The device information service.
    private let deviceInformationService: DeviceInformationService

    private(set) var deviceInformation: DeviceInformation?

    func refreshDeviceInformation() {
        deviceInformationService.refresh()
    }

    // MARK: - Wearable Device Information

    /// The wearable sensor service.
    private let wearableSensorService: WearableSensorService

    private(set) var wearableDeviceInformation: WearableDeviceInformation?

    func refreshWearableDeviceInformation() {
        wearableSensorService.refreshWearableDeviceInformation()
    }

    // MARK: - Sensor Information

    private(set) var sensorInformation: SensorInformation? {
        didSet {
            Log.device.info("Received sensor information: \(sensorInformation?.debugDescription ?? "nil")")
        }
    }

    func refreshSensorInformation() {
        wearableSensorService.refreshSensorInformation()
    }

    // MARK: - Sensor Configuration

    private(set) var sensorConfiguration: SensorConfiguration? {
        didSet {
            Log.device.info("Received sensor configuration: \(sensorConfiguration?.debugDescription ?? "nil")")
        }
    }

    func refreshSensorConfiguration() {
        wearableSensorService.refreshSensorConfiguration()
    }

    func changeSensorConfiguration(_ newConfiguration: SensorConfiguration) {
        Log.device.info("Writing sensor configuration: \(newConfiguration.debugDescription)")
        wearableSensorService.write(sensorConfiguration: newConfiguration)
    }

    // MARK: - Gesture Information

    private(set) var gestureInformation: GestureInformation? {
        didSet {
            Log.device.info("Received gesture information: \(gestureInformation?.debugDescription ?? "nil")")
        }
    }

    func refreshGestureInformation() {
         wearableSensorService.refreshGestureInformation()
    }

    // MARK: - Gesture Configuration

    private(set) var gestureConfiguration: GestureConfiguration? {
        didSet {
            Log.device.info("Received gesture configuration: \(gestureConfiguration?.debugDescription ?? "nil")")
        }
    }

    func refreshGestureConfiguration() {
        wearableSensorService.refreshGestureConfiguration()
    }

    func changeGestureConfiguration(_ newConfiguration: GestureConfiguration) {
        Log.device.info("Writing gesture configuration: \(newConfiguration.debugDescription)")
        wearableSensorService.write(gestureConfiguration: newConfiguration)
    }

    // MARK: - Startup information

    func deviceIsReady() throws -> Bool {
        let deviceInfo = deviceInformation != nil
        let wearableDeviceInfo = wearableDeviceInformation != nil
        let sensorInfo = sensorInformation != nil
        let sensorConfig = sensorConfiguration != nil
        let gestureInfo = gestureInformation != nil
        let gestureConfig = gestureConfiguration != nil

        Log.device.info("Startup information received: deviceInfo=\(deviceInfo) wearableDeviceInfo=\(wearableDeviceInfo) " +
            "sensorInfo=\(sensorInfo) sensorConfig=\(sensorConfig) gestureConfig=\(gestureConfig)")

        let flags = [
            deviceInfo,
            wearableDeviceInfo,
            sensorInfo,
            sensorConfig,
            gestureInfo,
            gestureConfig
        ]

        let result = flags.reduce(true, { $0 && $1 })
        Log.device.info(result ? "Startup complete" : "Startup not yet complete")
        return result
    }
}

// MARK: - DeviceInformationServiceDelegate

extension BoseWearableDevice: DeviceInformationServiceDelegate {

    func deviceInformationService(_ sender: DeviceInformationService, didUpdateDeviceInformation value: DeviceInformation) {
        deviceInformation = value
        NotificationCenter.default.post(WearableDeviceEvent.didUpdateDeviceInformation(value), from: self)
    }
}

// MARK: - WearableSensorServiceDelegate

extension BoseWearableDevice: WearableSensorServiceDelegate {

    func service(_ sender: WearableSensorService, didReceiveWearableDeviceInformation info: WearableDeviceInformation) {
        wearableDeviceInformation = info
        NotificationCenter.default.post(WearableDeviceEvent.didUpdateWearableDeviceInformation(info), from: self)
    }

    func service(_ sender: WearableSensorService, didReceiveSensorInformation info: SensorInformation) {
        sensorInformation = info
        NotificationCenter.default.post(WearableDeviceEvent.didUpdateSensorInformation(info), from: self)
    }

    func service(_ sender: WearableSensorService, didReceiveSensorConfiguration config: SensorConfiguration) {
        sensorConfiguration = config
        NotificationCenter.default.post(WearableDeviceEvent.didUpdateSensorConfiguration(config), from: self)
    }

    func service(_ sender: WearableSensorService, didWriteSensorConfiguration config: SensorConfiguration) {
        sensorConfiguration = config
        NotificationCenter.default.post(WearableDeviceEvent.didUpdateSensorConfiguration(config), from: self)
    }

    func service(_ sender: WearableSensorService, didFailToWriteSensorConfiguration error: Error) {
        NotificationCenter.default.post(WearableDeviceEvent.didFailToWriteSensorConfiguration(error), from: self)
    }

    func service(_ sender: WearableSensorService, didReceiveSensorData data: SensorData) {
        NotificationCenter.default.post(WearableDeviceEvent.didReceiveSensorData(data), from: self)
    }

    func service(_ sender: WearableSensorService, didReceiveGestureConfiguration config: GestureConfiguration) {
        gestureConfiguration = config
        NotificationCenter.default.post(WearableDeviceEvent.didUpdateGestureConfiguration(config), from: self)
    }

    func service(_ sender: WearableSensorService, didReceiveGestureInformation info: GestureInformation) {
        gestureInformation = info
        NotificationCenter.default.post(WearableDeviceEvent.didUpdateGestureInformation(info), from: self)
    }

    func service(_ sender: WearableSensorService, didWriteGestureConfiguration config: GestureConfiguration) {
        gestureConfiguration = config
        NotificationCenter.default.post(WearableDeviceEvent.didUpdateGestureConfiguration(config), from: self)
    }

    func service(_ sender: WearableSensorService, didFailToWriteGestureConfiguration error: Error) {
        NotificationCenter.default.post(WearableDeviceEvent.didFailToWriteGestureConfiguration(error), from: self)
    }

    func service(_ sender: WearableSensorService, didReceiveGestureData data: GestureData) {
        NotificationCenter.default.post(WearableDeviceEvent.didReceiveGestureData(data), from: self)
    }
}
