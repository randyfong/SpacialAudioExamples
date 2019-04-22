//
//  SensorSample.swift
//  BoseWearable
//
//  Created by Paul Calnan on 10/10/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation
import Logging

/// An individual sensor sample. An enum is used as different sensors have provide different data formats.
public enum SensorSample {

    /// An accelerometer sample, containing a vector value and an accuracy value.
    case accelerometer(value: Vector, accuracy: VectorAccuracy)

    /// A gyroscope sample, containing a vector value and an accuracy value.
    case gyroscope(value: Vector, accuracy: VectorAccuracy)

    /// A rotation sample, containing a quaternion value and an accuracy value.
    case rotation(value: Quaternion, accuracy: QuaternionAccuracy)

    /// A game rotation sample, containing a quaternion.
    case gameRotation(value: Quaternion)

    /// An orientation sample, containing a vector value and an accuracy value.
    case orientation(value: Vector, accuracy: VectorAccuracy)

    /// A magnetometer sample, containing a vector value and an accuracy value.
    case magnetometer(value: Vector, accuracy: VectorAccuracy)

    /// An uncalibrated magnetometer sample, containing a vector value and a bias value.
    case uncalibratedMagnetometer(value: Vector, bias: Vector)

    /// The vector value associated with this sample, or `nil` if this sample does not provide a vector value.
    public var vector: Vector? {
        switch self {
        case .accelerometer(let v, _),
             .gyroscope(let v, _),
             .orientation(let v, _),
             .magnetometer(let v, _),
             .uncalibratedMagnetometer(let v, _):
            return v

        default:
            return nil
        }
    }

    /// The vector accuracy value associated with this sample, or `nil` if this sample does not provide a vector accuracy value.
    public var vectorAccuracy: VectorAccuracy? {
        switch self {
        case .accelerometer(_, let a),
             .gyroscope(_, let a),
             .orientation(_, let a),
             .magnetometer(_, let a):
            return a

        default:
            return nil
        }
    }

    /// The quaternion value associated with this sample, or `nil` if this sample does not provide a quaternion value.
    public var quaternion: Quaternion? {
        switch self {
        case .rotation(let v, _),
             .gameRotation(let v):
            return v

        default:
            return nil
        }
    }

    /// The quaternion accuracy value associated with this sample, or `nil` if this sample does not provide a quaternion accuracy value.
    public var quaternionAccuracy: QuaternionAccuracy? {
        if case .rotation(_, let a) = self {
            return a
        }
        return nil
    }

    /// The bias value associated with this sample, or `nil` if this sample does not provide a bias value.
    public var bias: Vector? {
        if case .uncalibratedMagnetometer(_, let b) = self {
            return b
        }
        return nil
    }

    // MARK: - Parsing

    /// Parses a sample from the specified payload. Uses the scale function to convert from integral to floating-point values.
    static func parse(sensor: SensorType, payload: Data, scale: ScaleFunction) -> SensorSample? {
        let offset = 0

        switch sensor {
        case .accelerometer:
            guard let (value, accuracy) = parseVectorAndAccuracy(from: payload, offset: offset, scale: scale) else {
                return nil
            }
            return .accelerometer(value: value, accuracy: accuracy)

        case .gyroscope:
            guard let (value, accuracy) = parseVectorAndAccuracy(from: payload, offset: offset, scale: scale) else {
                return nil
            }
            return .gyroscope(value: value, accuracy: accuracy)

        case .rotation:
            guard let (value, accuracy) = parseQuaternionAndAccuracy(from: payload, offset: offset, scale: scale) else {
                return nil
            }
            return .rotation(value: value, accuracy: accuracy)

        case .gameRotation:
            guard let value = parseQuaternion(from: payload, offset: offset, scale: scale) else {
                return nil
            }
            return .gameRotation(value: value)

        case .orientation:
            guard let (value, accuracy) = parseVectorAndAccuracy(from: payload, offset: offset, scale: scale) else {
                return nil
            }
            return .orientation(value: value, accuracy: accuracy)

        case .magnetometer:
            guard let (value, accuracy) = parseVectorAndAccuracy(from: payload, offset: offset, scale: scale) else {
                return nil
            }
            return .magnetometer(value: value, accuracy: accuracy)

        case .uncalibratedMagnetometer:
            guard
                let value = parseVector(from: payload, offset: offset, scale: scale),
                let bias = parseVector(from: payload, offset: offset + vectorSize, scale: scale)
            else {
                return nil
            }
            return .uncalibratedMagnetometer(value: value, bias: bias)
        }
    }

