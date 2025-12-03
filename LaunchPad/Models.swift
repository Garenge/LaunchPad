//
//  Models.swift
//  LaunchPad
//
//  Core data models for apps and Launchpad layout.
//

import Foundation

/// Represents a single installed application that can appear in Launchpad.
struct AppItem: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let bundleIdentifier: String?
    let bundleURL: URL
    let isSystemApp: Bool

    init(
        id: UUID = UUID(),
        name: String,
        bundleIdentifier: String?,
        bundleURL: URL,
        isSystemApp: Bool
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.bundleURL = bundleURL
        self.isSystemApp = isSystemApp
    }
}

/// Top-level representation of Launchpad layout: pages of items.
struct LaunchpadLayout: Codable {
    var pages: [LaunchpadPage]
}

/// A single page in Launchpad.
struct LaunchpadPage: Codable {
    var items: [LaunchpadItem]
}

/// An item that can be placed on a Launchpad page: either a single app or a folder.
enum LaunchpadItem: Codable {
    case app(id: UUID)
    case folder(FolderItem)

    private enum CodingKeys: String, CodingKey {
        case type
        case appID
        case folder
    }

    private enum ItemType: String, Codable {
        case app
        case folder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ItemType.self, forKey: .type)

        switch type {
        case .app:
            let appID = try container.decode(UUID.self, forKey: .appID)
            self = .app(id: appID)
        case .folder:
            let folder = try container.decode(FolderItem.self, forKey: .folder)
            self = .folder(folder)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .app(let id):
            try container.encode(ItemType.app, forKey: .type)
            try container.encode(id, forKey: .appID)
        case .folder(let folder):
            try container.encode(ItemType.folder, forKey: .type)
            try container.encode(folder, forKey: .folder)
        }
    }
}

/// Represents a folder containing apps in Launchpad.
struct FolderItem: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var appIDs: [UUID]

    init(
        id: UUID = UUID(),
        name: String,
        appIDs: [UUID]
    ) {
        self.id = id
        self.name = name
        self.appIDs = appIDs
    }
}


