import SwiftUI

/// 设置视图
@MainActor
struct SettingsView: View {
    @Bindable var viewModel: PracticeViewModel
    @State private var cumulativeStats = CumulativeStats.shared
    @State private var showResetConfirmation = false
    @State private var reloadResult: Bool?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 词库
                sectionHeader(icon: "book.closed", title: "词库")
                dictSection

                Divider()

                // 显示
                sectionHeader(icon: "eye", title: "显示")
                displaySection

                Divider()

                // 累计统计
                sectionHeader(icon: "chart.bar", title: "累计统计")
                statsSection

                Divider()

                // 快捷键
                sectionHeader(icon: "keyboard", title: "快捷键")
                shortcutsSection

                Divider()

                // 关于
                sectionHeader(icon: "info.circle", title: "关于")
                aboutSection
            }
            .padding()
        }
    }

    // MARK: - 通用

    private func sectionHeader(icon: String, title: String) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .foregroundColor(.primary)
    }

    // MARK: - 词库

    private var dictSection: some View {
        HStack {
            if WubiDictionary.shared.isLoaded {
                Label("已加载 \(WubiDictionary.shared.count) 条", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.callout)
            } else {
                Label("未加载", systemImage: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
                    .font(.callout)
            }
            Spacer()
            Group {
                if let result = reloadResult {
                    Text(result ? "✓ 成功" : "✗ 失败")
                        .font(.caption)
                        .foregroundColor(result ? .green : .red)
                        .transition(.opacity)
                } else {
                    Button("重新加载") {
                        let ok = WubiDictionary.shared.loadBuiltin()
                        withAnimation { reloadResult = ok }
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(2))
                            withAnimation { reloadResult = nil }
                        }
                    }
                    .font(.callout)
                }
            }
        }
    }

    // MARK: - 显示

    private var displaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $viewModel.showWubiHints) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("显示五笔编码提示")
                    Text("在输入区上方显示当前字的五笔编码")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Toggle(isOn: $viewModel.limitToGB2312) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("仅显示 GB2312 字符")
                    Text("过滤 GBK 扩展字符")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Toggle(isOn: $viewModel.convertHalfwidthToFullwidth) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("英文符号转中文全角")
                    Text("文章模式下将半角 ,.!?:;() 等转为全角符号")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - 累计统计

    private var statsSection: some View {
        VStack(spacing: 0) {
            // 统计列表 — 使用 LazyVGrid 实现两列布局
            let items: [(String, String)] = [
                ("累计练习", "\(cumulativeStats.data.totalChars) 字"),
                ("累计正确", "\(cumulativeStats.data.correctChars) 字"),
                ("累计用时", cumulativeStats.formattedTime),
                ("总正确率", String(format: "%.1f%%", cumulativeStats.accuracy * 100)),
                ("平均速度", String(format: "%.1f 字/分", cumulativeStats.averageSpeed)),
            ]

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(items, id: \.0) { label, value in
                    HStack(spacing: 4) {
                        Text(label + ":")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(value)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.primary)
                        Spacer(minLength: 0)
                    }
                }
            }

            Divider()
                .padding(.vertical, 8)

            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                Label("重置累计统计", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.plain)
            .confirmationDialog("重置累计统计", isPresented: $showResetConfirmation) {
                Button("重置", role: .destructive) { cumulativeStats.reset() }
                Button("取消", role: .cancel) { }
            } message: {
                Text("确定要重置所有累计统计数据吗？此操作不可撤销。")
            }
        }
    }

    // MARK: - 快捷键

    private var shortcutsSection: some View {
        VStack(spacing: 6) {
            shortcutRow(key: "⌘⇧V", action: "从剪贴板载入文本")
            shortcutRow(key: "⌘R", action: "重新开始")
            shortcutRow(key: "Esc", action: "暂停/继续")
            shortcutRow(key: "⌘,", action: "打开设置")
            shortcutRow(key: "⌘+/⌘-", action: "调整字号")
        }
    }

    private func shortcutRow(key: String, action: String) -> some View {
        HStack(spacing: 12) {
            Text(key)
                .font(.system(.caption, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
                )
                .frame(minWidth: 52, alignment: .leading)

            Text(action)
                .font(.callout)

            Spacer()
        }
    }

    // MARK: - 关于

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("五笔打字练习器 v2.0")
                .font(.body)
            Text("基于五笔86版编码")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("词库来源: rime/rime-wubi (LGPL v3)")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("支持 3000+ 单字、500 词组、27 篇文章")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SettingsView(viewModel: PracticeViewModel())
        .frame(width: 380, height: 700)
}
