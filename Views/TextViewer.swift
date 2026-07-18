import SwiftUI
import AppKit

struct TextViewer: NSViewRepresentable {
    let attributedText: NSAttributedString
    var cursorPosition: Int
    var textVersion: Int
    var appearanceVersion: Int
    var fontSize: CGFloat = 18
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

        if context.coordinator.isFirstUpdate || changedIndex < 0
            || appearanceVersion != context.coordinator.lastAppearanceVersion {
            ts.setAttributedString(attributedText)
            textView.layoutManager?.ensureLayout(for: textView.textContainer!)
            context.coordinator.isFirstUpdate = false
            context.coordinator.lastAppearanceVersion = appearanceVersion
        } else {
            if changedIndex >= 0 && changedIndex < fullLength {
                let newAttrs = attributedText.attributes(at: changedIndex, effectiveRange: nil)
                ts.setAttributes(newAttrs, range: NSRange(location: changedIndex, length: 1))
            }
        }

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

        if cursorPosition >= 0 && cursorPosition < fullLength {
            let cursorRange = NSRange(location: cursorPosition, length: 1)
            ts.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: cursorRange)
            let resolvedAccent = NSColor.resolve { NSColor.controlAccentColor }
            ts.addAttribute(.underlineColor, value: resolvedAccent, range: cursorRange)
        }

        context.coordinator.lastCursorPosition = cursorPosition

        guard textVersion != context.coordinator.lastTextVersion else { return }
        context.coordinator.lastTextVersion = textVersion

        guard let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }

        let glyphRange = layoutManager.glyphRange(forCharacterRange: NSRange(location: cursorPosition, length: 0), actualCharacterRange: nil)
        guard glyphRange.location != NSNotFound else {
            scrollToBottom(scrollView, textView: textView)
            return
        }

        let cursorRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        let targetY = cursorRect.origin.y

        let clipView = scrollView.contentView
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
