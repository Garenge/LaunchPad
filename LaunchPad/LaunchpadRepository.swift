//
//  LaunchpadRepository.swift
//  LaunchPad
//
//  Facade that combines app catalog + layout data-sources.
//

import Foundation

/// Repository providing a unified API for Launchpad-related data.
final class LaunchpadRepository {
    private let appDataSource: AppCatalogDataSource
    private let layoutDataSource: LaunchpadLayoutDataSource

    init(
        appDataSource: AppCatalogDataSource = FileSystemAppCatalogDataSource(),
        layoutDataSource: LaunchpadLayoutDataSource = LocalJSONLayoutDataSource()
    ) {
        self.appDataSource = appDataSource
        self.layoutDataSource = layoutDataSource
    }

    /// Load current apps and corresponding layout.
    func loadInitialData() throws -> (apps: [AppItem], layout: LaunchpadLayout) {
        let apps = try appDataSource.loadInstalledApps()
        let layout = try layoutDataSource.loadLayout(for: apps)
        return (apps, layout)
    }

    /// Persist updated layout.
    func updateLayout(_ layout: LaunchpadLayout) throws {
        try layoutDataSource.saveLayout(layout)
    }
}


