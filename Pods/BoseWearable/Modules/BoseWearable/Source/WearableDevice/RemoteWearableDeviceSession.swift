//
//  RemoteWearableDeviceSession.swift
//  BoseWearable
//
//  Created by Paul Calnan on 10/18/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import BLECore
import Foundation
import Logging

/// Represents a wearable device session with a remote device.
class RemoteWearableDeviceSession: WearableDeviceSession, SessionDelegate {

    weak var delegate: WearableDeviceSessionDelegate?

    /// This session is owned and managed by this object. When this object is deallocated, the session is closed and disposed.
    private let session: Session

    /// The token representing the `WearableDeviceEvent` listener.
    private var token: NotificationToken?

    /// Flag indicating whether all startup information has been received.
    private var waitingForStartupInformation = true

    /**
     Creates a new `RemoteWearableDeviceSession` with the specified underlying `BLECore.Session`.

     The underlying session is hereafter owned by this `RemoteWearableDeviceSession`. It is closed and disposed when this object is deallocated. Thus, it is important that there is a strict one-to-one correspondence between a `Session` and a `RemoteWearableDeviceSession`. If a `Session` is shared between multiple `RemoteWearableDeviceSession` objects, it will be destroyed when the first `RemoteWearableDeviceSession` is deallocated.
     */
    init(session: Session) {
        self.session = session
        self.session.delegate = self

        token = NotificationCenter.default.addObserver(for: WearableDeviceEvent.self, queue: .main) { [weak self] event in
            self?.wearableDeviceEvent(event)
        }
    }

    /// Close and dispose of the underlying `BLECore.Session` object.
    deinit {
        Log.session.info("Deallocating RemoteWearableDeviceSession; Close and dispose underlying BLECore.Session")
        session.close()
        session.dispose()
    }

    /// Called whenever a `WearableDeviceEvent` has been received.
    private func wearableDeviceEvent(_ event: WearableDeviceEvent) {
        notifyDelegateIfStartupSequenceComplete()
    }

    /// If the device is ready, notifies the delegate that the session opened. If an error thrown by `Device.deviceIsReady()`, closes the session and propagates the error to the delegate.
    private func notifyDelegateIfStartupSequenceComplete() {
        if waitingForStartupInformation {

            do {
                let done = try device?.deviceIsReady()
                if done ?? false {
                    delegate?.sessionDidOpen(self)
                    waitingForStartupInformation = false
                }
            }
            catch {
                close()
                delegate?.session(self, didFailToOpenWithError: error)
            }
        }
    }

    var device: WearableDevice? {
        return session.device as? WearableDevice
    }

    func open() {
        waitingForStartupInformation = true
        session.open()
    }

    func close() {
        session.close()
    }

    func sessionDidOpen(_ session: Session) {
        notifyDelegateIfStartupSequenceComplete()
    }

    func session(_ session: Session, didFailToOpenWithError error: Error?) {
        delegate?.session(self, didFailToOpenWithError: error)
    }

    func session(_ session: Session, didCloseWithError error: Error?) {
        delegate?.session(self, didCloseWithError: error)
    }

}
