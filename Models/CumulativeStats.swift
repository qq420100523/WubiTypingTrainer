import Foundation
import Observation

/// 累计统计 — 跨会话持久化
struct CumulativeStatsData: Codable {
    var totalChars: Int       // 累计练习字数
    var correctChars: Int     // 累计正确字数
    var totalTime: TimeInterval  // 累计用时（秒）
}

/// 累计统计管理器
@MainActor
@Observable
final class CumulativeStats {
    private static let fileName = "wubi-cumulative-stats.json"

    private(set) var data: CumulativeStatsData {
        didSet { save() }
    }

    static let shared = CumulativeStats()

    private init() {
        guard let loaded = Self.loadFromFile() else {
            data = CumulativeStatsData(totalChars: 0, correctChars: 0, totalTime: 0)
            return
        }
        data = loaded
    }

    /// 记录一次练习结果
    func record(totalChars: Int, correctChars: Int, time: TimeInterval) {
        var d = data
        d.totalChars += totalChars
        d.correctChars += correctChars
        d.totalTime += time
        data = d
    }

    /// 总正确率
    var accuracy: Double {
        guard data.totalChars > 0 else { return 1.0 }
        return Double(data.correctChars) / Double(data.totalChars)
    }

    /// 平均速度（字/分）
    var averageSpeed: Double {
        guard data.totalTime > 0 else { return 0 }
        return (Double(data.correctChars) / data.totalTime) * 60
    }

    /// 格式化累计用时
    var formattedTime: String {
        let minutes = Int(data.totalTime) / 60
        let seconds = Int(data.totalTime) % 60
        if minutes > 0 {
            return "\(minutes)分\(seconds)秒"
        }
        return "\(seconds)秒"
    }

    /// 重置累计统计
    func reset() {
        data = CumulativeStatsData(totalChars: 0, correctChars: 0, totalTime: 0)
    }

    // MARK: - 文件持久化

    private var persistenceURL: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("WubiTypingTrainer")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(Self.fileName)
    }

    private func save() {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        try? encoded.write(to: persistenceURL, options: .atomic)
    }

    private static func loadFromFile() -> CumulativeStatsData? {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("WubiTypingTrainer")
        let url = dir.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(CumulativeStatsData.self, from: data)
        else { return nil }
        return decoded
    }
}
