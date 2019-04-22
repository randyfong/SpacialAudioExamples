//
//  Service.swift
//  BLECore
//
//  Created by Paul Calnan on 8/28/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import CoreBluetooth
import Foundation
import Logging

/**
 Encapsulates a device's service. Provides a wrapper around `CBService` with convenience functions for accessing the characteristics associated with this service.

 Applications should provide types implementing the `Service` protocol for each of the services used by the application. See the `DeviceInformationService` type in `BLECore` for an example of how a `Service` can be implemented.
 */
public protocol Service {

    /// Used to identify services on discovered devices during the device connection process.
    static var identification: ServiceIdentification { get }

    /// The underlying service object.
    var service: CBService { get }

    /// Creates a new service instance backed by the specified `CBService` object.
    init(service: CBService)

    /**
     Invoked when you retrieve a specified characteristic's value, or when the peripheral device notifies your app that the characteristic's value has changed.

     - parameter uuid: the UUID of the characteristic whose value has been retrieved or updated
     - parameter error: if an error occurred, the cause of the failure
     */
    func didUpdateValue(forCharacteristic uuid: CBUUID, error: Error?)

    /**
     Invoked when the peripheral receives a request to start or stop providing notifications for a specified characteristic's value. This method is invoked when your app calls `Service.setNotifyValue(_:for:)`. If successful, the `error` parameter is `nil`. If unsuccessful, the `error` parameter indicates the cause of the failure.

     - parameter uuid: the UUID of the characteristic for which notifications of its value are to be configured
     - parameter error: if an error occurred, the cause of the failure
     */
    func didUpdateNotificationState(forCharacteristic uuid: CBUUID, error: Error?)

    /**
     Invoked when you write data to a characteristic's value. This method is invoked only when your app calls `Service.writeValue(_:for:type:)` with the `.withResponse` constant specified as the write type. If successful, the `error` parameter is `nil`. If unsuccessful, the `error` parameter indicates the cause of the failure.

     - parameter uuid: the UUID of the characteristic whose value has been written
     - parameter error: if an error occurred, the cause of the failure
     */
    func didWriteValue(forCharacteristic uuid: CBUUID, error: Error?)
}

// MARK: - Default implementations

extension Service {

    /// The default implementation of this function does nothing.
    public func didUpdateValue(forCharacteristic uuid: CBUUID, error: Error?) { }

    /// The default implementation of this function does nothing.
    public func didUpdateNotificationState(forCharacteristic uuid: CBUUID, error: Error?) { }

    /// The default implementation of this function does nothing.
    public func didWriteValue(forCharacteristic uuid: CBUUID, error: Error?) { }
}

// MARK: - Characteristics

extension Service {

    /**
     Returns the first characteristic with the specified UUID, or `nil` if one cannot be found.

     - parameter uuid: the characteristic UUID
     - returns: the first characteristic provided by the service with the specified UUID
     */
    public func characteristic(for uuid: CBUUIDConvertible) -> CBCharacteristic? {
        return service.characteristics?.first(where: { $0.uuid == uuid.asUUID })
    }

    /**
     Returns the value for the characteristic with the specified UUID. Returns `nil` if no such characteristic can be found or if no value is present.

     - parameter uuid: the characteristic UUID
     - returns: the value for the characteristic with the specified UUID
     */
    public func value(for uuid: CBUUIDConvertible) -> Data? {
        return characteristic(for: uuid.asUUID)?.value
    }

    /**
     Retrieves the value of the specified characteristic. When you call this method to read the value of a characteristic, `Service.didUpdateValue(forCharacteristic:error:)` is called, indicating whether the read was successful. If the value of the characteristic was successfully retrieved, you can access it via `Service.value(for:)`.

     Note that if the specified UUID does not correspond to a characteristic on this service (i.e., `Service.characteristic(for:)` returns `nil`), no action is taken and this function returns immediately.

     - parameter uuid: the characteristic UUID
     */
    public func readValue(for uuid: CBUUIDConvertible) {
        guard let c = characteristic(for: uuid.asUUID) else {
            Log.service.error("Service.readValue: could not find characteristic for \(uuid)")
            return
        }
        service.peripheral.readValue(for: c)
    }

    /**
     Writes the specified value of the specified characteristic. When you call this method to write the value of a characteristic, `Service.didWriteValue(forCharacteristic:error:)` is called only if you specified he write type as `.withResponse`. The response you receive through `Service.didWriteValue(forCharacteristic:error:)` indicates whether the write was successful; if the write failed, it details the cause of the failure in an error.

     If you specify the write `type` as `.withoutResponse`, the write is best-effort and not guaranteed. If the write does not succeed in this case, you are not notified nor do you receive an error indicating the cause of the failure.

     Note that if the specified UUID does not correspond to a characteristic on this service (i.e., `Service.characteristic(for:)` returns `nil`), no action is taken and this function returns immediately.

     - parameter value: the value to write to the specified characteristic
     - parameter uuid: the UUID of the characteristic being updated
     - parameter type: the type of write to be executed
     */
    public func writeValue(_ value: Data, for uuid: CBUUIDConvertible, type: CBCharacteristicWriteType) {
        guard let c = characteristic(for: uuid.asUUID) else {
            Log.service.error("Service.writeValue: could not find characteristic for \(uuid)")
            return
        }
        service.peripheral.writeValue(value, for: c, type: type)
    }

    /**
     Sets notifications or indications for the value of the specified characteristic.

     When you enable notifications for the characteristic's value, `Service.didUpdateNotificationState(forCharacteristic:error:)` is called, indicating whether or not the action succeeded. If successful, `Service.didUpdateValue(forCharacteristic:error:)` is then called whenever the characteristic value changes.

     Note that if the specified UUID does not correspond to a characteristic on this service (i.e., `Service.characteristic(for:)` returns `nil`), no action is taken and this function returns immediately.

     - parameter enabled: indicates whether you want to receive notifications when the characteristic's value changes
     - parameter uuid: the UUID of the characteristic
     */
    public func setNotifyValue(_ enabled: Bool, for uuid: CBUUIDConvertible) {
        guard let c = characteristic(for: uuid.asUUID) else {
            return
        }
        service.peripheral.setNotifyValue(enabled, for: c)
    }
}

// MARK: - Data Conversion {

extension Service {

    /// Convenience function to convert a `Data` object to a string using the specified encoding (defaulting to `.utf8`).
    public func string(from data: Data?, encoding: String.Encoding = .utf8) -> String? {
        guard let d = data else {
            return nil
        }
        return String(data: d, encoding: .utf8)
    }
}
