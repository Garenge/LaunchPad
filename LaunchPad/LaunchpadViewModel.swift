//
//  LaunchpadViewModel.swift
//  LaunchPad
//
//  View model that bridges LaunchpadRepository to SwiftUI views.
//

import Foundation
import Combine

final class LaunchpadViewModel: ObservableObject {
    @Published private(set) var apps: [AppItem] = []
    @Published private(set) var layout: LaunchpadLayout?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let repository: LaunchpadRepository

    init(repository: LaunchpadRepository = LaunchpadRepository()) {
        self.repository = repository
        loadInitialData()
    }

    /// Load apps and layout from the repository.
    func loadInitialData() {
        isLoading = true
        errorMessage = nil

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                let (apps, layout) = try self.repository.loadInitialData()
                DispatchQueue.main.async {
                    self.apps = apps
                    self.layout = layout
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    /// Lookup an app by its ID.
    func app(for id: UUID) -> AppItem? {
        apps.first(where: { $0.id == id })
    }
}


