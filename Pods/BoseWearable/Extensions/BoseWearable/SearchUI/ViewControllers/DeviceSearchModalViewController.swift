//
//  DeviceSearchModalViewController.swift
//  BoseWearable/SearchUI
//
//  Created by Paul Calnan on 9/3/18.
//  Copyright © 2018 Rocket Insights, Inc. All rights reserved.
//

import BLECore
import UIKit

/// The root modal view controller that contains the `DeviceListTableViewController`.
class DeviceSearchModalViewController: UIViewController {

    /// The view that contains the child `DeviceListTableViewController` instance.
    @IBOutlet var containerView: UIView!

    /// Called when the user taps in the background view (not in the `containerView` or its children).
    var cancelCallback: (() -> Void)?

    /// :nodoc:
    override func viewDidLoad() {
        super.viewDidLoad()
        containerView.layer.cornerRadius = 40
    }

    /// Called when the user taps in the background view (not in the `containerView` or its children).
    @IBAction func tapGestureRecognized(_ sender: Any) {
        self.cancelCallback?()
        dismiss(animated: true, completion: nil)
    }
}
