import Foundation

/// 打字统计信息
struct TypingStats {
    /// 总用时（秒）
    let elapsedTime: TimeInterval
    /// 正确字符数
    let correctCount: Int
    /// 错误字符数
    let errorCount: Int
    /// 总输入字符数
    let totalTyped: Int
    /// 总按键数
    let keystrokeCount: Int
    /// 退格次数
    let backspaceCount: Int
    /// 目标文本长度
    let targetLength: Int
    
    /// 速度（字/分钟）
    var speed: Double {
        guard elapsedTime > 0 else { return 0 }
        return (Double(correctCount) / elapsedTime) * 60
    }
    
    /// 准确率
    var accuracy: Double {
        guard totalTyped > 0 else { return 1.0 }
        return Double(correctCount) / Double(totalTyped)
    }
    
    /// 击键（键/秒）
    var keystrokePerSecond: Double {
        guard elapsedTime > 0 else { return 0 }
        return Double(keystrokeCount) / elapsedTime
    }
    
    /// 进度百分比
    var progress: Double {
        guard targetLength > 0 else { return 0 }
        return Double(totalTyped) / Double(targetLength)
    }
    
    /// 格式化的时间字符串
    var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        if minutes > 0 {
            return "\(minutes)分\(seconds)秒"
        }
        return "\(seconds)秒"
    }
    
    /// 格式化的速度
    var formattedSpeed: String {
        String(format: "%.1f 字/分", speed)
    }
    
    /// 格式化的准确率
    var formattedAccuracy: String {
        String(format: "%.1f%%", accuracy * 100)
    }
    
    /// 格式化的击键
    var formattedKeystroke: String {
        String(format: "%.2f 键/秒", keystrokePerSecond)
    }
}
