//
//  SignalStrength+ImageName.swift
//  BoseWearable/SearchUI
//
//  Created by Paul Calnan on 11/7/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import Foundation

extension SignalStrength {

    /// The name of the image resource associated with a given signal strength value.
    var imageName: String {
        let index: Int

        switch self {
        case .weak:
            index = 1
        case .moderate:
            index = 2
        case .strong:
            index = 3
        case .full:
            index = 4
        }

        return "bars-\(index)"
    }
}
