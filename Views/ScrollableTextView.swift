import SwiftUI
import AppKit

/// 可编程滚动的文本视图 — 使用 NSScrollView + NSTextView 实现精确 Y 坐标滚动
/// 支持增量属性更新：每次击键只修改变色字符和光标位置，避免全量重建 + 布局
struct ScrollableTextView: NSViewRepresentable {
    let attributedText: NSAttributedString
    /// 光标在字符数组中的索引（用于定位滚动）
    var cursorPosition: Int
    var textVersion: Int
    /// 外观版本号（深/浅色切换时由 SwiftUI 侧递增）
    var appearanceVersion: Int
    var fontSize: CGFloat = 18
    /// 最近发生变化的字符索引（-1 = 需要全量重建）
    var changedIndex: Int = -1

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.textContainer?.lineFragmentPadding = 0
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        scrollView.documentView = textView
        context.coordinator.textView = textView
        context.coordinator.scrollView = scrollView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView,
              let ts = textView.textStorage else { return }

        let fullLength = attributedText.length

        // --- 全量重建 vs 增量更新 ---
        if context.coordinator.isFirstUpdate || changedIndex < 0
            || appearanceVersion != context.coordinator.lastAppearanceVersion {
            ts.setAttributedString(attributedText)
            textView.layoutManager?.ensureLayout(for: textView.textContainer!)
            context.coordinator.isFirstUpdate = false
            context.coordinator.lastAppearanceVersion = appearanceVersion
        } else {
            // 增量更新：仅修改刚输入字符的颜色
            if changedIndex >= 0 && changedIndex < fullLength {
                let newAttrs = attributedText.attributes(at: changedIndex, effectiveRange: nil)
                ts.setAttributes(newAttrs, range: NSRange(location: changedIndex, length: 1))
            }
        }

        // 清除旧光标下划线
        let oldCursor = context.coordinator.lastCursorPosition
        if oldCursor >= 0 && oldCursor < fullLength && oldCursor != cursorPosition {
            let oldRange = NSRange(location: oldCursor, length: 1)
            ts.removeAttribute(.underlineStyle, range: oldRange)
            ts.removeAttribute(.underlineColor, range: oldRange)
            let oldAttrs = attributedText.attributes(at: oldCursor, effectiveRange: nil)
            if let fg = oldAttrs[.foregroundColor] as? NSColor {
                ts.addAttribute(.foregroundColor, value: fg, range: oldRange)
            }
        }

        // 设置新光标下划线
        if cursorPosition >= 0 && cursorPosition < fullLength {
            let cursorRange = NSRange(location: cursorPosition, length: 1)
            ts.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: cursorRange)
            let resolvedAccent = NSColor.resolve { NSColor.controlAccentColor }
            ts.addAttribute(.underlineColor, value: resolvedAccent, range: cursorRange)
        }

        context.coordinator.lastCursorPosition = cursorPosition

        // 只在文本版本变化时（即真正输入了新字）才强制滚动
        guard textVersion != context.coordinator.lastTextVersion else { return }
        context.coordinator.lastTextVersion = textVersion

        // 用 NSTextView 自身 API 获取光标准确 Y 坐标
        guard let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }

        let glyphRange = layoutManager.glyphRange(forCharacterRange: NSRange(location: cursorPosition, length: 0), actualCharacterRange: nil)
        guard glyphRange.location != NSNotFound else {
            // 光标超出范围 → 滚到底部
            scrollToBottom(scrollView, textView: textView)
            return
        }

        let cursorRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        let targetY = cursorRect.origin.y

        let clipView = scrollView.contentView
        // 把光标位置滚动到容器居中（减去容器高度的一半）
        let halfHeight = clipView.bounds.height / 2
        let targetOffset = max(0, min(targetY - halfHeight, textView.bounds.height - clipView.bounds.height))

        let currentOffset = clipView.bounds.origin.y
        if abs(targetOffset - currentOffset) > 0.5 {
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.duration = 0
            clipView.setBoundsOrigin(NSPoint(x: 0, y: targetOffset))
            NSAnimationContext.endGrouping()
        }
    }

    private func scrollToBottom(_ scrollView: NSScrollView, textView: NSTextView) {
        let clipView = scrollView.contentView
        let targetOffset = max(0, textView.bounds.height - clipView.bounds.height)
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0
        clipView.setBoundsOrigin(NSPoint(x: 0, y: targetOffset))
        NSAnimationContext.endGrouping()
    }

    class Coordinator {
        weak var textView: NSTextView?
        weak var scrollView: NSScrollView?
        var lastTextVersion: Int = -1
        var isFirstUpdate: Bool = true
        var lastAppearanceVersion: Int = -1
        var lastCursorPosition: Int = 0
    }
}


