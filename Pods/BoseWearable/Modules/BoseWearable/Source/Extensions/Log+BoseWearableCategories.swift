//
//  Log+BoseWearableSubsystem.swift
//  BoseWearable
//
//  Created by Paul Calnan on 10/8/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation
import Logging

extension Log {

    /// The log subsystem for BoseWearable.
    private static let subsystem = "com.bose.ar.BoseWearable"

    /// Category for session-related log messages.
    static let session = Log(subsystem: subsystem, category: "session", isEnabled: false)

    /// Category for service-related log messages.
    static let service = Log(subsystem: subsystem, category: "service", isEnabled: false)

    /// Category for device-related log messages.
    static let device = Log(subsystem: subsystem, category: "device", isEnabled: false)

    /// Category for sensor-related log messages. This excludes sensor data.
    static let sensor = Log(subsystem: subsystem, category: "sensor", isEnabled: false)

    /// Category for sensor data log messages. This category is very verbose and should be disabled in release configurations.
    static let sensorData = Log(subsystem: subsystem, category: "sensorData", isEnabled: false)
}
