//
//  SensorTimestamp.swift
//  BoseWearable
//
//  Created by Paul Calnan on 8/17/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

/// Indicates a timestamp, in milliseconds, associated with a sensor reading or gesture event. As this is an unsigned 16-bit value, a timestamp will roll over every 65.536 seconds.
public typealias SensorTimestamp = UInt16
