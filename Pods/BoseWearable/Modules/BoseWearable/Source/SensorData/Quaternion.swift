//
//  Quaternion.swift
//  BoseWearable
//
//  Created by Paul Calnan on 8/17/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation
import simd

/// A data type representing a quaternion.
public typealias Quaternion = simd_quatd

extension Quaternion {

    /// The value for the w axis.
    public var w: Double {
        return real
    }

    /// The value for the x axis.
    public var x: Double {
        return imag.x
    }

    /// The value for the y axis.
    public var y: Double {
        return imag.y
    }

    /// The value for the z axis.
    public var z: Double {
        return imag.z
    }

    /// Convert from double-precision floating-point values to single-precision floating-point values.
    public var quatf: simd_quatf {
        return simd_quatf(ix: Float(imag.x), iy: Float(imag.y), iz: Float(imag.z), r: Float(real))
    }

    /// The pitch of the device, in radians.
    public var pitch: Double {
        let sinp = 2 * (w * x + y * z)
        let cosp = 1 - 2 * (x * x + y * y)

        // The horizon is around -π or π (where the values wrap around).

        // We want to make the horizon 0, so first add π.
        let pitch = atan2(sinp, cosp) + Double.pi

        // Normalize the angle to be between -π and π.
        return pitch > Double.pi ? pitch - 2 * Double.pi : pitch
    }

    /// The roll of the device, in radians.
    public var roll: Double {
        let sinr = 2 * (w * y - z * x)
        if fabs(sinr) >= 1 {
            return -copysign(Double.pi / 2, sinr)
        }
        else {
            return -asin(sinr)
        }
    }

    /// The yaw of the device, in radians.
    public var yaw: Double {
        let siny = 2 * (w * z + x * y)
        let cosy = 1 - 2 * (y * y + z * z)

        return -atan2(siny, cosy)
    }
}

extension Quaternion { // : CustomDebugStringConvertible

    /// A textual description of the quaternion suitable for debugging.
    public var debugDescription: String {
        return "Quaternion(x: \(x), y: \(y), z: \(z), w: \(w))"
    }
}
