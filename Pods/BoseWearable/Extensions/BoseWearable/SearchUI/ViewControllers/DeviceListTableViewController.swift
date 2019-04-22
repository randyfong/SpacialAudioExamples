//
//  DeviceListTableViewController.swift
//  BoseWearable/SearchUI
//
//  Created by Paul Calnan on 9/3/18.
//  Copyright © 2018 Rocket Insights, Inc. All rights reserved.
//

import BLECore
import UIKit

/// Shows the list of discovered devices, their signal strength, and connection state.
class DeviceListTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    /// Symbolic constants
    enum Constants {

        /// Table view row height
        static let rowHeight: CGFloat = 64

        /// Table view header height
        static let headerHeight: CGFloat = 40

        /// Top background gradient color
        static let backgroundGradientTop = UIColor.white

        /// Bottom background gradient color
        static let backgroundGradientBottom = UIColor(red: 243 / 255, green: 243 / 255, blue: 243 / 255, alpha: 1.0)
    }

    /// Label showing the app name
    @IBOutlet weak var appNameLabel: UILabel!

    /// Image view showing the app icon
    @IBOutlet weak var iconImageView: UIImageView!

    /// Table view containing the discovered devices
    @IBOutlet weak var tableView: UITableView!

    /// Status label showing the current connection status
    @IBOutlet weak var statusLabel: UILabel!

    /// Image view showing the device icon
    @IBOutlet weak var deviceIconView: UIImageView!

    /// Label showing the table header
    @IBOutlet weak var headerLabel: UILabel!

    /// The list of discovered devices being displayed.
    private(set) var devices: [DiscoveredDevice] = []

    /// Callback invoked when a device is selected.
    var selectionCallback: ((DiscoveredDevice) -> Void)!

    /// Maps discovered device identifier to that device's signal strength.
    private var signalStrength: [UUID: SignalStrength] = [:]

    /// Flag indicating whether we have devices to show (false) or an empty-state message should be shown (true).
    private var showEmptyMessage = true

    /// :nodoc:
    override func viewDidLoad() {
        super.viewDidLoad()
        appNameLabel.text = UIApplication.shared.displayName
        iconImageView.image = UIApplication.shared.appIcon
        iconImageView.layer.cornerRadius = 10

        tableView.rowHeight = Constants.rowHeight
    }

    /// :nodoc:
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setGradient(top: Constants.backgroundGradientTop, bottom: Constants.backgroundGradientBottom)
    }

    /// Configures the gradient of the table view background.
    private func setGradient(top: UIColor, bottom: UIColor) {
        let gradientBackgroundColors = [top.cgColor, bottom.cgColor]
        let gradientLocations: [NSNumber] = [0.0, 1.0]

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = gradientBackgroundColors
        gradientLayer.locations = gradientLocations

        gradientLayer.frame = tableView.bounds
        let backgroundView = UIView(frame: tableView.bounds)
        backgroundView.layer.insertSublayer(gradientLayer, at: 0)
        tableView.backgroundView = backgroundView
    }

    /// :nodoc:
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    /// :nodoc:
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return showEmptyMessage ? 1 : devices.count
    }

    /// :nodoc:
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if showEmptyMessage {
            return tableView.dequeueReusableCell(withIdentifier: "EmptyCell", for: indexPath)
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceListTableViewCell", for: indexPath) as? DeviceListTableViewCell else {
            return UITableViewCell()
        }

        guard let device = device(at: indexPath) else {
            return cell
        }

        configure(cell, for: device)
        return cell
    }

    /// :nodoc:
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let device = device(at: indexPath) else {
            return
        }
        selectionCallback(device)
    }

    /// :nodoc:
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.rowHeight
    }

    /// Finds the index of the specified device in the `devices` array.
    private func index(for device: DiscoveredDevice) -> Int? {
        return devices.firstIndex(where: { $0.identifier == device.identifier })
    }

    /// Finds the index path for the specified device.
    private func indexPath(for device: DiscoveredDevice) -> IndexPath? {
        guard let idx = index(for: device) else {
            return nil
        }
        return indexPath(forIndex: idx)
    }

    /// Converts an index to an index path.
    private func indexPath(forIndex index: Int) -> IndexPath {
        return IndexPath(row: index, section: 0)
    }

    /// Finds the device at the specified index path.
    private func device(at indexPath: IndexPath) -> DiscoveredDevice? {
        guard indexPath.row < devices.count else {
            return nil
        }
        return devices[indexPath.row]
    }

    /// Updates the status label based on the current connected device(s).
    private func checkStatus() {
        let connectedDevices = BoseWearable.shared.retrieveConnectedWearableDevices()
        if connectedDevices.count == 0 {
            statusLabel.text =
                NSLocalizedString("DeviceListTableViewController.noDevice", tableName: "SearchUILocalizable", bundle: BoseWearable.bundle, comment: "")
        }
        else {
            if devices.count == 1, let name = devices.first?.name ?? devices.first?.localName {
                statusLabel.text = name
            }
            else {
                statusLabel.text =
                    NSLocalizedString("DeviceListTableViewController.connected", tableName: "SearchUILocalizable", bundle: BoseWearable.bundle, comment: "")
            }
        }
    }

    /// Add the specified device with the specified signal strength.
    func add(device: DiscoveredDevice, signalStrength: SignalStrength) {
        checkStatus()
        set(signalStrength: signalStrength, for: device)

        if showEmptyMessage {
            // this is the first device, remove the looking for devices message
            showEmptyMessage = false
            tableView.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        }

        devices.append(device)
        let ip = indexPath(forIndex: devices.count - 1)
        tableView.insertRows(at: [ip], with: .automatic)
    }

    /// Update the display of the specified device.
    func update(device: DiscoveredDevice, signalStrength: SignalStrength) {
        checkStatus()
        set(signalStrength: signalStrength, for: device)

        guard
            let ip = indexPath(for: device),
            let cell = tableView.cellForRow(at: ip) as? DeviceListTableViewCell
        else {
            return
        }

        configure(cell, for: device)
    }

    /// Remove the specified device.
    func remove(device: DiscoveredDevice) {
        guard let index = index(for: device) else {
            return
        }
        checkStatus()

        devices.remove(at: index)

        let ip = indexPath(forIndex: index)
        tableView.deleteRows(at: [ip], with: .automatic)
    }

    /// Updates the signal strength of the specified device.
    private func set(signalStrength newValue: SignalStrength, for device: DiscoveredDevice) {
        signalStrength[device.identifier] = newValue
    }

    /// Returns the signal strength for the specified device.
    private func signalStrength(for device: DiscoveredDevice) -> SignalStrength? {
        return signalStrength[device.identifier]
    }

    /// Updates the specified cell to display the specified device.
    private func configure(_ cell: DeviceListTableViewCell, for device: DiscoveredDevice) {
        let name = device.name ?? device.localName ?? "---"
        cell.configure(name: name, state: device.state, signalStrength: signalStrength(for: device))
    }
}
