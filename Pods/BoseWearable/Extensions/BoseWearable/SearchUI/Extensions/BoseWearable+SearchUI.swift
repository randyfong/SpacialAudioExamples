//
//  BoseWearable+SearchUI.swift
//  BoseWearable/SearchUI
//
//  Created by Paul Calnan on 9/19/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

extension BoseWearable {

    /// The `startDeviceSearch(mode:completionHander:)` creates a `DeviceSearchTask` that must be retained. We retain it via `objc_setAssociatedObject()` and this is the key that we use for that association.
    static var taskKey = "DeviceSearchTaskKey"

    /**
     Begins searching for devices in the specified mode. A `UIViewController` may be modally presented on a newly-created `UIWindow` to present a list of discovered devices. The user can select a device from this list. The `mode` value passed allows for already-connected devices to be automatically selected.

     Once a device has been selected (either by the user or via automatic selection described above), a session is created. The session must be opened before being used.

     The result of the operation is passed to the specified completion handler. This will either indicate that the session was successfully created, that the operation failed with an error, or that the operation was cancelled by the user.

     - parameter mode: The mode of operation. See the documentation for `SearchUI.Mode` for more details.
     - parameter completionHandler: A callback that is invoked with the result of the operation.
     */
    public func startDeviceSearch(mode: DeviceSearchMode, completionHandler: @escaping (CancellableResult<WearableDeviceSession>) -> Void) {
        let task = DeviceSearchTask(bluetoothManager: bluetoothManager,
                                    mode: mode,
                                    userInterface: DeviceSearchUserInterfaceIOS(),
                                    completionHandler: completionHandler)
        task.start()

        // retain the task
        objc_setAssociatedObject(self, &BoseWearable.taskKey, task, .OBJC_ASSOCIATION_RETAIN)
    }
}
