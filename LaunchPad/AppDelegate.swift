//
//  AppDelegate.swift
//  LaunchPad
//
//  Created by ex_liuzp9 on 2025/11/26.
//

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    private var keyEventMonitor: Any?
    private var isLaunchpadVisible = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let win = NSApp.windows.first else { return }
        self.window = win
        showLaunchpad(animated: true)
        startKeyMonitor()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        // 当重新激活 app 时，如果当前没有显示 launchpad 窗口，则再次展示
        guard let win = window ?? NSApp.windows.first else { return }
        window = win
        if !isLaunchpadVisible {
            showLaunchpad(animated: true)
        }
    }

    // MARK: - Fake fullscreen (enter)

    /// 配置窗口为“伪全屏 Launchpad”样式（不含动画）
    private func configureLaunchpadWindow(_ window: NSWindow) {
        // Hide macOS menu bar and Dock
        NSMenu.setMenuBarVisible(false)
        NSApp.presentationOptions = [.hideDock, .hideMenuBar]

        // Allow window to appear above other spaces (no new desktop)
        window.collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces]

        // Remove system fullscreen
        window.collectionBehavior.remove(.fullScreenPrimary)

        // Hide title bar
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.styleMask.remove(.titled)

        // Resize to fill the screen
        if let screen = NSScreen.main {
            window.setFrame(screen.frame, display: true, animate: false)
        }

        window.level = .normal
        window.isOpaque = false
        window.hasShadow = false
    }

    /// 展示 Launchpad 窗口，可选淡入动画
    private func showLaunchpad(animated: Bool) {
        guard let window = self.window ?? NSApp.windows.first else { return }
        self.window = window

        configureLaunchpadWindow(window)

        let presentWindow = {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }

        if animated {
            window.alphaValue = 0
            presentWindow()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().alphaValue = 1
            }
        } else {
            window.alphaValue = 1
            presentWindow()
        }

        isLaunchpadVisible = true
    }

    // MARK: - Keyboard handling

    /// 监听键盘事件：Esc 或 空格 用于退出伪全屏 / 最小化
    private func startKeyMonitor() {
        keyEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDown(event)
            return event
        }
    }

    private func handleKeyDown(_ event: NSEvent) {
        guard let window = self.window else { return }

        switch event.keyCode {
        case 53: // Esc
            // 优雅地退出伪全屏：淡出并隐藏窗口 / App
            exitFakeFullscreenAndDismiss(window)
        case 49: // Space
            // 只恢复菜单栏和 Dock（保留窗口）
            exitFakeFullscreen(window)
        default:
            break
        }
    }

    // MARK: - Exit fake fullscreen (leave)

    /// 恢复菜单栏和 Dock，但不改窗口大小
    private func exitFakeFullscreen(_ window: NSWindow) {
        NSMenu.setMenuBarVisible(true)
        NSApp.presentationOptions = []
    }

    /// 优雅地退出伪全屏：淡出当前窗口，然后恢复菜单栏 / Dock，并隐藏窗口
    private func exitFakeFullscreenAndDismiss(_ window: NSWindow) {
        isLaunchpadVisible = false
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            guard let self = self else { return }
            self.exitFakeFullscreen(window)
            window.alphaValue = 1
            window.orderOut(nil)
            NSApp.hide(nil)
        }
    }
}


