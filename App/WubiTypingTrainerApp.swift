import SwiftUI

@main
struct WubiTypingTrainerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // 注册黑体字根字体，用于显示拆字
        _ = RadicalFontManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(after: .pasteboard) {
                Divider()
                Button("载入文章 (⌘⇧V)") {
                    postNotification(.loadFromClipboard)
                }
                .keyboardShortcut("v", modifiers: [.command, .shift])
            }
            
            CommandGroup(after: .textEditing) {
                Divider()
                Button("重打") {
                    postNotification(.restart)
                }
                .keyboardShortcut("r", modifiers: .command)
                
                Button("暂停/继续") {
                    postNotification(.togglePause)
                }
                .keyboardShortcut(.escape, modifiers: [])

                Divider()

                Button("设置") {
                    postNotification(.openSettings)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
    
    private func postNotification(_ name: Notification.Name) {
        NotificationCenter.default.post(name: name, object: nil)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 将窗口激活到前台
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}

extension Notification.Name {
    static let loadFromClipboard = Notification.Name("loadFromClipboard")
    static let restart = Notification.Name("restart")
    static let togglePause = Notification.Name("togglePause")
    static let openSettings = Notification.Name("openSettings")
}
