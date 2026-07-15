import SwiftUI

/// 练习模式选择器 — 显示所有可用模式的按钮行
struct ModeSelectorView: View {
    @Bindable var viewModel: PracticeViewModel
    @State private var showModeConfirmation = false
    @State private var pendingMode: PracticeMode?

    private let modes: [PracticeMode] = [
        .random, .zone1, .zone2, .zone3, .zone4, .zone5,
        .common, .mistakes, .phrase, .article,
    ]

    private var sessionHasActivity: Bool {
        viewModel.session.startTime != nil || viewModel.session.typedText.count > 0
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(modes) { mode in
                    Button(action: {
                        if mode != viewModel.session.mode, sessionHasActivity {
                            viewModel.suspendTimer()
                            pendingMode = mode
                            showModeConfirmation = true
                        } else {
                            viewModel.setMode(mode)
                        }
                    }) {
                        Text(mode.rawValue)
                            .font(.caption.weight(viewModel.session.mode == mode ? .semibold : .regular))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                viewModel.session.mode == mode
                                    ? Color.accentColor
                                    : Color(nsColor: .controlBackgroundColor)
                            )
                            .foregroundColor(
                                viewModel.session.mode == mode
                                    ? Color(nsColor: .alternateSelectedControlTextColor)
                                    : .primary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(
                                        viewModel.session.mode == mode
                                            ? Color.accentColor
                                            : Color(nsColor: .separatorColor),
                                        lineWidth: viewModel.session.mode == mode ? 1.5 : 0.5
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(viewModel.session.mode == mode ? .isSelected : [])
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 6)
        .confirmationDialog("切换模式", isPresented: $showModeConfirmation) {
            Button("切换", role: .destructive) {
                if let mode = pendingMode { viewModel.setMode(mode) }
            }
            Button("取消", role: .cancel) {
                viewModel.resumeTimer()
                pendingMode = nil
            }
        } message: {
            Text("当前练习进度将会丢失，确定要切换模式吗？")
        }
    }
}

#Preview {
    ModeSelectorView(viewModel: PracticeViewModel())
        .frame(width: 500)
        .padding()
}
