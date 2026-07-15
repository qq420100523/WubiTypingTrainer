import Foundation
import Observation

/// 错字记录
struct MistakeEntry: Codable, Identifiable {
    let char: String
    let code: String?
    var count: Int

    var id: String { char }
}

/// 错字本 — 记录输入错误的汉字，支持持久化
@MainActor
@Observable
final class MistakeTracker {
    private static let fileName = "wubi-mistakes.json"

    private(set) var mistakes: [String: MistakeEntry] = [:] {
        didSet { scheduleSave() }
    }

    static let shared = MistakeTracker()

    private var saveTask: Task<Void, Never>?

    private init() {
        load()
    }

    /// 记录一次错误
    func recordMistake(for char: Character, code: String?) {
        let key = String(char)
        if var entry = mistakes[key] {
            entry.count += 1
            mistakes[key] = entry
        } else {
            mistakes[key] = MistakeEntry(char: key, code: code, count: 1)
        }
    }

    /// 记录一次正确（减少错字计数）
    func recordCorrect(for char: Character) {
        let key = String(char)
        guard var entry = mistakes[key] else { return }
        entry.count -= 1
        if entry.count <= 0 {
            mistakes.removeValue(forKey: key)
        } else {
            mistakes[key] = entry
        }
    }

    /// 获取按错误次数降序排列的错字列表
    var sortedMistakes: [MistakeEntry] {
        mistakes.values.sorted { $0.count > $1.count }
    }

    /// 错字数量
    var count: Int { mistakes.count }

    /// 清空错字本
    func clear() {
        mistakes = [:]
        save()
    }

    /// 是否有错字
    var isEmpty: Bool { mistakes.isEmpty }

    // MARK: - 持久化（文件 + 防抖）

    private var persistenceURL: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("WubiTypingTrainer")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(Self.fileName)
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(0.5))
            self?.save()
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(mistakes) else { return }
        try? data.write(to: persistenceURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: persistenceURL),
              let dict = try? JSONDecoder().decode([String: MistakeEntry].self, from: data)
        else { return }
        mistakes = dict
    }
}
