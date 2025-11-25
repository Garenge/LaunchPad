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
            Color.black
                .ignoresSafeArea()
            Text("Fake Fullscreen Window")
                .foregroundColor(.white)
                .font(.largeTitle)
        }
    }
}

#Preview {
    ContentView()
}
