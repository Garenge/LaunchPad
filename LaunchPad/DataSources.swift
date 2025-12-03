//
//  DataSources.swift
//  LaunchPad
//
//  Abstract data-source layer for apps and layout.
//

import Foundation
import AppKit

// MARK: - Protocols

/// Abstract source of installed applications.
protocol AppCatalogDataSource {
    /// Load the list of installed applications that can appear in Launchpad.
    func loadInstalledApps() throws -> [AppItem]
}

/// Abstract source of Launchpad layout (pages, order, folders).
protocol LaunchpadLayoutDataSource {
    /// Load layout for given apps. If no persisted layout exists, create a sensible default.
    func loadLayout(for apps: [AppItem]) throws -> LaunchpadLayout

    /// Persist the given layout.
    func saveLayout(_ layout: LaunchpadLayout) throws
}

// MARK: - Errors

enum LaunchpadDataError: Error {
    case layoutNotFound
}

// MARK: - Concrete implementations (plan A: filesystem + local JSON)

/// File-system based implementation that scans common application directories.
final class FileSystemAppCatalogDataSource: AppCatalogDataSource {
    private let searchDirectories: [URL]

    init(searchDirectories: [URL]? = nil) {
        if let dirs = searchDirectories {
            self.searchDirectories = dirs
        } else {
            self.searchDirectories = [
                URL(fileURLWithPath: "/Applications"),
                URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Applications"),
                URL(fileURLWithPath: "/System/Applications")
            ]
        }
    }

    func loadInstalledApps() throws -> [AppItem] {
        var items: [AppItem] = []
        let fm = FileManager.default

        for baseURL in searchDirectories {
            guard let contents = try? fm.contentsOfDirectory(
                at: baseURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }

            for url in contents where url.pathExtension == "app" {
                guard let bundle = Bundle(url: url) else { continue }

                let displayName =
                    (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String) ??
                    (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String) ??
                    url.deletingPathExtension().lastPathComponent

                let bundleId = bundle.bundleIdentifier
                let isSystem = url.path.hasPrefix("/System")

                let item = AppItem(
                    name: displayName,
                    bundleIdentifier: bundleId,
                    bundleURL: url,
                    isSystemApp: isSystem
                )
                items.append(item)
            }
        }

        // Simple deterministic ordering: by localized name.
        return items.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
}

/// Layout data-source that stores user layout in a JSON file under Application Support.
final class LocalJSONLayoutDataSource: LaunchpadLayoutDataSource {
    private let fileURL: URL
    private let itemsPerPage: Int

    init(fileURL: URL? = nil, itemsPerPage: Int = 35) {
        if let customURL = fileURL {
            self.fileURL = customURL
        } else {
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first ?? URL(fileURLWithPath: NSHomeDirectory())

            let directory = appSupport.appendingPathComponent("LaunchPad", isDirectory: true)
            try? FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: nil
            )

            self.fileURL = directory.appendingPathComponent("layout.json")
        }

        self.itemsPerPage = max(itemsPerPage, 1)
    }

    func loadLayout(for apps: [AppItem]) throws -> LaunchpadLayout {
        let fm = FileManager.default

        if fm.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                let layout = try JSONDecoder().decode(LaunchpadLayout.self, from: data)
                return layout
            } catch {
                // If decoding fails, fall back to default layout.
                return makeDefaultLayout(for: apps)
            }
        } else {
            // No existing layout – create a default one.
            return makeDefaultLayout(for: apps)
        }
    }

    func saveLayout(_ layout: LaunchpadLayout) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(layout)
        try data.write(to: fileURL, options: [.atomic])
    }

    // MARK: - Helpers

    private func makeDefaultLayout(for apps: [AppItem]) -> LaunchpadLayout {
        // Default: put all apps into a single page.
        let items = apps.map { LaunchpadItem.app(id: $0.id) }
        let page = LaunchpadPage(items: items)
        return LaunchpadLayout(pages: [page])
    }
}


