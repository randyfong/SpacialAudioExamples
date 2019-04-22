//
//  SignalStrength.swift
//  BoseWearable
//
//  Created by Paul Calnan on 11/6/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

/// Indicates the observed signal strength of a device suitable for display in the user interface.
public enum SignalStrength {

    /// Weak signal (level one out of four)
    case weak

    /// Moderate signal (level two out of four)
    case moderate

    /// Strong signal (level three out of four)
    case strong

    /// Full signal (level four out of four)
    case full

    /// Convert from an RSSI value to a SignalStrength. Returns nil if the value is too low.
    static func fromRSSI(_ value: Int) -> SignalStrength? {
        if value > -35 {
            return .full
        }
        else if value > -45 {
            return .strong
        }
        else if value > -55 {
            return .moderate
        }
        else if value > -70 {
            return .weak
        }
        else {
            return nil
        }
    }
}
