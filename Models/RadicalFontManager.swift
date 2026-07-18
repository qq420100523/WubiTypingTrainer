//
//  RadicalFontManager.swift
//  Fire
//
//  Created by qq420100523 on 2026/7/2.
//

import Foundation
import CoreText
import OSLog

/// 管理黑体字根字体注册，用于候选词窗中显示五笔拆字字根（如 〈氵工〉）
/// 字体来源：https://github.com/mrshiqiqi/rime-wubi
/// 在 init 时自动注册到当前进程，注册后可在 SwiftUI Text 中通过 Font.custom(fontName) 使用
class RadicalFontManager {
    static let shared = RadicalFontManager()
    static let fontName = "黑体字根"

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "WubiTypingTrainer", category: "RadicalFontManager")

    private var fontAvailable = false

    private init() {
        registerFont()
    }

    private func registerFont() {
        // Xcode 将 ttf 复制到 Resources 根目录，而非保留源码中的 font/ 子目录
        let fontURL = Bundle.main.url(forResource: Self.fontName, withExtension: "ttf")
            ?? Bundle.main.url(forResource: Self.fontName, withExtension: "ttf", subdirectory: "font")
        guard let fontURL else {
            logger.error("Font file not found in bundle")
            return
        }

        let registered = CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        if registered {
            fontAvailable = true
            logger.notice("Font registered: \(Self.fontName)")
            return
        }

        let font = CTFontCreateWithName(Self.fontName as CFString, 12, nil)
        fontAvailable = (CTFontCopyFamilyName(font) as String) == Self.fontName
        if fontAvailable {
            logger.info("Font already available: \(Self.fontName)")
        } else {
            logger.error("Font registration failed")
        }
    }

    var isFontAvailable: Bool {
        fontAvailable
    }
}
