//
//  WearableSensorService.swift
//  BoseWearable
//
//  Created by Paul Calnan on 9/25/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import BLECore
import CoreBluetooth
import Foundation
import Logging

/**
 The Wearable Sensor Service provides information about a wearable device, as well as information, configuration, and data for the sensors and gesture detectors provided by the device.
 */
class WearableSensorService: Service {

    /// Service identification. UUID is FDD2.
    private struct Identification: ServiceIdentification {

        let identifier: CBUUIDConvertible = "FDD2"

        let requiredCharacteristics: [CBUUIDConvertible] = Characteristic.all

        let optionalCharacteristics: [CBUUIDConvertible] = []
    }

    static let identification: ServiceIdentification = Identification()

    /// Characteristics provided by this service.
    private enum Characteristic: String, CBUUIDConvertible {

        /// The wearable device information characteristic identifier.
        case wearableDeviceInformation = "7B61AD83-041C-4333-A0AB-EFB2AB7BDD43"

        /// The sensor information characteristic identifier.
        case sensorInformation = "855CB3E7-98FF-42A6-80FC-40B32A2221C1"

        /// The sensor configuration characteristic identifier.
        case sensorConfiguration = "5AF38AF6-000E-404B-9B46-07F77580890B"

        /// The sensor data characteristic identifier.
        case sensorData = "56A72AB8-4988-4CC8-A752-FBD1D54A953D"

        /// The gesture information characteristic identifier.
        case gestureInformation = "A0384F52-F95A-4BCD-B898-7B9CEEC92DAD"

        /// The gesture configuration characteristic identifier.
        case gestureConfiguration = "21E550AF-F780-477B-9334-1F983296F1D7"

        /// The gesture data characteristic identifier.
        case gestureData = "9014DD4E-79BA-4802-A275-894D3B85AC74"

        /// An array of all defined characteristic identifiers.
        static let all: [Characteristic] = [
            .wearableDeviceInformation,
            .sensorInformation,
            .sensorConfiguration,
            .sensorData,
            .gestureInformation,
            .gestureConfiguration,
            .gestureData
        ]

        var asUUID: CBUUID {
            return rawValue.asUUID
        }

        /// An array of characteristics that are notifying. We set the notify value to true for these characteristics (others are not notifying characteristics).
        fileprivate static let notifying: [Characteristic] = [
            .wearableDeviceInformation,
            .sensorConfiguration,
            .sensorData,
            .gestureConfiguration,
            .gestureData
        ]
    }

    /// Notified when various events occur.
    weak var delegate: WearableSensorServiceDelegate?

    /// The sensor metadata used for guidance when parsing sensor data.
    private var sensorMetadata: SensorMetadata?

    /// The gesture metadata used for guidance when parsing gesture configuration.
    private var gestureMetadata: GestureMetadata?

    let service: CBService

    required init(service: CBService) {
        self.service = service

        Characteristic.notifying.forEach {
            setNotifyValue(true, for: $0)
        }
    }

    /// Refreshes all of the characteristics except sensor and gesture data.
    func refreshAll() {
        refreshWearableDeviceInformation()
        refreshSensorInformation()
        refreshGestureInformation()
        refreshSensorConfiguration()
        refreshGestureConfiguration()
    }

    /// Refreshes the wearable device information characteristic.
    func refreshWearableDeviceInformation() {
        readValue(for: Characteristic.wearableDeviceInformation)
    }

    /// Refreshes the sensor information characteristic.
    func refreshSensorInformation() {
        readValue(for: Characteristic.sensorInformation)
    }

    /// Refreshes the sensor configuration characteristic.
    func refreshSensorConfiguration() {
        readValue(for: Characteristic.sensorConfiguration)
    }

    /// Refreshes the gesture information characteristic.
    func refreshGestureInformation() {
        readValue(for: Characteristic.gestureInformation)
    }

    /// Refreshes the gesture configuration characteristic.
    func refreshGestureConfiguration() {
        readValue(for: Characteristic.gestureConfiguration)
    }

    /// Writes the specified sensor configuration.
    func write(sensorConfiguration: SensorConfiguration) {
        let data = sensorConfiguration.data
        Log.service.info("Writing \(data.hexString) for sensor configuration \(Characteristic.sensorConfiguration)")
        writeValue(data, for: Characteristic.sensorConfiguration, type: .withResponse)
    }

    /// Writes the specified gesture configuration.
    func write(gestureConfiguration: GestureConfiguration) {
        let data = gestureConfiguration.data
        Log.service.info("Writing \(data.hexString) for gesture configuration \(Characteristic.gestureConfiguration)")
        writeValue(data, for: Characteristic.gestureConfiguration, type: .withResponse)
    }

    /// Convenience function allowing querying values by `Characteristic`.
    private func value(for characteristic: Characteristic) -> Data? {
        return value(for: characteristic as CBUUIDConvertible)
    }

    /// The current value for the wearable device information characteristic.
    private var wearableDeviceInformationData: Data? {
        return value(for: .wearableDeviceInformation)
    }

    /// The current value of the sensor information characteristic.
    private var sensorInformationData: Data? {
        return value(for: .sensorInformation)
    }

    /// The current value of the sensor configuration characteristic.
    private var sensorConfigurationData: Data? {
        return value(for: .sensorConfiguration)
    }

    /// The current value of the sensor data characteristic.
    private var sensorData: Data? {
        return value(for: .sensorData)
    }

