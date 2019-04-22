//
//  ScaleFunction.swift
//  BoseWearable
//
//  Created by Paul Calnan on 11/8/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

/// Type-alias for a scaling function used to convert from integral to floating-point sensor values.
typealias ScaleFunction = (Int16) -> Double

/// An identity function that performs no scaling but simply converts from `Int16` to `Double`.
let IdentityScaling: ScaleFunction = { Double($0) }
