//
//  BoseWearable+LoggingConfig.swift
//  BoseWearable
//
//  Created by Paul Calnan on 11/19/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import BLECore
import Foundation
import Logging

extension BoseWearable {

    /// If `true`, enables logging of device-level events. Default is `false`.
    public static var isDeviceLoggingEnabled: Bool {
        get {
            return Log.device.isEnabled
        }

        set {
            Log.device.isEnabled = newValue
        }
    }

    /// If `true`, enabled logging of sensor data. Default is `false`.
    public static var isSensorDataLoggingEnabled: Bool {
        get {
            return Log.sensorData.isEnabled
        }

        set {
            Log.sensorData.isEnabled = newValue
        }
    }

    /// If `true`, enables logging of sensor events. Default is `false`.
    public static var isSensorLoggingEnabled: Bool {
        get {
            return Log.sensor.isEnabled
        }

        set {
            Log.sensor.isEnabled = newValue
        }
    }

    /// If `true`, enables logging of service-level events. Default is `false`.
    public static var isServiceLoggingEnabled: Bool {
        get {
            return Log.service.isEnabled
        }

        set {
            Log.service.isEnabled = newValue
        }
    }

    /// If `true`, enables logging of session-level events. Default is `false`.
    public static var isSessionLoggingEnabled: Bool {
        get {
            return Log.session.isEnabled
        }

        set {
            Log.session.isEnabled = newValue
        }
    }

    /// Enables all BoseWearable logging.
    public static func enableAllLogging() {
        setAllLogging(enabled: true)
    }

    /// Disables all BoseWearable logging.
    public static func disableAllLogging() {
        setAllLogging(enabled: false)
    }

    /// Enables commonly useful BoseWearable logging.
    public static func enableCommonLogging() {
        isDeviceLoggingEnabled = true
        isSensorDataLoggingEnabled = false
        isSensorLoggingEnabled = true
        isServiceLoggingEnabled = true
        isSessionLoggingEnabled = true
    }

    /// Bulk enable/disable all logging categories.
    private static func setAllLogging(enabled: Bool) {
        isDeviceLoggingEnabled = enabled
        isSensorDataLoggingEnabled = enabled
        isSensorLoggingEnabled = enabled
        isServiceLoggingEnabled = enabled
        isSessionLoggingEnabled = enabled
    }
}
