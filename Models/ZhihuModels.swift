import Foundation

// MARK: - API 响应模型

/// 知乎日报 API 响应 — 最新文章列表
struct ZhihuLatestResponse: Codable {
    let date: String
    let stories: [ZhihuStorySummary]
    let topStories: [ZhihuStorySummary]?

    enum CodingKeys: String, CodingKey {
        case date, stories
        case topStories = "top_stories"
    }
}

/// 知乎日报文章概要
struct ZhihuStorySummary: Codable, Identifiable {
    let id: Int
    let title: String
    let hint: String?
    let images: [String]?
    let image: String?
    let url: String?
}

/// 知乎日报 API 响应 — 文章详情
struct ZhihuStoryDetail: Codable {
    let id: Int
    let title: String
    let body: String?
    let image: String?
    let imageSource: String?
    let shareUrl: String?
    let css: [String]?

    enum CodingKeys: String, CodingKey {
        case id, title, body, image, css
        case imageSource = "image_source"
        case shareUrl = "share_url"
    }
}

// MARK: - 处理后用于练习的模型

/// 处理后的知乎日报文章，可直接转换为 ArticleEntry 供练习使用
struct ZhihuArticle: Codable, Identifiable {
    let id: String
    let storyId: Int
    let title: String
    let bodyText: String
    let hint: String
    let shareUrl: String?
    let updatedAt: Date

    /// 转换为供练习引擎使用的 ArticleEntry
    var asArticleEntry: ArticleEntry {
        ArticleEntry(id: "zhihu_\(storyId)", title: "[知乎日报] \(title)", text: bodyText)
    }
}

// MARK: - 文章源协议

/// 外部文章源协议
protocol ArticleSource: Equatable {
    var name: String { get }
    var icon: String { get }
    func fetch() async -> [ArticleEntry]
}

/// 知乎日报文章源
struct ZhihuDailySource: ArticleSource {
    let name = "知乎日报"
    let icon = "newspaper"

    func fetch() async -> [ArticleEntry] {
        let articles = await ZhihuDailyService.shared.fetchLatest()
        return articles.map { $0.asArticleEntry }
    }
}

/// 宋词三百首源（从 GitHub 开源数据获取随机词篇）
struct SongCiSource: ArticleSource {
    let name = "宋词三百首"
    let icon = "music.note.list"

    func fetch() async -> [ArticleEntry] {
        guard let url = URL(string: "https://raw.githubusercontent.com/chinese-poetry/chinese-poetry/master/%E5%AE%8B%E8%AF%8D/%E5%AE%8B%E8%AF%8D%E4%B8%89%E7%99%BE%E9%A6%96.json"),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let poems = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return [] }
        return poems.shuffled().prefix(5).compactMap { item in
            guard let rhythmic = item["rhythmic"] as? String,
                  let author = item["author"] as? String,
                  let paras = item["paragraphs"] as? [String],
                  !paras.isEmpty
            else { return nil }
            let text = paras.joined(separator: "\n")
            let id = "songci_\(UUID().uuidString.prefix(8))"
            return ArticleEntry(id: id, title: "《\(rhythmic)》- \(author)", text: text)
        }
    }
}

/// 诗经源（从 GitHub 开源数据获取随机篇目）
struct ShijingSource: ArticleSource {
    let name = "诗经"
    let icon = "book.pages"

    func fetch() async -> [ArticleEntry] {
        guard let url = URL(string: "https://raw.githubusercontent.com/chinese-poetry/chinese-poetry/master/%E8%AF%97%E7%BB%8F/shijing.json"),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let poems = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return [] }
        let shuffled = poems.shuffled().prefix(5)
        return shuffled.compactMap { poem in
            guard let title = poem["title"] as? String,
                  let content = poem["content"] as? [String],
                  !content.isEmpty
            else { return nil }
            let text = content.joined(separator: "\n")
            let id = "shijing_\(UUID().uuidString.prefix(8))"
            return ArticleEntry(id: id, title: "《\(title)》", text: text)
        }
    }
}

/// 论语源（从 GitHub 开源数据获取随机章节）
struct LunyuSource: ArticleSource {
    let name = "论语"
    let icon = "books.vertical"

