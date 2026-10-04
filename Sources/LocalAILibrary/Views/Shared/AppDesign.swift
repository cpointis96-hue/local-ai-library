import SwiftUI

enum AppDesign {
    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let xxl: CGFloat = 20
        static let xxxl: CGFloat = 24
    }

    enum Radius {
        static let small: CGFloat = 5
        static let medium: CGFloat = 7
        static let large: CGFloat = 10
    }

    enum Control {
        static let compactHeight: CGFloat = 24
        static let regularHeight: CGFloat = 28
        static let prominentHeight: CGFloat = 32
    }

    enum Width {
        static let sidebarMin: CGFloat = 180
        static let sidebarIdeal: CGFloat = 220
        static let sidebarMax: CGFloat = 280
        static let browserMin: CGFloat = 240
        static let browserIdeal: CGFloat = 320
        static let browserMax: CGFloat = 460
        static let detailMax: CGFloat = 760
    }

    enum Colors {
        static let windowBackground = Color(nsColor: .windowBackgroundColor)
        static let sidebarBackground = Color(nsColor: .underPageBackgroundColor)
        static let secondaryBackground = Color(nsColor: .controlBackgroundColor)
        static let separator = Color(nsColor: .separatorColor)
        static let secondaryText = Color(nsColor: .secondaryLabelColor)
        static let tertiaryText = Color(nsColor: .tertiaryLabelColor)
    }

    enum Typography {
        static let section = Font.system(.caption, design: .default).weight(.semibold)
        static let row = Font.system(.body, design: .default)
        static let metadata = Font.system(.caption, design: .default)
        static let detailLabel = Font.system(.caption, design: .default).weight(.medium)
        static let detailValue = Font.system(.body, design: .default)
    }
}
