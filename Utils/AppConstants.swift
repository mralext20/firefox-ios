/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

public enum AppBuildChannel {
    case Developer
    case Aurora
}

public struct AppConstants {
    static let AboutHomeURL = NSURL(string: "about:home")!

    static let AppBackgroundColor = UIColor.blackColor()

    static let ToolbarHeight: CGFloat = 44
    static let DefaultRowHeight: CGFloat = 58
    static let DefaultPadding: CGFloat = 10

    static let DefaultMediumBoldFont = UIFont(name: UIAccessibilityIsBoldTextEnabled() ? "HelveticaNeue-Bold" : "HelveticaNeue", size: 13)
    static let DefaultMediumFont = UIFont(name: UIAccessibilityIsBoldTextEnabled() ? "HelveticaNeue-Medium" : "HelveticaNeue", size: 13)
    static let DefaultSmallFontSize: CGFloat = 11
    static let DefaultSmallFont = UIFont(name: UIAccessibilityIsBoldTextEnabled() ? "HelveticaNeue-Medium" : "HelveticaNeue", size: DefaultSmallFontSize)
    static let DefaultSmallFontBold = UIFont(name: "HelveticaNeue-Bold", size: 11)

    // These highlight colors are currently only used on Snackbar buttons when they're pressed
    static let HighlightColor = UIColor(red: 205/255, green: 223/255, blue: 243/255, alpha: 0.9)
    static let HighlightText = UIColor(red: 42/255, green: 121/255, blue: 213/255, alpha: 1.0)

    static let PanelBackgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.6)
    static let SeparatorColor = UIColor(rgb: 0xcccccc)
    static let HighlightBlue = UIColor(red:0.3, green:0.62, blue:1, alpha:1)
    static let BorderColor = UIColor.blackColor().colorWithAlphaComponent(0.25)
    static let BackgroundColor = UIColor(red: 0.21, green: 0.23, blue: 0.25, alpha: 1)

    // Firefox Orange
    static let ControlTintColor = UIColor(red: 240.0 / 255, green: 105.0 / 255, blue: 31.0 / 255, alpha: 1)

#if MOZ_CHANNEL_AURORA
    static let BuildChannel = AppBuildChannel.Aurora
#else
    static let BuildChannel = AppBuildChannel.Developer
#endif

    static let IsRunningTest = NSClassFromString("XCTestCase") != nil
}
