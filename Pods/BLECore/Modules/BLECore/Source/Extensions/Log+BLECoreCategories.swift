//
//  Log+BLECoreSubsystem.swift
//  BLECore
//
//  Created by Paul Calnan on 9/19/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation
import Logging

extension Log {

    /// The log subsystem for BLECore.
    private static let subsystem = "com.bose.ar.BLECore"

    /// Category for session-related log messages.
    static let session = Log(subsystem: subsystem, category: "session", isEnabled: false)

    /// Category for discovery-related log messages.
    static let discovery = Log(subsystem: subsystem, category: "discovery", isEnabled: false)

    /// Category for traffic-related log messages.
    static let traffic = Log(subsystem: subsystem, category: "traffic", isEnabled: false)

    /// Category for device-related log messages.
    static let device = Log(subsystem: subsystem, category: "device", isEnabled: false)

    /// Category for service-related log messages.
    static let service = Log(subsystem: subsystem, category: "service", isEnabled: false)
}
