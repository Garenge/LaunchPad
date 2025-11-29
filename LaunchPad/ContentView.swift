//
//  ContentView.swift
//  LaunchPad
//
//  Created by ex_liuzp9 on 2025/11/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            // 背景层：毛玻璃 + 轻微遮罩，点击背景可退出（类似系统 Launchpad）
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                
                Color.black.opacity(0.03)
                    .ignoresSafeArea()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // 点击背景时，发送通知退出 Launchpad（和 Esc 效果一样）
                NotificationCenter.default.post(name: NSNotification.Name("DismissLaunchpad"), object: nil)
            }
            
            // 内容层
            Text("Fake Fullscreen Window")
                .foregroundColor(.white)
                .font(.largeTitle)
        }
    }
}

#Preview {
    ContentView()
}
