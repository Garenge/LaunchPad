//
//  AppDelegate.swift
//  LaunchPad
//
//  Created by ex_liuzp9 on 2025/11/26.
//

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow?
    private var keyEventMonitor: Any?
    private var isLaunchpadVisible = false
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        if let monitor = keyEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 使用窗口生命周期回调替代固定延迟：
        // 监听第一个主窗口出现的时机，再进行全屏配置和动画
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFirstWindowDidBecomeMain(_:)),
            name: NSWindow.didBecomeMainNotification,
            object: nil
        )
    }

    /// 第一个 SwiftUI 窗口真正成为主窗口时的回调
    @objc private func handleFirstWindowDidBecomeMain(_ notification: Notification) {
        guard let win = notification.object as? NSWindow else { return }

        // 只对第一次出现的窗口做 Launchpad 配置，避免重复处理
        if self.window != nil { return }

        self.window = win
        win.delegate = self

        // 立即配置为 Launchpad 伪全屏
        configureLaunchpadWindow(win)

        // 然后再执行带动画的展示
        showLaunchpad(animated: true)
        startKeyMonitor()
        startNotificationObserver()
    }
    
    /// 监听来自 ContentView 的点击背景退出通知
    private func startNotificationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDismissLaunchpad),
            name: NSNotification.Name("DismissLaunchpad"),
            object: nil
        )
    }
    
    @objc private func handleDismissLaunchpad() {
        guard let window = self.window else { return }
        exitFakeFullscreenAndDismiss(window)
    }

    /// 当用户点击 Dock 图标重新打开应用时，接管系统默认行为，避免额外创建“小窗口”
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            // 没有可见窗口时，重新展示我们的 Launchpad 全屏窗口
            showLaunchpad(animated: true)
        } else if let existing = window {
            // 已经有缓存窗口时，确保它是全屏 Launchpad 状态
            self.window = existing
            configureLaunchpadWindow(existing)
            existing.makeKeyAndOrderFront(nil)
        }

        // 返回 false 告诉系统：“我已经处理好了”，不要再自动帮我创建新窗口
        return false
    }

    // MARK: - Fake fullscreen (enter)

    /// 配置窗口为"伪全屏 Launchpad"样式（不含动画）
    private func configureLaunchpadWindow(_ window: NSWindow) {
        // Hide macOS menu bar and Dock
        NSMenu.setMenuBarVisible(false)
        NSApp.presentationOptions = [.hideDock, .hideMenuBar]

        // Allow window to appear on all spaces (不创建新的桌面 Space)
        window.collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces]

        // Remove system fullscreen
        window.collectionBehavior.remove(.fullScreenPrimary)

        // 配置为无边框、全内容视图的覆盖层窗口，避免看起来像普通"窗口"
        window.styleMask = [.borderless, .fullSizeContentView]
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true

        // 作为覆盖层存在，但不创建新的 Space
        window.level = .normal
        window.isOpaque = false
        window.hasShadow = false
        window.backgroundColor = .clear

        // 强制设置为全屏：使用主屏幕的完整 frame
        if let screen = NSScreen.main {
            let screenFrame = screen.frame
            // 确保窗口完全覆盖屏幕，包括菜单栏区域
            window.setFrame(screenFrame, display: true, animate: false)
            // 禁用窗口大小调整，确保保持全屏
            window.styleMask.remove(.resizable)
            // 多次强制设置，确保生效
            DispatchQueue.main.async {
                window.setFrame(screenFrame, display: true, animate: false)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                window.setFrame(screenFrame, display: true, animate: false)
            }
        }
    }

    /// 展示 Launchpad 窗口，可选淡入动画
    private func showLaunchpad(animated: Bool) {
        // 统一使用同一个窗口作为 Launchpad 覆盖层
        var targetWindow: NSWindow?

        if let stored = self.window {
            targetWindow = stored
        } else if let main = NSApp.mainWindow {
            targetWindow = main
            self.window = main
        } else if let first = NSApp.windows.first {
            targetWindow = first
            self.window = first
        }

        guard let window = targetWindow else { return }

        // 关闭其它可见窗口，避免出现一个全屏一个小窗口的情况
        for win in NSApp.windows where win != window && win.isVisible {
            win.close()
        }

        configureLaunchpadWindow(window)
        
        // 在显示前再次强制设置全屏
        if let screen = NSScreen.main {
            window.setFrame(screen.frame, display: true, animate: false)
        }

        let presentWindow = {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            
            // 窗口显示后，立即再次强制确保全屏
            if let screen = NSScreen.main {
                window.setFrame(screen.frame, display: true, animate: false)
                // 再延迟一点，确保生效
                DispatchQueue.main.async {
                    window.setFrame(screen.frame, display: true, animate: false)
                }
            }
        }

        if animated {
            window.alphaValue = 0
            presentWindow()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().alphaValue = 1
            } completionHandler: {
                // 动画完成后，再次确保窗口是全屏的
                if let screen = NSScreen.main {
                    window.setFrame(screen.frame, display: true, animate: false)
                    // 再次延迟确保生效
                    DispatchQueue.main.async {
                        window.setFrame(screen.frame, display: true, animate: false)
                    }
                }
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
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            guard let self = self else { return }
            self.exitFakeFullscreen(window)
            window.alphaValue = 0
            window.orderOut(nil)
            self.isLaunchpadVisible = false
        }
    }
}


