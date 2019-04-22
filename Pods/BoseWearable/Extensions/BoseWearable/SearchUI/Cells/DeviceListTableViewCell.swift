//
//  DeviceListTableViewCell.swift
//  BoseWearable/SearchUI
//
//  Created by Paul Calnan on 9/3/18.
//  Copyright © 2018 Rocket Insights, Inc. All rights reserved.
//

import CoreBluetooth
import UIKit

/// A cell for the `DeviceListTableViewController`.
class DeviceListTableViewCell: UITableViewCell {

    /// Symbolic constants
    enum Constants {

        /// The text color when a device is connected or connecting
        static let selectedColor = UIColor.black

        /// The text color when a device is disconnected or disconnecting
        static let unselectedColor = UIColor(red: 139 / 255, green: 139 / 255, blue: 139 / 255, alpha: 1.0)
    }

    /// Image view for the signal strength icon
    @IBOutlet weak var signalStrengthImageView: UIImageView!

    /// Label for the device name
    @IBOutlet weak var deviceNameLabel: UILabel!

    /// Image view indicating the connection state
    @IBOutlet weak var radioButton: UIImageView!

    /// Activity indicator indicating that the device is connecting.
    @IBOutlet weak var connectingIndicator: UIActivityIndicatorView!

    /// Configure the cell to display the specified name, peripheral state, and signal strength.
    func configure(name: String, state: CBPeripheralState, signalStrength: SignalStrength?) {
        let bundle = Bundle(for: type(of: self))

        deviceNameLabel.text = name
        if let imageName = signalStrength?.imageName {
            signalStrengthImageView.image = UIImage(named: imageName, in: bundle, compatibleWith: nil)
        }
        else {
            signalStrengthImageView.image = nil
        }

        switch state {
        case .connecting:
            connectingIndicator.startAnimating()
            radioButton.image = UIImage(named: "radioButtonConnecting", in: bundle, compatibleWith: nil)
            deviceNameLabel.textColor = Constants.selectedColor
        case .connected:
            connectingIndicator.stopAnimating()
            radioButton.image = UIImage(named: "radioButtonOn", in: bundle, compatibleWith: nil)
            deviceNameLabel.textColor = Constants.selectedColor
        case .disconnected, .disconnecting:
            connectingIndicator.stopAnimating()
            radioButton.image = UIImage(named: "radioButtonOff", in: bundle, compatibleWith: nil)
            deviceNameLabel.textColor = Constants.unselectedColor
        }
    }
}
