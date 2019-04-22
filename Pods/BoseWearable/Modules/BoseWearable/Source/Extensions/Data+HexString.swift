//
//  Data+HexString.swift
//  BoseWearable
//
//  Created by Paul Calnan on 10/8/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

extension Data {
    /// Converts the byte sequence of this Data object into a hexadecimal representation (two lowercase characters per byte).
    var hexString: String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
