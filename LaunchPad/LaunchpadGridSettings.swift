//
//  LaunchpadGridSettings.swift
//  LaunchPad
//
//  Stores configurable grid layout: how many columns per row and how many rows per page,
//  as well as paddings and icon size. This is separated so future UI can tweak these values
//  and the grid will automatically refresh.
//

import Foundation
import Combine

final class LaunchpadGridSettings: ObservableObject {
    static let shared = LaunchpadGridSettings()

    @Published var columnsPerRow: Int {
        didSet { persist() }
    }

    @Published var rowsPerPage: Int {
        didSet { persist() }
    }

    /// Horizontal margin between grid and screen edges.
    @Published var horizontalMargin: Double {
        didSet { persist() }
    }

    /// Vertical margin between grid and screen edges.
    @Published var verticalMargin: Double {
        didSet { persist() }
    }

    /// Icon size (width/height) in points.
    @Published var iconSize: Double {
        didSet { persist() }
    }

    private let columnsKey = "LaunchpadGridSettings.columnsPerRow"
    private let rowsKey = "LaunchpadGridSettings.rowsPerPage"
    private let hMarginKey = "LaunchpadGridSettings.horizontalMargin"
    private let vMarginKey = "LaunchpadGridSettings.verticalMargin"
    private let iconSizeKey = "LaunchpadGridSettings.iconSize"

    private init() {
        let defaults = UserDefaults.standard
        let storedColumns = defaults.integer(forKey: columnsKey)
        let storedRows = defaults.integer(forKey: rowsKey)
        let storedHMargin = defaults.object(forKey: hMarginKey) as? Double
        let storedVMargin = defaults.object(forKey: vMarginKey) as? Double
        let storedIconSize = defaults.object(forKey: iconSizeKey) as? Double

        // Provide sensible defaults if nothing stored yet.
        self.columnsPerRow = storedColumns > 0 ? storedColumns : 7
        self.rowsPerPage = storedRows > 0 ? storedRows : 5
        self.horizontalMargin = storedHMargin ?? 80
        self.verticalMargin = storedVMargin ?? 60
        self.iconSize = storedIconSize ?? 64
    }

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(columnsPerRow, forKey: columnsKey)
        defaults.set(rowsPerPage, forKey: rowsKey)
        defaults.set(horizontalMargin, forKey: hMarginKey)
        defaults.set(verticalMargin, forKey: vMarginKey)
        defaults.set(iconSize, forKey: iconSizeKey)
    }
}


