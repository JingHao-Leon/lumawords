import Foundation

enum AmbientScene: String, CaseIterable, Identifiable, Codable, Sendable {
    case ocean, classroom, feed

    var id: String { rawValue }
    var title: String {
        switch self {
        case .ocean: "翻涌海面"
        case .classroom: "教室白噪音"
        case .feed: "模糊短视频"
        }
    }
    var subtitle: String {
        switch self {
        case .ocean: "海浪与潮汐声"
        case .classroom: "轻微人声与翻页声"
        case .feed: "低清滚动的环境感"
        }
    }
    var symbol: String {
        switch self {
        case .ocean: "water.waves"
        case .classroom: "building.2"
        case .feed: "play.rectangle.fill"
        }
    }
}

/// 短视频背景的主题合集,对应 Bundle 内 feed-<主题>-N.mp4 文件前缀。
enum FeedTheme: String, CaseIterable, Identifiable, Codable, Sendable {
    case all, meme, romance, emotion

    var id: String { rawValue }
    var title: String {
        switch self {
        case .all: "全部"
        case .meme: "meme 梗"
        case .romance: "纯爱"
        case .emotion: "情感氛围"
        }
    }
    var videoPrefix: String {
        self == .all ? "feed-" : "feed-\(rawValue)-"
    }
}

struct Word: Identifiable, Codable, Hashable {
    let id: UUID
    let spelling: String
    let phonetic: String
    let definition: String
    var example: String?
    var exampleTranslation: String?
    let book: String

    var displayPhonetic: String { phonetic.isEmpty ? "" : "/\(phonetic)/" }
}

struct WordBook: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let icon: String

    var total: Int { WordBank.totalCount(for: id) }
}

struct ReviewRecord: Codable, Hashable {
    var wordID: UUID
    var bookID: String
    var stage: Int
    var dueDate: Date
    var mastered: Bool
}

/// 离线词库:按词书从 Bundle 懒加载 JSON,只缓存当前词书。
/// 词库文件由 ECDICT 按考试标签过滤生成(zk/gk/cet4/cet6/ky/ielts/toefl/gre)。
enum WordBank {
    static let books = [
        WordBook(id: "zk", title: "中考词汇", detail: "初中核心词", icon: "book.fill"),
        WordBook(id: "gk", title: "高考词汇", detail: "高中核心词", icon: "book.closed.fill"),
        WordBook(id: "cet4", title: "大学英语四级", detail: "CET-4 大纲词", icon: "graduationcap.fill"),
        WordBook(id: "cet6", title: "大学英语六级", detail: "CET-6 大纲词", icon: "books.vertical.fill"),
        WordBook(id: "ky", title: "考研词汇", detail: "考研大纲词", icon: "pencil.and.outline"),
        WordBook(id: "ielts", title: "雅思词汇", detail: "学术与生活场景", icon: "airplane"),
        WordBook(id: "toefl", title: "托福词汇", detail: "北美学术英语", icon: "globe.americas.fill"),
        WordBook(id: "gre", title: "GRE 核心", detail: "高阶学术词汇", icon: "sparkles")
    ]

    private struct Row: Codable {
        let spelling: String
        let phonetic: String
        let definition: String
    }

    private static let manifest: [String: Int] = {
        guard let url = Bundle.main.url(forResource: "manifest", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: Int].self, from: data)
        else { return [:] }
        return decoded
    }()

    /// 只保留一本词书的缓存,避免一次载入全部词库。
    private static var cache: (bookID: String, words: [Word])?

    static func totalCount(for bookID: String) -> Int { manifest[bookID] ?? 0 }

    static func words(for bookID: String) -> [Word] {
        if let cache, cache.bookID == bookID { return cache.words }
        guard let bookIndex = books.firstIndex(where: { $0.id == bookID }),
              let url = Bundle.main.url(forResource: bookID, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rows = try? JSONDecoder().decode([Row].self, from: data)
        else { return [] }
        let base = bookIndex * 1_000_000
        let words = rows.enumerated().map { index, row in
            Word(id: deterministicID(base + index),
                 spelling: row.spelling,
                 phonetic: row.phonetic,
                 definition: row.definition,
                 example: nil,
                 exampleTranslation: nil,
                 book: bookID)
        }
        cache = (bookID, words)
        return words
    }

    /// 确定性 UUID:同一本词书同一位置永远得到同一个 id,复习记录跨启动可对上。
    private static func deterministicID(_ n: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", n))!
    }
}
