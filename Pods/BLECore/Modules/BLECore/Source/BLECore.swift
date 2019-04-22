//
//  BLECore.swift
//  BLECore
//
//  Created by Paul Calnan on 10/8/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

/// Contains static configuration variables for the `BLECore` library.
public final class BLECore {

    /// The bundle for the BLECore library. Useful for resolving resources and loading localized strings.
    static var bundle: Bundle {
        return Bundle(for: BLECore.self)
    }
}