    func fetch() async -> [ArticleEntry] {
        guard let url = URL(string: "https://raw.githubusercontent.com/chinese-poetry/chinese-poetry/master/%E8%AE%BA%E8%AF%AD/lunyu.json"),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let chapters = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return [] }
        let shuffled = chapters.shuffled().prefix(3)
        return shuffled.compactMap { chapter in
            guard let ch = chapter["chapter"] as? String,
                  let paragraphs = chapter["paragraphs"] as? [String],
                  !paragraphs.isEmpty
            else { return nil }
            let text = paragraphs.joined(separator: "\n")
            let id = "lunyu_\(UUID().uuidString.prefix(8))"
            return ArticleEntry(id: id, title: ch, text: text)
        }
    }
}

/// 易阅读源（从 yuedu.owenyang.top 获取随机散文/小说）
struct YiYueDuSource: ArticleSource {
    let name = "每日一文"
    let icon = "text.alignleft"

    func fetch() async -> [ArticleEntry] {
        guard let url = URL(string: "https://yuedu.owenyang.top/article"),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let html = String(data: data, encoding: .utf8)
        else { return [] }

        let paragraphs = extractParagraphs(html)
        guard paragraphs.count >= 2 else { return [] }

        let title = extractTitle(html)
        let authorLine = paragraphs.first ?? ""
        let body = paragraphs.dropFirst().joined(separator: "\n\n")

        let id = "yuedu_\(UUID().uuidString.prefix(8))"
        var displayTitle = title
        if displayTitle.isEmpty { displayTitle = "每日一文" }
        return [ArticleEntry(id: id, title: displayTitle, text: body)]
    }

    private func extractTitle(_ html: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "<title>(.*?)\\s*\\|\\s*易阅读"),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              match.numberOfRanges >= 2,
              let r = Range(match.range(at: 1), in: html)
        else { return "" }
        return String(html[r]).trimmingCharacters(in: .whitespaces)
    }

    private func extractParagraphs(_ html: String) -> [String] {
        let cleaned = html
            .replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?<\\/script>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?<\\/style>", with: "", options: .regularExpression)
        guard let regex = try? NSRegularExpression(pattern: "<p>(.*?)</p>", options: .dotMatchesLineSeparators)
        else { return [] }
        let range = NSRange(cleaned.startIndex..., in: cleaned)
        let matches = regex.matches(in: cleaned, range: range)
        return matches.compactMap { m in
            guard m.numberOfRanges >= 2,
                  let r = Range(m.range(at: 1), in: cleaned)
            else { return nil }
            let raw = String(cleaned[r])
            let text = raw.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : text
        }
    }
}

/// 一言名言源（从 api.xygeng.cn 获取随机名言警句）
struct YanSource: ArticleSource {
    let name = "一言"
    let icon = "quote.opening"

    func fetch() async -> [ArticleEntry] {
        var entries: [ArticleEntry] = []
        var seen = Set<String>()
            for _ in 0..<5 {
            try? await Task.sleep(for: .milliseconds(200))
            guard let entry = await fetchOne(), seen.insert(entry.id).inserted
            else { continue }
            entries.append(entry)
        }
        return entries
    }

    private func fetchOne() async -> ArticleEntry? {
        guard let url = URL(string: "https://api.xygeng.cn/one"),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let d = json["data"] as? [String: Any],
              let content = d["content"] as? String,
              !content.isEmpty
        else { return nil }
        let tag = d["tag"] as? String ?? ""
        let author = d["name"] as? String ?? "佚名"
        let title = tag.isEmpty ? "一言" : "「\(tag)」"
        let text = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let id = "yan_\(UUID().uuidString.prefix(8))"
        return ArticleEntry(id: id, title: "\(title) - \(author)", text: text)
    }
}

/// 唐诗三百首源（从 GitHub 开源数据获取随机诗篇）
struct TangShiSource: ArticleSource {
    let name = "唐诗三百首"
    let icon = "book.closed"

    func fetch() async -> [ArticleEntry] {
        guard let url = URL(string: "https://raw.githubusercontent.com/chinese-poetry/chinese-poetry/master/%E8%92%99%E5%AD%A6/tangshisanbaishou.json"),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let categories = root["content"] as? [[String: Any]]
        else { return [] }
        var poems: [[String: Any]] = []
        for cat in categories {
            if let items = cat["content"] as? [[String: Any]] {
                poems.append(contentsOf: items)
            }
        }
        return poems.shuffled().prefix(5).compactMap { item in
            guard let title = item["chapter"] as? String,
                  let author = item["author"] as? String,
                  let paras = item["paragraphs"] as? [String],
                  !paras.isEmpty
            else { return nil }
            let text = paras.joined(separator: "\n")
            let id = "tangshi_\(UUID().uuidString.prefix(8))"
            return ArticleEntry(id: id, title: "《\(title)》- \(author)", text: text)
        }
    }
}
