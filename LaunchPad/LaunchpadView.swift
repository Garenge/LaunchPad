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
    @State private var dragOffset: CGFloat = 0  // Real-time drag offset for visual feedback
    @State private var isDragging: Bool = false
    @State private var pageOffset: CGFloat = 0  // Base offset for page position

    /// 指示器距离屏幕底部的固定间距
    private let indicatorBottomPadding: CGFloat = 32
    /// 指示器自身的高度（用于给网格预留空间）
    private let indicatorHeight: CGFloat = 24

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
                                .frame(height: indicatorHeight)
                                .padding(.bottom, indicatorBottomPadding)
                        }
                        .padding(.horizontal, gridSettings.horizontalMargin)
                    }
                }
            }
        }
        .onAppear {
            // Reset all animation-related state when view appears
            // This ensures clean state when app reopens
            resetAnimationState()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetLaunchpadView"))) { _ in
            // Reset state when explicitly requested (e.g., when app reopens)
            resetAnimationState()
        }
    }
    
    // MARK: - State Reset
    
    private func resetAnimationState() {
        // Reset all animation-related state to initial values
        dragOffset = 0
        pageOffset = 0
        isDragging = false
        lastScrollTime = .distantPast
        // Note: currentPage is intentionally not reset to preserve user's position
    }

    @ViewBuilder
    private func gridAndPaging(in containerSize: CGSize) -> some View {
        if let layout = viewModel.layout {
            let allItems = layout.pages.flatMap { $0.items }
            let itemsPerPage = max(1, gridSettings.columnsPerRow * gridSettings.rowsPerPage)
            let pages = paginate(items: allItems, itemsPerPage: itemsPerPage)

            // 计算给网格可用的高度：
            // 总高度 - 顶部间距 - 底部间距(与顶部相同) - 指示器总高度(自身高度 + 底部固定间距)
            let topMargin = gridSettings.verticalMargin
            let bottomMargin = gridSettings.verticalMargin
            let indicatorTotalHeight = indicatorHeight + indicatorBottomPadding
            let availableGridHeight = max(
                containerSize.height - topMargin - bottomMargin - indicatorTotalHeight,
                0
            )

            // 根据可用高度和每页行数，动态计算行间距：
            // 每个 AppIconView 的实际高度 = iconSize + spacing(8) + textHeight(约24，2行文字)
            let rows = max(gridSettings.rowsPerPage, 1)
            let iconSize = CGFloat(gridSettings.iconSize)
            let iconSpacing: CGFloat = 8  // VStack spacing
            let textHeight: CGFloat = 24  // 2行文字的高度（12pt * 2）
            let itemHeight = iconSize + iconSpacing + textHeight
            let contentHeight = CGFloat(rows) * itemHeight
            let gaps = max(rows - 1, 1)
            let rawRowSpacing = (availableGridHeight - contentHeight) / CGFloat(gaps)
            // 只设置最小值，不设上限，让网格可以随间距变化自由缩放
            let rowSpacing = max(8, rawRowSpacing)
            let pageWidth = containerSize.width - (gridSettings.horizontalMargin * 2)
            
            ZStack {
                // CollectionView 风格：水平排列多个页面
                VStack(spacing: 0) {
                    // 顶部到网格的距离
                    Spacer().frame(height: topMargin)

                    // 页面容器：使用 HStack 水平排列所有页面
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            ForEach(0..<pages.count, id: \.self) { pageIndex in
                                // 每个页面都是一个独立的网格
                                pageView(
                                    items: pages[pageIndex],
                                    columns: columns,
                                    rowSpacing: rowSpacing,
                                    availableHeight: availableGridHeight
                                )
                                .frame(width: pageWidth, height: availableGridHeight, alignment: .top)
                            }
                        }
                        .offset(x: -(CGFloat(currentPage) * pageWidth) + dragOffset + pageOffset)
                        // Use transaction to control animation behavior
                        .transaction { transaction in
                            if isDragging {
                                transaction.animation = nil
                            } else {
                                transaction.animation = .spring(response: 0.4, dampingFraction: 0.85)
                            }
                        }
                    }
                    .frame(height: availableGridHeight)
                    .clipped()  // 裁剪超出部分，只显示当前可见的页面

                    // 使用 Spacer 占据剩余空间
                    Spacer(minLength: 0)

                    // 网格到底部指示器区域顶部的距离，与顶部一致
                    Spacer().frame(height: bottomMargin)

                    // 为底部指示器预留固定区域高度（指示器本身高度 + 固定底部间距）
                    Spacer().frame(height: indicatorHeight + indicatorBottomPadding)
                }

                // 捕获滚轮事件用于翻页
                ScrollPagingCaptureView { deltaY in
                    handleScroll(deltaY: deltaY, totalPages: pages.count)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 捕获鼠标拖拽事件用于翻页（带视觉反馈）
                SwipePagingCaptureView(
                    onDragChanged: { offset in
                        dragOffset = offset
                        isDragging = true
                    },
                    onDragEnded: { direction in
                        handleDragEnd(direction: direction, totalPages: pages.count, pageWidth: pageWidth)
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Text("No layout available")
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Page View
    
    @ViewBuilder
    private func pageView(
        items: [LaunchpadItem],
        columns: [GridItem],
        rowSpacing: CGFloat,
        availableHeight: CGFloat
    ) -> some View {
        VStack(alignment: .center, spacing: 0) {
            LazyVGrid(columns: columns, alignment: .center, spacing: rowSpacing) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    switch item {
                    case .app(let id):
                        if let app = viewModel.app(for: id) {
                            AppIconView(app: app, iconSize: gridSettings.iconSize, fontSize: gridSettings.appNameFontSize)
                        }
                    case .folder(let folder):
                        FolderIconPlaceholderView(folder: folder, iconSize: gridSettings.iconSize, fontSize: gridSettings.appNameFontSize)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: availableHeight, alignment: .top)
    }

    // MARK: - Pagination helpers

    private func handleScroll(deltaY: CGFloat, totalPages: Int) {
        // 简单节流，避免一次滚动触发多次翻页
        let now = Date()
        guard now.timeIntervalSince(lastScrollTime) > 0.15 else { return }
        lastScrollTime = now

        guard totalPages > 1 else { return }

        let oldPage = currentPage
        var targetPage = currentPage
        var isAtEdge = false

        if deltaY < 0 {
            // Scroll down = next page
            if currentPage < totalPages - 1 {
                targetPage = currentPage + 1
            } else {
                // Already at last page - show bounce effect
                isAtEdge = true
            }
        } else if deltaY > 0 {
            // Scroll up = previous page
            if currentPage > 0 {
                targetPage = currentPage - 1
            } else {
                // Already at first page - show bounce effect
                isAtEdge = true
            }
        }

        if isAtEdge {
            // Bounce effect at edge: small offset then spring back
            let bounceDistance: CGFloat = 30
            let bounceDirection: CGFloat = deltaY < 0 ? -1 : 1
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                dragOffset = bounceDistance * bounceDirection
            }
            
            // Spring back after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    dragOffset = 0
                }
            }
            return
        }

        guard targetPage != oldPage else { return }

        // Use explicit animation to ensure smooth transition
        // Update all related states together within animation block
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            currentPage = targetPage
            // Ensure offsets are reset for clean transition
            if dragOffset != 0 {
                dragOffset = 0
            }
            if pageOffset != 0 {
                pageOffset = 0
            }
        }
        
        print("Launchpad scroll to page =", targetPage, "/", totalPages)
    }

    private func handleDragEnd(direction: SwipePagingCaptureView.SwipeDirection?, totalPages: Int, pageWidth: CGFloat) {
        guard totalPages > 1 else {
            // Reset offset with animation
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                dragOffset = 0
                pageOffset = 0
            }
            isDragging = false
            return
        }

        var shouldChangePage = false
        var targetPage = currentPage

        if let direction = direction {
            switch direction {
            case .left:
                // Swipe left = next page
                if currentPage < totalPages - 1 {
                    targetPage = currentPage + 1
                    shouldChangePage = true
                }
            case .right:
                // Swipe right = previous page
                if currentPage > 0 {
                    targetPage = currentPage - 1
                    shouldChangePage = true
                }
            }
        }

        if shouldChangePage {
            // Change page: maintain visual continuity during transition
            // Current offset: -(currentPage * pageWidth) + dragOffset
            // Target offset: -(targetPage * pageWidth) + 0
            // We need to smoothly transition from current to target
            
            let oldPage = currentPage
            let currentOffset = -(CGFloat(oldPage) * pageWidth) + dragOffset
            let targetOffset = -(CGFloat(targetPage) * pageWidth)
            
            // Set pageOffset to maintain current visual position
            pageOffset = currentOffset - targetOffset
            
            // Update currentPage
            currentPage = targetPage
            print("Launchpad drag to page =", currentPage, "/", totalPages)
            
            // Animate both dragOffset and pageOffset to 0
            // This will smoothly transition from currentOffset to targetOffset
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                dragOffset = 0
                pageOffset = 0
            }
        } else {
            // Reset to current page with smooth bounce-back animation
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                dragOffset = 0
                pageOffset = 0
            }
        }

        isDragging = false
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
    let fontSize: Double

    var body: some View {
        VStack(spacing: 8) {
            iconImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
                .cornerRadius(iconSize * 0.22)
                .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)

            Text(app.name)
                .font(.system(size: fontSize))
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
    let fontSize: Double

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
                .font(.system(size: fontSize))
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


