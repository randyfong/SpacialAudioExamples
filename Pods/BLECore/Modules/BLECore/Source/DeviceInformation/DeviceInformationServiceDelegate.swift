//
//  DeviceInformationServiceDelegate.swift
//  BLECore
//
//  Created by Paul Calnan on 10/29/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

/// A `DeviceInformationService` instance notifies its delegate whenever a characteristic value is read, updating the current `DeviceInformation`.
public protocol DeviceInformationServiceDelegate: class {

    /**
     Indicates that the specified `DeviceInformationService` instance has received new information (a characteristic value update).

     - parameter sender: the source `DeviceInformationService`
     - parameter info: the updated `DeviceInformation` object
     */
    func deviceInformationService(_ sender: DeviceInformationService, didUpdateDeviceInformation info: DeviceInformation)
}
