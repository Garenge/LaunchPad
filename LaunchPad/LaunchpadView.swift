//
//  LaunchpadView.swift
//  LaunchPad
//
//  First-pass Launchpad UI: a single-page grid of app icons backed by the view model.
//

import SwiftUI
import AppKit

struct LaunchpadView: View {
    @ObservedObject var viewModel: LaunchpadViewModel
    @ObservedObject private var gridSettings = LaunchpadGridSettings.shared

    @State private var currentPage: Int = 0
    @State private var lastScrollTime: Date = .distantPast

    private let indicatorBottomPadding: CGFloat = 32
    private let indicatorReservedHeight: CGFloat = 72

    // Grid configuration derived from grid settings.
    private var columns: [GridItem] {
        let count = max(gridSettings.columnsPerRow, 1)
        return Array(
            repeating: GridItem(.flexible(), spacing: 32, alignment: .center),
            count: count
        )
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // 中心网格
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else if let message = viewModel.errorMessage {
                    Text(message)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    gridAndPaging(in: proxy.size)
                        .padding(.horizontal, gridSettings.horizontalMargin)
                }

                // 固定在底部的页面指示器
                if let layout = viewModel.layout {
                    let allItems = layout.pages.flatMap { $0.items }
                    let itemsPerPage = max(1, gridSettings.columnsPerRow * gridSettings.rowsPerPage)
                    let pages = paginate(items: allItems, itemsPerPage: itemsPerPage)
                    let safePageIndex = min(max(currentPage, 0), max(pages.count - 1, 0))

                    if pages.count > 1 {
                        VStack {
                            Spacer()
                            pageControl(totalPages: pages.count, current: safePageIndex)
                                .padding(.bottom, indicatorBottomPadding)
                        }
                        .padding(.horizontal, gridSettings.horizontalMargin)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func gridAndPaging(in containerSize: CGSize) -> some View {
        if let layout = viewModel.layout {
            let allItems = layout.pages.flatMap { $0.items }
            let itemsPerPage = max(1, gridSettings.columnsPerRow * gridSettings.rowsPerPage)
            let pages = paginate(items: allItems, itemsPerPage: itemsPerPage)
            let safePageIndex = min(max(currentPage, 0), max(pages.count - 1, 0))
            let pageItems = pages.isEmpty ? [] : pages[safePageIndex]

            ZStack {
                VStack(spacing: 0) {
                    Spacer().frame(height: gridSettings.verticalMargin)

                    LazyVGrid(columns: columns, alignment: .center, spacing: 32) {
                        ForEach(Array(pageItems.enumerated()), id: \.offset) { _, item in
                            switch item {
                            case .app(let id):
                                if let app = viewModel.app(for: id) {
                                    AppIconView(app: app, iconSize: gridSettings.iconSize)
                                }
                            case .folder(let folder):
                                FolderIconPlaceholderView(folder: folder, iconSize: gridSettings.iconSize)
                            }
                        }
                    }

                    Spacer().frame(height: indicatorReservedHeight + gridSettings.verticalMargin)
                }

                // 捕获滚轮事件用于翻页
                ScrollPagingCaptureView { deltaY in
                    handleScroll(deltaY: deltaY, totalPages: pages.count)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Text("No layout available")
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Pagination helpers

    private func handleScroll(deltaY: CGFloat, totalPages: Int) {
        // 简单节流，避免一次滚动触发多次翻页
        let now = Date()
        guard now.timeIntervalSince(lastScrollTime) > 0.15 else { return }
        lastScrollTime = now

        guard totalPages > 1 else { return }

        let oldPage = currentPage

        if deltaY < 0, currentPage < totalPages - 1 {
            currentPage += 1
        } else if deltaY > 0, currentPage > 0 {
            currentPage -= 1
        }

        if currentPage != oldPage {
            print("Launchpad currentPage =", currentPage, "/", totalPages)
        }
    }

    private func paginate(items: [LaunchpadItem], itemsPerPage: Int) -> [[LaunchpadItem]] {
        guard itemsPerPage > 0 else { return [items] }
        var pages: [[LaunchpadItem]] = []
        var index = 0

        while index < items.count {
            let end = min(index + itemsPerPage, items.count)
            let page = Array(items[index..<end])
            pages.append(page)
            index = end
        }

        if pages.isEmpty {
            pages = [[]]
        }

        return pages
    }

    @ViewBuilder
    private func pageControl(totalPages: Int, current: Int) -> some View {
        HStack(spacing: 16) {
            Button {
                if currentPage > 0 {
                    currentPage -= 1
                }
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white.opacity(current > 0 ? 0.9 : 0.4))
            }
            .buttonStyle(.plain)
            .disabled(current <= 0)

            HStack(spacing: 6) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(index == current ? Color.white : Color.white.opacity(0.4))
                        .frame(width: index == current ? 8 : 6, height: index == current ? 8 : 6)
                }
            }

            Button {
                if currentPage < totalPages - 1 {
                    currentPage += 1
                }
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(current < totalPages - 1 ? 0.9 : 0.4))
            }
            .buttonStyle(.plain)
            .disabled(current >= totalPages - 1)
        }
    }
}

// MARK: - Icon Views

private struct AppIconView: View {
    let app: AppItem
    let iconSize: Double

    var body: some View {
        VStack(spacing: 8) {
            iconImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
                .cornerRadius(iconSize * 0.22)
                .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)

            Text(app.name)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 80)
        }
    }

    private var iconImage: Image {
        let nsImage = NSWorkspace.shared.icon(forFile: app.bundleURL.path)
        return Image(nsImage: nsImage)
    }
}

/// Placeholder for folder icon – later can be replaced with real folder preview.
private struct FolderIconPlaceholderView: View {
    let folder: FolderItem
    let iconSize: Double

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.2))
                .frame(width: iconSize, height: iconSize)
                .overlay(
                    Image(systemName: "folder.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white.opacity(0.8))
                        .padding(14)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)

            Text(folder.name)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 80)
        }
    }
}

#Preview {
    // Minimal preview with an empty view model.
    LaunchpadView(viewModel: LaunchpadViewModel())
        .background(
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
            }
        )
}


