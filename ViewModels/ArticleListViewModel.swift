import Foundation
import Observation

/// 文章列表视图模型
/// 管理内置文章、用户自定义文章，支持按需从外部源获取文章
@MainActor
@Observable
final class ArticleListViewModel {
    private(set) var customArticles: [ArticleEntry] = []
    /// 所有外部文章源
    let sources: [any ArticleSource] = [ZhihuDailySource(), YiYueDuSource(), YanSource(), SongCiSource(), TangShiSource(), ShijingSource(), LunyuSource()]
    /// 各源的文章列表 [sourceName: [ArticleEntry]]
    private(set) var sourceArticles: [String: [ArticleEntry]] = [:]
    /// 各源的刷新状态 [sourceName: Bool]
    private(set) var isRefreshing: [String: Bool] = [:]
    /// 各源的错误消息 [sourceName: String?]
    private(set) var sourceErrors: [String: String?] = [:]
    /// 各源的成功消息 [sourceName: String?]  
    private(set) var sourceMessages: [String: String?] = [:]

    private let storageKey = "wubi-custom-articles"

    /// 全部可用文章（内置 + 自定义）
    var allArticles: [ArticleEntry] {
        ArticleData.all + customArticles
    }

    /// 从 UserDefaults 加载自定义文章
    func loadCustomArticles() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let articles = try? JSONDecoder().decode([ArticleEntry].self, from: data)
        else { return }
        customArticles = articles
    }

    /// 将自定义文章持久化到 UserDefaults
    private func saveCustomArticles() {
        guard let data = try? JSONEncoder().encode(customArticles) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    /// 导入一篇自定义文章
    func importCustomArticle(title: String, text: String) -> ArticleEntry? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, trimmedText.count >= 2 else { return nil }

        let article = ArticleEntry(id: "custom_\(Date().timeIntervalSince1970)", title: trimmedTitle, text: trimmedText)
        customArticles.append(article)
        saveCustomArticles()
        return article
    }

    /// 删除一篇自定义文章
    func deleteCustom(_ article: ArticleEntry) {
        customArticles.removeAll { $0.id == article.id }
        saveCustomArticles()
    }

    /// 将外部源文章保存为自定义文章
    func saveSourceArticle(_ entry: ArticleEntry) {
        let savedId = "saved_\(entry.id)"
        let saved = ArticleEntry(id: savedId, title: entry.title, text: entry.text)
        if !customArticles.contains(where: { $0.id == savedId }) {
            customArticles.append(saved)
            saveCustomArticles()
        }
    }

    /// 判断是否为自定义文章
    func isCustom(_ article: ArticleEntry) -> Bool {
        article.id.hasPrefix("custom_") || article.id.hasPrefix("saved_")
    }

    /// 预查询所有源（仅首次无缓存时）
    func prefetchAll() {
        for source in sources where sourceArticles[source.name] == nil {
            fetch(source: source)
        }
    }

    // MARK: - 外部源管理

    /// 获取某个源的文章列表
    func articles(for sourceName: String) -> [ArticleEntry] {
        sourceArticles[sourceName] ?? []
    }

    /// 刷新指定外部源
    func fetch(source: any ArticleSource) {
        let name = source.name
        guard !(isRefreshing[name] ?? false) else { return }
        isRefreshing[name] = true
        sourceErrors[name] = nil

        Task {
            let articles = await source.fetch()
            await MainActor.run {
                sourceArticles[name] = articles
                isRefreshing[name] = false
                if articles.isEmpty {
                    sourceErrors[name] = "获取失败，请检查网络连接后重试"
                    sourceMessages[name] = nil
                } else {
                    sourceMessages[name] = "已获取 \(articles.count) 篇\(name)文章"
                    sourceErrors[name] = nil
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        sourceMessages[name] = nil
                    }
                }
            }
        }
    }
}
