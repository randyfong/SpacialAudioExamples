//
//  Vector.swift
//  BoseWearable
//
//  Created by Paul Calnan on 8/17/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation
import simd

/// A data type representing a 3-dimensional vector.
public typealias Vector = simd_double3

extension Vector {

    /// Convert from double-precision floating-point values to single-precision floating-point values.
    public var float3: simd_float3 {
        return simd_float3(Float(x), Float(y), Float(z))
    }
}
