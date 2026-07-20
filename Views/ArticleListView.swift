import SwiftUI

/// 文章选择列表视图
/// 支持选择内置文章、导入自定义文章
@MainActor
struct ArticleListView: View {
    @Bindable var viewModel: PracticeViewModel
    var articleListVM: ArticleListViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showImportSheet = false
    @State private var importTitle = ""
    @State private var importText = ""

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

            if articleListVM.allArticles.isEmpty {
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
                    Section("内置文章") {
                        ForEach(articleListVM.allArticles) { article in
                            articleRow(article)
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
            articleListVM.loadCustomArticles()
        }
    }

    // MARK: - 文章行

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
                    if articleListVM.isCustom(article) {
                        Text("自定义")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    Spacer()
                    if articleListVM.isCustom(article) {
                        Button(role: .destructive) {
                            articleListVM.deleteCustom(article)
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
            if articleListVM.isCustom(article) {
                Button("删除", role: .destructive) {
                    articleListVM.deleteCustom(article)
                }
            }
        }
    }

    // MARK: - 导入 sheet

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
                    if let _ = articleListVM.importCustomArticle(title: importTitle, text: importText) {
                        importTitle = ""
                        importText = ""
                        showImportSheet = false
                    }
                }
                .keyboardShortcut(.return)
                .disabled(importTitle.trimmingCharacters(in: .whitespaces).isEmpty ||
                          importText.trimmingCharacters(in: .whitespaces).count < 2)
            }
        }
        .padding()
        .frame(width: 400, height: 350)
    }
}

#Preview {
    ArticleListView(viewModel: PracticeViewModel(), articleListVM: ArticleListViewModel())
}
