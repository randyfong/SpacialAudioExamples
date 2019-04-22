//
//  SimulatedWearableDeviceSession.swift
//  BoseWearable
//
//  Created by Paul Calnan on 10/18/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

/// Represents a wearable device session with a simulated wearable device.
class SimulatedWearableDeviceSession: WearableDeviceSession {

    let device: WearableDevice?

    /// Creates a new session with the specified device.
    init(device: SimulatedWearableDevice) {
        self.device = device
    }

    weak var delegate: WearableDeviceSessionDelegate?

    func open() {
        DispatchQueue.main.async {
            self.delegate?.sessionDidOpen(self)
        }
    }

    func close() {
        DispatchQueue.main.async {
            self.delegate?.session(self, didCloseWithError: nil)
        }
    }
}
