//
//  Data+IntegerByteOrder.swift
//  BoseWearable
//
//  Created by Paul Calnan on 7/2/18.
//  Copyright © 2018 Bose. All rights reserved.
//

import Foundation

/// The byte order used when packing and unpacking integral values from a `Data` buffer.
enum ByteOrder {

    /// Big-endian byte order.
    case bigEndian

    /// Little-endian byte order.
    case littleEndian

    /// Converts a fixed-width integer from this byte order to the host byte order.
    func convert<T: FixedWidthInteger>(_ value: T) -> T {
        switch self {
        case .bigEndian:
            return T(bigEndian: value)

        case .littleEndian:
            return T(littleEndian: value)
        }
    }
}

extension Data {

    /// Returns a `Data` object starting at the specified index with the specified length. If the range indicated by `index` and `length` is invalid, returns nil.
    func subdata(at index: Int, length: Int) -> Data? {
        guard
            index >= 0, length >= 0,
            let si = self.index(startIndex, offsetBy: index, limitedBy: endIndex),
            let ei = self.index(startIndex, offsetBy: index + length, limitedBy: endIndex),
            si <= ei
        else {
            return nil
        }

        return subdata(in: Range(uncheckedBounds: (si, ei)))
    }

    /// Returns the fixed-width integer at the specified index converted from the specified byte order to the host byte order.
    func integer<T: FixedWidthInteger>(_ sourceByteOrder: ByteOrder, at index: Int) -> T? {
        let length = MemoryLayout<T>.size
        guard let data = subdata(at: index, length: length) else {
            return nil
        }

        let value: T = data.withUnsafeBytes { $0.pointee }
        return sourceByteOrder.convert(value)
    }

    /// Converts the specified fixed-width integer to a byte array in the specified byte order.
    static func data<T: FixedWidthInteger>(_ targetByteOrder: ByteOrder, for integer: T) -> Data {
        var value = targetByteOrder.convert(integer)
        return Data(bytes: &value, count: MemoryLayout.size(ofValue: value))
    }
}
