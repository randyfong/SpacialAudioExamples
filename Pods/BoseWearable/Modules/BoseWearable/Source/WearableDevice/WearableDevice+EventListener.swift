//
//  WearableDevice+EventListener.swift
//  BoseWearable
//
//  Created by Paul Calnan on 10/25/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import BLECore
import Foundation

/*
 Implementation Note
 -------------------

 The functionality in this file allows SDK clients to use TypedNotifications
 without having to import BLECore.
 */

extension WearableDevice {

    /// Callback type that receives a `WearableDeviceEvent`.
    public typealias WearableDeviceEventHandler = (WearableDeviceEvent) -> Void

    /**
     Registers a handler block to be executed on the specified queue whenever a `WearableDeviceEvent` is posted from this `WearableDevice` object.

     Note that the returned `ListenerToken` must be retained. Once it is deallocated, the listener is deregistered.

     If the closure passed to this function references `self`, you must add `[weak self]` to the closure's capture list. Failing to do so will result in a retain cycle and leaked memory.

     - parameter queue: The queue on which to execute the block. If you pass `nil`, the block is run synchronously on the posting thread.
     - parameter handler: The block to be executed when the event is received.
     - returns: An opaque `ListenerToken` object. The listener is automatically deregistered when this token object is deallocated, so be sure to retain a reference to it.
     */
    public func addEventListener(queue: OperationQueue?, handler: @escaping WearableDeviceEventHandler) -> ListenerToken {
        let token =
            NotificationCenter.default.addObserver(for: WearableDeviceEvent.self,
                                                   object: self,
                                                   queue: queue,
                                                   using: handler)
        return ListenerToken(token)
    }
}
