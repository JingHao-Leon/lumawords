<div align="center">

# 光屿单词 LumaWords

**一个以沉浸感为中心的 iOS 背单词应用 · An immersion-first vocabulary app for iOS**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-iOS%2017%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5-orange.svg)](https://swift.org)
[![GitHub last commit](https://img.shields.io/github/last-commit/JingHao-Leon/lumawords)](https://github.com/JingHao-Leon/lumawords/commits/main)
[![GitHub repo size](https://img.shields.io/github/repo-size/JingHao-Leon/lumawords)](https://github.com/JingHao-Leon/lumawords)

</div>

---

## ✨ 功能亮点

| 功能 | 说明 |
|---|---|
| 🔊 美式发音朗读 | 基于 `AVSpeechSynthesizer`，以 `en-US` 朗读当前单词 |
| 🌊 程序化动态背景 | 翻涌海面、微嘈教室、低清短视频三种沉浸背景，不缓存、不无限加载视频 |
| 🎧 实时白噪音 | 与背景场景对应的可播放/暂停环境音（海浪、教室人声） |
| 📚 多词书切换 | 内置 8 本词书（中考 / 高考 / 四六级 / 考研 / 雅思 / 托福 / GRE），词库由 ECDICT 按考试标签过滤生成 |
| 🧠 艾宾浩斯复习 | 按 0 / 1 / 2 / 4 / 7 / 15 / 30 天间隔自动安排复习 |
| ✅ 学习反馈 | 「记住了 / 还不熟」即时更新复习阶段、今日完成量与待复习量 |
| 💾 本地持久化 | 昵称登录与学习记录通过 `UserDefaults` 保存在本机，离线可用 |

## 📖 内置词库

| 词书 | 说明 | 词条数 |
|---|---|---:|
| 中考词汇 | 初中核心词 | 1,600 |
| 高考词汇 | 高中核心词 | 3,674 |
| 大学英语四级 | CET-4 大纲词 | 3,846 |
| 大学英语六级 | CET-6 大纲词 | 5,406 |
| 考研词汇 | 考研大纲词 | 4,801 |
| 雅思词汇 | 学术与生活场景 | 5,038 |
| 托福词汇 | 北美学术英语 | 6,970 |
| GRE 核心 | 高阶学术词汇 | 7,504 |

合计 **38,839** 词条。

## 🛠 技术栈

- **Swift 5 + SwiftUI**，最低支持 **iOS 17**
- `AVFoundation`（语音朗读 / 白噪音 / 视频背景播放）
- `UserDefaults` 本地持久化，无后端依赖
- Xcode 工程，无第三方依赖（无 CocoaPods / SPM 包）

## 📁 项目结构

```
.
├── LumaWords.xcodeproj/          # Xcode 工程
├── LumaWords/
│   ├── LumaWordsApp.swift        # App 入口
│   ├── RootView.swift            # 根视图与导航
│   ├── StudyView.swift           # 背单词主界面
│   ├── LibraryViews.swift        # 词书库与切换
│   ├── StudyStore.swift          # 学习状态与艾宾浩斯调度
│   ├── Models.swift              # 数据模型（词书 / 词条）
│   ├── AmbientBackgroundView.swift  # 程序化动态背景
│   ├── AmbientSoundEngine.swift     # 白噪音引擎
│   ├── WordBank/                 # 8 本词库 JSON + manifest.json
│   ├── Media/                    # 背景视频与白噪音音频
│   └── Assets.xcassets/          # App 图标等资源
├── MediaStaging/videos/meme/     # 未收入 bundle 的暂存素材
└── docs/media-sources.md         # 素材来源清单与许可说明
```

## 🚀 运行方法

1. 用 Xcode（15+）打开 `LumaWords.xcodeproj`
2. 选择 iOS 17 或更新版本的模拟器 / 真机
3. ⌘R 运行

## 🎬 素材来源

所有音视频素材均来自 **Mixkit / Pixabay / Pexels** 的免费商用许可（无需署名），完整清单、直链与收录状态见 [docs/media-sources.md](docs/media-sources.md)。

## 🗺 Roadmap

- [ ] Sign in with Apple + CloudKit 多设备同步（当前为本地优先原型）
- [ ] 接入取得授权的完整词库（当前词书为 ECDICT 演示词库）
- [ ] 学习统计与数据可视化

---

## English

**LumaWords (光屿单词)** is an immersion-first vocabulary app for iOS 17+, built with Swift 5 and SwiftUI. It pairs each word with procedurally generated ambient backgrounds — rolling ocean waves, a murmuring classroom, or looping lo-fi short videos — together with matching white noise, so review sessions feel like a place rather than a flashcard deck.

Highlights:

- **en-US text-to-speech** for every word via `AVSpeechSynthesizer`
- **Eight built-in word books** (38,839 entries total): middle/high school, CET-4/6, postgraduate entrance, IELTS, TOEFL and GRE, filtered from ECDICT by exam tag
- **Ebbinghaus spaced repetition** with 0 / 1 / 2 / 4 / 7 / 15 / 30-day intervals
- **Local-first**: nickname sign-in and all study records persist in `UserDefaults` — no backend, works offline
- All media assets are free for commercial use (Mixkit / Pixabay / Pexels licenses); see [docs/media-sources.md](docs/media-sources.md)

This is a demonstrable local-first prototype. Multi-device sync (Sign in with Apple + CloudKit) and fully licensed word books are on the roadmap.

## 📄 License

[MIT](LICENSE) © JingHao-Leon
