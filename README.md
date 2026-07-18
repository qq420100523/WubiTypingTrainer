# WubiTypingTrainer

五笔打字练习器 — macOS 原生应用，帮助你练习五笔86版输入法。

## 功能

- 随机构字、分区键位练习、高频字、词组、文章练习
- 错字本自动记录错误，针对性复习
- 五笔拆字提示（字根分解 + 编码）
- 知乎日报文章抓取，练习真实文本
- 练习统计（速度、准确率、击键次数等）

## 系统要求

- macOS 14.0+
- Apple Silicon 或 Intel

## 构建

```bash
xcodebuild build \
  -project WubiTypingTrainer.xcodeproj \
  -scheme WubiTypingTrainer \
  -configuration Debug \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO
```

或在 Xcode 中打开 `WubiTypingTrainer.xcodeproj`，选择 Product → Build。

## 测试

测试文件在 `Tests/` 目录下。在 Xcode 中激活测试：

1. 打开项目 → Product → Test（⌘U）
2. 首次运行时 Xcode 会提示创建测试 Scheme，接受即可
3. 或在 `WubiTypingTrainer.xcscheme` 的 Test Action 中手动添加测试 target

命令行运行：
```bash
xcodebuild test \
  -project WubiTypingTrainer.xcodeproj \
  -scheme WubiTypingTrainer \
  -configuration Debug \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO
```

## 许可

MIT License
