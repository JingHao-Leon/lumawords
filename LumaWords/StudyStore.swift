import AVFoundation
import Foundation
import Observation

@MainActor @Observable
final class StudyStore {
    private enum GlobalKey {
        static let currentUser = "luma.currentUser"
        static let ambient = "luma.ambient"
        static let feedTheme = "luma.feedTheme"
    }

    var selectedBookID: String
    var ambientScene: AmbientScene
    var feedTheme: FeedTheme
    var nickname: String
    var records: [ReviewRecord]
    var dailyCount: Int
    var dailyDate: Date
    var streak: Int
    var lastStudyDate: Date?

    /// 未登录时用 guest 命名空间;登录后每个昵称一套独立数据。
    private var namespace: String { nickname.isEmpty ? "guest" : nickname }
    private func userKey(_ name: String) -> String { "luma.\(namespace).\(name)" }

    init() {
        let defaults = UserDefaults.standard
        nickname = defaults.string(forKey: GlobalKey.currentUser) ?? ""
        ambientScene = AmbientScene(rawValue: defaults.string(forKey: GlobalKey.ambient) ?? "ocean") ?? .ocean
        feedTheme = FeedTheme(rawValue: defaults.string(forKey: GlobalKey.feedTheme) ?? "all") ?? .all
        selectedBookID = "cet4"
        records = []
        dailyCount = 0
        dailyDate = .now
        streak = 0
        lastStudyDate = nil
        loadUserData()
    }

    // MARK: - 词书与复习队列

    var activeWords: [Word] { WordBank.words(for: selectedBookID) }
    var currentBook: WordBook { WordBank.books.first { $0.id == selectedBookID } ?? WordBank.books[0] }
    var isSignedIn: Bool { !nickname.isEmpty }

    private var bookRecords: [ReviewRecord] { records.filter { $0.bookID == selectedBookID } }

    /// 到期复习优先,其次按词库顺序取新词;都完成返回 nil。
    var currentWord: Word? {
        let words = activeWords
        guard !words.isEmpty else { return nil }
        let wordByID = Dictionary(words.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let due = bookRecords
            .filter { !$0.mastered && $0.dueDate <= .now }
            .sorted { $0.dueDate < $1.dueDate }
        for record in due {
            if let word = wordByID[record.wordID] { return word }
        }
        let recorded = Set(bookRecords.map(\.wordID))
        return words.first { !recorded.contains($0.id) }
    }

    var reviewDueCount: Int { bookRecords.filter { !$0.mastered && $0.dueDate <= .now }.count }
    var masteredCount: Int { bookRecords.filter(\.mastered).count }
    var learnedCount: Int { bookRecords.count }
    var newWordsRemaining: Int { max(0, currentBook.total - learnedCount) }

    func learnedCount(for bookID: String) -> Int { records.filter { $0.bookID == bookID }.count }

    func chooseBook(_ book: WordBook) {
        selectedBookID = book.id
        save()
    }

    func chooseScene(_ scene: AmbientScene) {
        ambientScene = scene
        save()
    }

    func chooseFeedTheme(_ theme: FeedTheme) {
        feedTheme = theme
        save()
    }

    // MARK: - 艾宾浩斯记忆

    func markCurrent(_ remembered: Bool) {
        guard let word = currentWord else { return }
        let existing = records.firstIndex { $0.wordID == word.id }
        let oldStage = existing.map { records[$0].stage } ?? -1
        let newStage = remembered ? min(oldStage + 1, ReviewSchedule.intervals.count - 1) : 0
        let dueDate = remembered
            ? ReviewSchedule.nextDate(for: newStage)
            : Date().addingTimeInterval(10 * 60) // 答错 10 分钟后再次出现
        let record = ReviewRecord(wordID: word.id,
                                  bookID: word.book,
                                  stage: newStage,
                                  dueDate: dueDate,
                                  mastered: remembered && newStage >= ReviewSchedule.intervals.count - 1)
        if let existing { records[existing] = record } else { records.append(record) }
        dailyCount += 1
        updateStreak()
        save()
    }

    private func updateStreak() {
        let calendar = Calendar.current
        if let last = lastStudyDate {
            if calendar.isDateInToday(last) { return }
            streak = calendar.isDateInYesterday(last) ? streak + 1 : 1
        } else {
            streak = 1
        }
        lastStudyDate = .now
    }

    // MARK: - 账户

    func signIn(as name: String) {
        nickname = name.trimmingCharacters(in: .whitespacesAndNewlines)
        loadUserData()
        save()
    }

    func signOut() {
        nickname = ""
        loadUserData()
        save()
    }

    // MARK: - 持久化

    private func loadUserData() {
        let defaults = UserDefaults.standard
        selectedBookID = defaults.string(forKey: userKey("selectedBook")) ?? "cet4"
        dailyCount = defaults.integer(forKey: userKey("dailyCount"))
        dailyDate = defaults.object(forKey: userKey("dailyDate")) as? Date ?? .now
        streak = defaults.integer(forKey: userKey("streak"))
        lastStudyDate = defaults.object(forKey: userKey("lastStudyDate")) as? Date
        if let data = defaults.data(forKey: userKey("records")),
           let decoded = try? JSONDecoder().decode([ReviewRecord].self, from: data) {
            records = decoded
        } else {
            records = []
        }
        resetDailyCountIfNeeded()
    }

    private func resetDailyCountIfNeeded() {
        guard !Calendar.current.isDateInToday(dailyDate) else { return }
        dailyCount = 0
        dailyDate = .now
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(nickname, forKey: GlobalKey.currentUser)
        defaults.set(ambientScene.rawValue, forKey: GlobalKey.ambient)
        defaults.set(feedTheme.rawValue, forKey: GlobalKey.feedTheme)
        defaults.set(selectedBookID, forKey: userKey("selectedBook"))
        defaults.set(dailyCount, forKey: userKey("dailyCount"))
        defaults.set(dailyDate, forKey: userKey("dailyDate"))
        defaults.set(streak, forKey: userKey("streak"))
        defaults.set(lastStudyDate, forKey: userKey("lastStudyDate"))
        defaults.set(try? JSONEncoder().encode(records), forKey: userKey("records"))
    }
}

enum ReviewSchedule {
    static let intervals = [0, 1, 2, 4, 7, 15, 30]
    static func nextDate(for stage: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: intervals[stage], to: .now) ?? .now
    }
}

@MainActor
final class PronunciationService {
    static let shared = PronunciationService()
    private let synthesizer = AVSpeechSynthesizer()
    func speak(_ word: String) {
        let utterance = AVSpeechUtterance(string: word)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.44
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
    }
}
