import SwiftUI

/// 文章选择视图
@MainActor
struct ArticleListView: View {
    @Bindable var viewModel: PracticeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var customArticles: [ArticleEntry] = []
    @State private var showImportSheet = false
    @State private var importTitle = ""
    @State private var importText = ""

    // 知乎日报相关
    @State private var zhihuArticles: [ZhihuArticle] = []
    @State private var isRefreshingZhihu = false
    @State private var zhihuError: String?

    private let storageKey = "wubi-custom-articles"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(.accentColor)
                Text("选择练习文章")
                    .font(.headline)
                Spacer()
                Button("导入文章") {
                    showImportSheet.toggle()
                }
                .font(.caption)
            }

            Divider()

            if allArticles.isEmpty && zhihuArticles.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "text.alignleft")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("暂无可用文章")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    // MARK: - 内置 & 自定义文章

                    Section("内置文章") {
                        ForEach(allArticles) { article in
                            articleRow(article)
                        }
                    }

                    // MARK: - 知乎日报文章

                    Section {
                        if isRefreshingZhihu {
                            HStack {
                                Spacer()
                                ProgressView("正在获取知乎日报…")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        } else if let error = zhihuError {
                            HStack {
                                Spacer()
                                VStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.orange)
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Button("重试", action: refreshZhihu)
                                        .font(.caption)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        } else if zhihuArticles.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 4) {
                                    Image(systemName: "newspaper")
                                        .foregroundColor(.secondary)
                                    Text("暂无知乎日报文章，点击刷新获取")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Button("刷新", action: refreshZhihu)
                                        .font(.caption)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        } else {
                            ForEach(zhihuArticles) { article in
                                Button(action: {
                                    viewModel.startArticle(article.asArticleEntry)
                                    dismiss()
                                }) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(article.title)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            .lineLimit(2)
                                        HStack(spacing: 8) {
                                            Text("知乎日报")
                                                .font(.caption2)
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(Color.green.opacity(0.1))
                                                .foregroundColor(.green)
                                                .clipShape(RoundedRectangle(cornerRadius: 3))
                                            Text(article.bodyText.count > 0 ? "\(article.bodyText.count) 字" : "")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(article.updatedAt, style: .date)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(.vertical, 2)
                            }
                        }
                    } header: {
                        HStack {
                            Text("知乎日报")
                            if !isRefreshingZhihu {
                                Button(action: refreshZhihu) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                                .help("刷新知乎日报")
                            }
                            Spacer()
                        }
                    }


                }
                .listStyle(.sidebar)
            }
        }
        .padding()
        .frame(width: 440, height: 480)
        .sheet(isPresented: $showImportSheet) {
            importSheet
        }
        .onAppear {
            loadCustomArticles()
            loadZhihu()
        }
    }

    // MARK: - 文章行（内置 & 自定义）

    private func articleRow(_ article: ArticleEntry) -> some View {
        Button(action: {
            viewModel.startArticle(article)
            dismiss()
        }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(article.title)
                        .font(.body)
                        .foregroundColor(.primary)
                    if isCustom(article) {
                        Text("自定义")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    Spacer()
                    if isCustom(article) {
                        Button(role: .destructive) {
                            deleteCustom(article)
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .help("删除此文章")
                    }
                }
                Text("\(article.text.count) 字")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
        .contextMenu {
            if isCustom(article) {
                Button("删除", role: .destructive) {
                    deleteCustom(article)
                }
            }
        }
    }

    private var allArticles: [ArticleEntry] {
        ArticleData.all + customArticles
    }

    // MARK: - 知乎日报

    private func loadZhihu() {
        zhihuArticles = ZhihuDailyService.loadCachedArticles()
        if zhihuArticles.isEmpty {
            refreshZhihu()
        }
    }

    private func refreshZhihu() {
        isRefreshingZhihu = true
        zhihuError = nil

        Task {
            let articles = await ZhihuDailyService.shared.fetchLatest()
            await MainActor.run {
                zhihuArticles = articles
                isRefreshingZhihu = false
                if articles.isEmpty {
                    zhihuError = "获取知乎日报失败，请检查网络连接后重试"
                }
            }
        }
    }

    private func isCustom(_ article: ArticleEntry) -> Bool {
        article.id.hasPrefix("custom_")
    }

    // MARK: - 导入表单

    private var importSheet: some View {
        VStack(spacing: 16) {
            Text("导入自定义文章")
                .font(.headline)

            TextField("文章标题", text: $importTitle)
                .textFieldStyle(.roundedBorder)

            TextEditor(text: $importText)
                .font(.system(size: 14, design: .monospaced))
                .frame(minHeight: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack {
                Text("字数: \(importText.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("取消") {
                    showImportSheet = false
                }
                .keyboardShortcut(.escape)

                Button("导入") {
                    importCustomArticle()
                }
                .keyboardShortcut(.return)
                .disabled(importTitle.trimmingCharacters(in: .whitespaces).isEmpty ||
                          importText.trimmingCharacters(in: .whitespaces).count < 2)
            }
        }
        .padding()
        .frame(width: 400, height: 350)
    }

    // MARK: - 持久化

    private func loadCustomArticles() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let articles = try? JSONDecoder().decode([ArticleEntry].self, from: data)
        else { return }
        customArticles = articles
    }

    private func saveCustomArticles() {
        guard let data = try? JSONEncoder().encode(customArticles) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func importCustomArticle() {
        let title = importTitle.trimmingCharacters(in: .whitespaces)
        let text = importText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, text.count >= 2 else { return }

        let article = ArticleEntry(id: "custom_\(Date().timeIntervalSince1970)", title: title, text: text)
        customArticles.append(article)
        saveCustomArticles()

        importTitle = ""
        importText = ""
        showImportSheet = false
    }

    private func deleteCustom(_ article: ArticleEntry) {
        customArticles.removeAll { $0.id == article.id }
        saveCustomArticles()
    }
}

#Preview {
    ArticleListView(viewModel: PracticeViewModel())
}
