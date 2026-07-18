import Foundation
import OSLog

/// 知乎日报文章抓取服务
actor ZhihuDailyService {
    static let shared = ZhihuDailyService()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "WubiTypingTrainer", category: "ZhihuDailyService")

    private let session: URLSession
    private let baseURL = "https://news-at.zhihu.com/api/4"
    /// 每次最多取文章数（防止请求过多）
    private let maxArticles = 10

    private init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        session = URLSession(configuration: config)
    }

    // MARK: - 缓存

    private let cacheKey = "wubi-zhihu-cached-articles"

    /// 获取最新文章（优先走缓存，下次刷新时自动补充新文章）
    func fetchLatest() async -> [ZhihuArticle] {
        // 1. 获取最新文章列表
        guard let stories = await fetchStoryList(), !stories.isEmpty else {
            return []
        }

        // 2. 已有缓存，按 storyId 索引
        let cached = Self.loadCachedArticles()
        var cachedById: [Int: ZhihuArticle] = [:]
        for article in cached {
            cachedById[article.storyId] = article
        }

        // 3. 并发获取详情：只取前 maxArticles 篇，已缓存的跳过
        let toFetch = stories.prefix(maxArticles)
        var results: [ZhihuArticle] = []
        results.reserveCapacity(toFetch.count)

        await withTaskGroup(of: ZhihuArticle?.self) { group in
            for story in toFetch {
                // 已缓存且内容完整 -> 直接复用
                if let cached = cachedById[story.id], !cached.bodyText.isEmpty {
                    group.addTask { cached }
                    continue
                }
                group.addTask {
                    return await self.fetchDetail(story)
                }
            }

            for await result in group {
                if let article = result {
                    results.append(article)
                }
            }
        }

        // 按 storyId 降序（最新的在前）
        results.sort { $0.storyId > $1.storyId }
        cacheArticles(results)
        return results
    }

    /// 获取最新文章列表（只含概要）
    private func fetchStoryList() async -> [ZhihuStorySummary]? {
        guard let url = URL(string: "\(baseURL)/news/latest") else { return nil }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode)
            else { return nil }

            let decoded = try JSONDecoder().decode(ZhihuLatestResponse.self, from: data)
            return decoded.stories
        } catch {
            logger.error("获取列表失败 - \(error.localizedDescription)")
            return nil
        }
    }

    /// 获取单篇文章详情
    private func fetchDetail(_ story: ZhihuStorySummary) async -> ZhihuArticle? {
        guard let url = URL(string: "\(baseURL)/news/\(story.id)") else { return nil }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode)
            else { return nil }

            let decoded = try JSONDecoder().decode(ZhihuStoryDetail.self, from: data)
            let bodyText = Self.extractPlainText(from: decoded.body ?? "")
            guard !bodyText.isEmpty else { return nil }

            return ZhihuArticle(
                id: "zhihu_\(decoded.id)",
                storyId: decoded.id,
                title: decoded.title,
                bodyText: bodyText,
                hint: story.hint ?? "",
                shareUrl: decoded.shareUrl,
                updatedAt: Date()
            )
        } catch {
            logger.error("获取详情失败 [\(story.title)] - \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - HTML 处理

    /// 从知乎日报的 body HTML 中提取纯文本
    static func extractPlainText(from html: String) -> String {
        var text = html

        // 移除 <style>...</style> 和 <script>...</script> 块
        for tag in ["style", "script"] {
            while let start = text.range(of: "<\(tag)", options: .caseInsensitive),
                  let end = text.range(
                      of: "</\(tag)>", options: .caseInsensitive,
                      range: start.upperBound ..< text.endIndex
                  )
            {
                text.removeSubrange(start.lowerBound ..< end.upperBound)
            }
        }

        // 块级标签 -> 换行
        text = text.replacingOccurrences(
            of: "(?i)</?(?:p|div|br|li|h[1-6]|blockquote|tr|section|figure|header|footer)\\b[^>]*>",
            with: "\n", options: .regularExpression
        )

        // 移除所有剩余 HTML 标签
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        // HTML 实体解码
        let entities: [(String, String)] = [
            ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"),
            ("&quot;", "\""), ("&#39;", "'"), ("&#x27;", "'"),
            ("&#34;", "\""), ("&#60;", "<"), ("&#62;", ">"),
            ("&nbsp;", " "), ("&#160;", " "), ("&ldquo;", "「"),
            ("&rdquo;", "」"), ("&mdash;", "—"), ("&ndash;", "–"),
        ]
        for (entity, char) in entities {
            text = text.replacingOccurrences(of: entity, with: char)
        }

        // 压缩多余空白行
        text = text.replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\s{3,}", with: "  ", options: .regularExpression)

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - 持久化

    private func cacheArticles(_ articles: [ZhihuArticle]) {
        guard let data = try? JSONEncoder().encode(articles) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey)
    }

    /// 读取缓存文章
    static func loadCachedArticles() -> [ZhihuArticle] {
        guard let data = UserDefaults.standard.data(forKey: "wubi-zhihu-cached-articles"),
              let articles = try? JSONDecoder().decode([ZhihuArticle].self, from: data)
        else { return [] }
        return articles
    }
}
