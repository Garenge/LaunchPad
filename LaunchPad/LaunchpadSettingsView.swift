//
//  LaunchpadSettingsView.swift
//  LaunchPad
//
//  Simple settings panel for grid layout: rows, columns and margins.
//

import SwiftUI

struct LaunchpadSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var gridSettings = LaunchpadGridSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Launchpad 布局设置")
                    .font(.headline)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("关闭设置")
            }

            HStack {
                Text("每行图标数")
                Spacer()
                Stepper(value: $gridSettings.columnsPerRow, in: 4...10) {
                    Text("\(gridSettings.columnsPerRow)")
                        .frame(width: 40, alignment: .trailing)
                }
                .frame(width: 140)
            }

            HStack {
                Text("每页行数")
                Spacer()
                Stepper(value: $gridSettings.rowsPerPage, in: 2...6) {
                    Text("\(gridSettings.rowsPerPage)")
                        .frame(width: 40, alignment: .trailing)
                }
                .frame(width: 140)
            }

            Divider()

            Group {
                HStack {
                    Text("左右边距")
                    Spacer()
                    Slider(value: $gridSettings.horizontalMargin, in: 40...400, step: 4)
                        .frame(width: 160)
                    Text("\(Int(gridSettings.horizontalMargin))")
                        .frame(width: 40, alignment: .trailing)
                }

                HStack {
                    Text("上下边距")
                    Spacer()
                    Slider(value: $gridSettings.verticalMargin, in: 80...260, step: 4)
                        .frame(width: 160)
                    Text("\(Int(gridSettings.verticalMargin))")
                        .frame(width: 40, alignment: .trailing)
                }
            }

            Divider()

            Group {
                HStack {
                    Text("图标大小")
                    Spacer()
                    Slider(value: $gridSettings.iconSize, in: 32...128, step: 2)
                        .frame(width: 160)
                    Text("\(Int(gridSettings.iconSize))")
                        .frame(width: 40, alignment: .trailing)
                }

                HStack {
                    Text("字体大小")
                    Spacer()
                    Slider(value: $gridSettings.appNameFontSize, in: 8...20, step: 0.5)
                        .frame(width: 160)
                    Text("\(Int(gridSettings.appNameFontSize))")
                        .frame(width: 40, alignment: .trailing)
                }
            }

            Spacer()

            Text("提示：设置会实时生效，并自动保存到本地。")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(width: 380, height: 340)
    }
}

#Preview {
    LaunchpadSettingsView()
}


