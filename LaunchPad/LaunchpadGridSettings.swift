//
//  LaunchpadGridSettings.swift
//  LaunchPad
//
//  Stores configurable grid layout: how many columns per row and how many rows per page.
//  This is separated so future UI can tweak these values and the grid will automatically refresh.
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

    private let columnsKey = "LaunchpadGridSettings.columnsPerRow"
    private let rowsKey = "LaunchpadGridSettings.rowsPerPage"

    private init() {
        let defaults = UserDefaults.standard
        let storedColumns = defaults.integer(forKey: columnsKey)
        let storedRows = defaults.integer(forKey: rowsKey)

        // Provide sensible defaults if nothing stored yet.
        self.columnsPerRow = storedColumns > 0 ? storedColumns : 7
        self.rowsPerPage = storedRows > 0 ? storedRows : 5
    }

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(columnsPerRow, forKey: columnsKey)
        defaults.set(rowsPerPage, forKey: rowsKey)
    }
}


