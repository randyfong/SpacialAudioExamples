//
//  SessionDelegate.swift
//  BLECore
//
//  Created by Paul Calnan on 8/14/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

/// A session delegate is notified of connectivity events related to a session.
public protocol SessionDelegate: class {

    /// Called to indicate that the `Session` successfully opened and its corresponding `Device` was successfully created.
    func sessionDidOpen(_ session: Session)

    /// Called to indicate that the `Session` failed to open. An error object is provided indicating the cause of the error.
    func session(_ session: Session, didFailToOpenWithError error: Error?)

    /// Called to indicate that the `Session` closed. If the `Session` closed normally, the error object will be `nil`. If the `Session` closed due to an error condition, that error condition will be indicated by a non-nil `error` parameter.
    func session(_ session: Session, didCloseWithError error: Error?)
}
