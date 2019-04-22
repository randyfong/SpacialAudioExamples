//
//  UIApplication+DisplayInfo.swift
//  BoseWearable/SearchUI
//
//  Created by Paul Calnan on 9/3/18.
//  Copyright © 2018 Rocket Insights, Inc. All rights reserved.
//

import UIKit

extension UIApplication {

    /// A `UIImage` representing the app's icon. Uses the last value in `CFBundleIcons` > `CFBundlePrimaryIcon` > `CFBundleIconFiles` from the app's Info.plist.
    var appIcon: UIImage? {
        let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any]
        let primaryIcon = icons?["CFBundlePrimaryIcon"] as? [String: Any]
        let iconFiles = primaryIcon?["CFBundleIconFiles"] as? [String]

        if let lastIcon = iconFiles?.last {
            return UIImage(named: lastIcon)
        }
        else {
            return nil
        }
    }

    /// The app's display name. Uses `CFBundleDisplayName`, falling back to `CFBundleName` from the app's Info.plist.
    var displayName: String? {
        return Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ??
            Bundle.main.infoDictionary?["CFBundleName"] as? String
    }

}
