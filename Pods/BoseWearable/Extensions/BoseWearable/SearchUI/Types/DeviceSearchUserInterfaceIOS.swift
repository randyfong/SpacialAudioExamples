//
//  DeviceSearchUserInterfaceIOS.swift
//  BoseWearable/SearchUI
//
//  Created by Paul Calnan on 11/6/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import BLECore
import UIKit

/// The `DeviceSearchTaskUserInterface` implementation for iOS.
class DeviceSearchUserInterfaceIOS: DeviceSearchTaskUserInterface {

    /// Since the user interface is not provided with a `UIViewController` upon which we can modally present, we need to create a `UIWindow` to present in.
    private var window: UIWindow?

    /// The root view controller of our `UIWindow`.
    private let rootViewController: UIViewController

    /// The modal view controller that we present on the `rootViewController`.
    private let modalViewController: DeviceSearchModalViewController

    /// The device list table view controller that we will update based on the received events.
    private let deviceListTableViewController: DeviceListTableViewController

    weak var delegate: DeviceSearchTaskUserInterfaceDelegate?

    /// Load the view controllers from our storyboard.
    private static func instantiateViewControllers() -> (DeviceSearchModalViewController, DeviceListTableViewController) {
        let storyboard = UIStoryboard(name: "DeviceSearchUserInterfaceIOS", bundle: BoseWearable.bundle)
        guard let modalVC = storyboard.instantiateInitialViewController() as? DeviceSearchModalViewController else {
            fatalError("Could not instantiate device search UI")
        }

        _ = modalVC.view

        guard let tableVC = modalVC.children.compactMap({ $0 as? DeviceListTableViewController }).first else {
            fatalError("Could not instantiate device search UI")
        }

        return (modalVC, tableVC)
    }

    /// :nodoc:
    init() {
        (modalViewController, deviceListTableViewController) = DeviceSearchUserInterfaceIOS.instantiateViewControllers()

        rootViewController = UIViewController(nibName: nil, bundle: nil)
        rootViewController.view.backgroundColor = .clear

        deviceListTableViewController.selectionCallback = { [weak self] in
            self?.delegate?.selected(device: $0)
        }

        modalViewController.cancelCallback = { [weak self] in
            self?.delegate?.cancelled()
        }
    }

    func show() {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()

        rootViewController.present(modalViewController, animated: true)
    }

    func dismiss() {
        rootViewController.dismiss(animated: true) { [weak self] in
            self?.window = nil
        }
    }

    func add(device: DiscoveredDevice, signalStrength: SignalStrength) {
        deviceListTableViewController.add(device: device, signalStrength: signalStrength)
    }

    func update(device: DiscoveredDevice, signalStrength: SignalStrength) {
        deviceListTableViewController.update(device: device, signalStrength: signalStrength)
    }

    func remove(device: DiscoveredDevice) {
        deviceListTableViewController.remove(device: device)
    }

}
