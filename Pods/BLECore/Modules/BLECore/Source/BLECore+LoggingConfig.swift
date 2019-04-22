//
//  BLECore+LoggingConfig.swift
//  BLECore
//
//  Created by Paul Calnan on 11/19/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation
import Logging

extension BLECore {

    /// Indicates whether device logging is enabled. Defaults to `false`.
    public static var isDeviceLoggingEnabled: Bool {
        get {
            return Log.device.isEnabled
        }

        set {
            Log.device.isEnabled = newValue
        }
    }

    /// Indicates whether device discovery logging is enabled. Defaults to `false`.
    public static var isDiscoveryLoggingEnabled: Bool {
        get {
            return Log.discovery.isEnabled
        }

        set {
            Log.discovery.isEnabled = newValue
        }
    }

    /// Indicates whether service logging is enabled. Defaults to `false`.
    public static var isServiceLoggingEnabled: Bool {
        get {
            return Log.service.isEnabled
        }

        set {
            Log.service.isEnabled = newValue
        }
    }

    /// Indicates whether session logging is enabled. Defaults to `false`.
    public static var isSessionLoggingEnabled: Bool {
        get {
            return Log.session.isEnabled
        }

        set {
            Log.session.isEnabled = newValue
        }
    }

    /// Indicates whether traffic logging is enabled. Defaults to `false`.
    public static var isTrafficLoggingEnabled: Bool {
        get {
            return Log.traffic.isEnabled
        }

        set {
            Log.traffic.isEnabled = newValue
        }
    }

    /// Enables all BLECore logging.
    public static func enableAllLogging() {
        setAllLogging(enabled: true)
    }

    /// Disables all BLECore logging.
    public static func disableAllLogging() {
        setAllLogging(enabled: false)
    }

    /// Enables commonly useful BLECore logging.
    public static func enableCommonLogging() {
        isDeviceLoggingEnabled = true
        isDiscoveryLoggingEnabled = false
        isServiceLoggingEnabled = true
        isSessionLoggingEnabled = true
        isTrafficLoggingEnabled = false
    }

    /// Bulk enable/disable all logging categories.
    private static func setAllLogging(enabled: Bool) {
        isDeviceLoggingEnabled = enabled
        isDiscoveryLoggingEnabled = enabled
        isServiceLoggingEnabled = enabled
        isSessionLoggingEnabled = enabled
        isTrafficLoggingEnabled = enabled
    }

}
