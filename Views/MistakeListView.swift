import SwiftUI

/// 错字本视图
@MainActor
struct MistakeListView: View {
    @State private var mistakeTracker = MistakeTracker.shared
    @State private var showClearConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("错字本")
                    .font(.headline)
                Spacer()
                if !mistakeTracker.isEmpty {
                    Text("共 \(mistakeTracker.count) 个错字")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text("记录你输入错误的汉字，方便针对性复习")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()

            if mistakeTracker.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    Text("暂无错字记录")
                        .foregroundColor(.secondary)
                    Text("继续练习，错误的字会自动记录在这里")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(mistakeTracker.sortedMistakes) { entry in
                        HStack(spacing: 12) {
                            Text(entry.char)
                                .font(.system(size: 28, weight: .bold))
                                .frame(width: 44)

                            VStack(alignment: .leading, spacing: 2) {
                                if let code = entry.code {
                                    Text("五笔: \(code.uppercased())")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.blue)
                                } else {
                                    Text("编码未知")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }

                            Spacer()

                            Text("错误 \(entry.count) 次")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.red.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)

                HStack {
                    Spacer()
                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        Label("清空错字本", systemImage: "trash")
                    }
                    .font(.caption)
                    .confirmationDialog("清空错字本", isPresented: $showClearConfirmation) {
                        Button("清空", role: .destructive) { mistakeTracker.clear() }
                        Button("取消", role: .cancel) { }
                    } message: {
                        Text("确定要清空所有错字记录吗？此操作不可撤销。")
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    MistakeListView()
        .frame(width: 400, height: 500)
}
