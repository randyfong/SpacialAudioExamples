//
//  Result.swift
//  BoseWearable
//
//  Created by Paul Calnan on 8/13/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

// Based loosely on Alamofire.Result
// https://github.com/Alamofire/Alamofire/blob/master/Source/Result.swift

/// Used to represent whether an operation was successful or encountered an error.
public enum Result<Value> {

    /// The operation was successful, returning the associated value.
    case success(Value)

    /// The operation failed, with the associated value causing the failure.
    case failure(Error)

    /// Returns `true` if the result is a success, `false` otherwise.
    public var isSuccess: Bool {
        if case .success(_) = self {
            return true
        }

        return false
    }

    /// Returns `true` if the result is a failure, `false` otherwise.
    public var isFailure: Bool {
        return !isSuccess
    }

    /// Returns the associated value if the result is a success, `nil` otherwise.
    public var value: Value? {
        if case .success(let value) = self {
            return value
        }

        return nil
    }

    /// Returns the associated error value if the result is a failure, `nil` otherwise.
    public var error: Error? {
        if case .failure(let error) = self {
            return error
        }

        return nil
    }
}