    /// Payload size of a vector, in bytes.
    private static let vectorSize = 6

    /// Parses a vector from the specified data buffer at the specified offset. Scales the vector using the specified scale function.
    private static func parseVector(from data: Data, offset: Int, scale: ScaleFunction) -> Vector? {
        guard
            let x: Int16 = data.integer(.bigEndian, at: offset),
            let y: Int16 = data.integer(.bigEndian, at: offset + 2),
            let z: Int16 = data.integer(.bigEndian, at: offset + 4)
        else {
            return nil
        }

        let scaled = Vector(scale(x), scale(y), scale(z))
        Log.sensorData.debug("Received vector: (\(x), \(y), \(z)) -> \(scaled.debugDescription)")
        return scaled
    }

    /// Payload size of a vector and its accuracy, in bytes.
    private static let vectorAndAccuracySize = vectorSize + 1

    /// Parses a vector and accuracy value from the specified data buffer at the specified offset. Scales the vector using the specified scale function.
    private static func parseVectorAndAccuracy(from data: Data, offset: Int, scale: ScaleFunction) -> (Vector, VectorAccuracy)? {
        guard
            let v = parseVector(from: data, offset: offset, scale: scale),
            let a: UInt8 = data.integer(.bigEndian, at: offset + vectorSize),
            let accuracy = VectorAccuracy(rawValue: a)
        else {
            return nil
        }

        return (v, accuracy)
    }

    /// Payload size of a quaternion, in bytes.
    private static let quaternionSize = 8

    /// Parses a quaternion from the specified data buffer at the specified offset. Scales the vector using the specified scale function.
    private static func parseQuaternion(from data: Data, offset: Int, scale: ScaleFunction) -> Quaternion? {
        guard
            let x: Int16 = data.integer(.bigEndian, at: offset),
            let y: Int16 = data.integer(.bigEndian, at: offset + 2),
            let z: Int16 = data.integer(.bigEndian, at: offset + 4),
            let w: Int16 = data.integer(.bigEndian, at: offset + 6)
        else {
            return nil
        }

        let scaled = Quaternion(ix: scale(x), iy: scale(y), iz: scale(z), r: scale(w))
        Log.sensorData.debug("Received quaternion: (\(x), \(y), \(z), \(w)) -> \(scaled.debugDescription)")
        return scaled
    }

    /// Payload size of a quaternion and its accuracy, in bytes.
    private static let quaternionAndAccuracySize = quaternionSize + 2

    /// Parses a quaternion and accuracy value from the specified data buffer at the specified offset. Scales the vector using the specified scale function.
    private static func parseQuaternionAndAccuracy(from data: Data, offset: Int, scale: ScaleFunction) -> (Quaternion, QuaternionAccuracy)? {
        guard
            let q = parseQuaternion(from: data, offset: offset, scale: scale),
            let a: Int16 = data.integer(.bigEndian, at: offset + quaternionSize)
        else {
            return nil
        }
        return (q, QuaternionAccuracy(estimatedAccuracy: scale(a)))
    }
}

extension SensorSample: CustomDebugStringConvertible {
    public var debugDescription: String {

        /// Helper -- formats "label: value"
        func fmt(_ label: String, _ value: String?) -> String? {
            guard let value = value else {
                return nil
            }
            return "\(label): \(value)"
        }

        return "SensorSample: " + [
            fmt("vector", vector?.debugDescription),
            fmt("vectorAccuracy", vectorAccuracy?.description),
            fmt("quaternion", quaternion?.debugDescription),
            fmt("quaternionAccuracy", quaternionAccuracy?.estimatedAccuracy.description),
            fmt("bias", bias?.debugDescription)
        ].compactMap({ $0 }).joined(separator: ", ")
    }
}