    /// The current value of the gesture information characteristic.
    private var gestureInformationData: Data? {
        return value(for: .gestureInformation)
    }

    /// The current value of the gesture configuration characteristic.
    private var gestureConfigurationData: Data? {
        return value(for: .gestureConfiguration)
    }

    /// The current value of the gesture data characteristic.
    private var gestureData: Data? {
        return value(for: .gestureData)
    }

    func didUpdateValue(forCharacteristic uuid: CBUUID, error: Error?) {
        if let error = error {
            Log.service.error("Error updating value: \(error)")
            return
        }

        switch uuid {
        case Characteristic.wearableDeviceInformation.asUUID:
            guard let value = WearableDeviceInformation(payload: wearableDeviceInformationData) else {
                Log.service.error("Unable to parse incoming device information: \(wearableDeviceInformationData?.hexString ?? "nil")")
                return
            }
            Log.service.debug("Received device information: \(value)")
            delegate?.service(self, didReceiveWearableDeviceInformation: value)

        case Characteristic.sensorInformation.asUUID:
            guard let value = SensorInformation(payload: sensorInformationData) else {
                Log.service.error("Unable to parse incoming sensor information: \(sensorInformationData?.hexString ?? "nil")")
                return
            }
            Log.service.debug("Received sensor information: \(value)")
            sensorMetadata = value
            delegate?.service(self, didReceiveSensorInformation: value)

        case Characteristic.sensorConfiguration.asUUID:
            guard let value = SensorConfiguration(payload: sensorConfigurationData) else {
                Log.service.error("Unable to parse incoming sensor configuration: \(sensorConfigurationData?.hexString ?? "nil")")
                return
            }
            Log.service.debug("Received sensor configuration: \(value)")
            delegate?.service(self, didReceiveSensorConfiguration: value)

        case Characteristic.sensorData.asUUID:
            guard let metadata = sensorMetadata else {
                Log.service.error("Received sensor data without previously receiving valid sensor information -- gesture data will be dropped")
                return
            }
            guard let value = SensorData(payload: sensorData, metadata: metadata) else {
                Log.service.error("Unable to parse incoming sensor data")
                return
            }
            Log.sensorData.debug("Received sensor data: \(value.debugDescription)")
            delegate?.service(self, didReceiveSensorData: value)

        case Characteristic.gestureInformation.asUUID:
            guard let value = GestureInformation(payload: gestureInformationData) else {
                Log.service.error("Unable to parse incoming gesture information: \(gestureInformationData?.hexString ?? "nil")")
                return
            }
            Log.service.debug("Received gesture information: \(value.debugDescription)")
            gestureMetadata = value
            delegate?.service(self, didReceiveGestureInformation: value)

        case Characteristic.gestureConfiguration.asUUID:
            guard let metadata = gestureMetadata else {
                Log.service.error("Received gesture configuration without previously receiving valid gesture information -- gesture configuration will be dropped")
                return
            }
            guard let value = GestureConfiguration(payload: gestureConfigurationData, metadata: metadata) else {
                Log.service.error("Unable to parse incoming gesture configuration: \(gestureConfigurationData?.hexString ?? "nil")")
                return
            }
            Log.service.debug("Received configuration data: \(value.debugDescription)")
            delegate?.service(self, didReceiveGestureConfiguration: value)

        case Characteristic.gestureData.asUUID:
            guard let value = GestureData(payload: gestureData) else {
                Log.service.error("Unable to parse incoming gesture data: \(gestureData?.hexString ?? "nil")")
                return
            }
            Log.sensorData.debug("Received gesture data: \(value.debugDescription)")
            delegate?.service(self, didReceiveGestureData: value)

        default:
            Log.service.info("Unknown characteristic updated value: \(uuid)")
        }
    }

    func didUpdateNotificationState(forCharacteristic uuid: CBUUID, error: Error?) {
        if let error = error {
            Log.service.error("Error updating notification state for characteristic \(uuid): \(error)")
        }
        else {
            Log.service.debug("Updated notification state for characteristic \(uuid)")
        }
    }

    func didWriteValue(forCharacteristic uuid: CBUUID, error: Error?) {
        switch uuid {
        case Characteristic.sensorConfiguration.asUUID:
            if let error = error {
                self.delegate?.service(self, didFailToWriteSensorConfiguration: BoseWearableError.from(error))
            }
            else {
                if let value = SensorConfiguration(payload: sensorConfigurationData) {
                    self.delegate?.service(self, didWriteSensorConfiguration: value)
                }
                else {
                    self.delegate?.service(self, didFailToWriteSensorConfiguration: BoseWearableError.invalidResponse)
                }
            }

        case Characteristic.gestureConfiguration.asUUID:
            if let error = error {
                self.delegate?.service(self, didFailToWriteGestureConfiguration: BoseWearableError.from(error))
            }
            else {
                guard let metadata = gestureMetadata else {
                    self.delegate?.service(self, didFailToWriteGestureConfiguration: BoseWearableError.missingGestureInformation)
                    return
                }

                if let value = GestureConfiguration(payload: gestureConfigurationData, metadata: metadata) {
                    self.delegate?.service(self, didWriteGestureConfiguration: value)
                }
                else {
                    self.delegate?.service(self, didFailToWriteGestureConfiguration: BoseWearableError.invalidResponse)
                }
            }

        default:
            Log.service.info("Unknown characteristic wrote value: \(uuid)")
        }
    }
}
