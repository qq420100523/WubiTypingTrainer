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
