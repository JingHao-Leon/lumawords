import SwiftUI

struct StudyView: View {
    @Bindable var store: StudyStore
    @Binding var selectedTab: AppTab
    @State private var showAnswer = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer(minLength: 28)
            if let word = store.currentWord {
                wordCard(word)
                Spacer(minLength: 16)
                HStack(spacing: 12) {
                    actionButton("还不熟", icon: "arrow.counterclockwise", color: .orange) { advance(false) }
                    actionButton("记住了", icon: "checkmark", color: .mint) { advance(true) }
                }
                .padding(.horizontal, 20)
            } else {
                finishedCard
            }
            Spacer(minLength: 10)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("沉浸复习").font(.title2.weight(.bold))
                Text("\(store.currentBook.title) · 今日 \(store.dailyCount) 词").font(.subheadline).foregroundStyle(.white.opacity(0.62))
            }
            Spacer()
        }
        .padding(.horizontal, 22).padding(.top, 14)
    }

    private func wordCard(_ word: Word) -> some View {
        Button { withAnimation(.spring) { showAnswer.toggle() } } label: {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Text("待复习 \(store.reviewDueCount) · 新词剩余 \(store.newWordsRemaining)")
                        .font(.caption.weight(.bold)).foregroundStyle(.mint)
                    Spacer()
                    Text("美音").font(.caption.weight(.bold)).padding(.horizontal, 10).padding(.vertical, 5).background(.white.opacity(0.12), in: Capsule())
                }
                Text(word.spelling).font(.system(size: 43, weight: .semibold, design: .rounded)).minimumScaleFactor(0.7)
                HStack {
                    Text(word.displayPhonetic).font(.title3).foregroundStyle(.white.opacity(0.70))
                    Spacer()
                    Button { PronunciationService.shared.speak(word.spelling) } label: { Image(systemName: "speaker.wave.2.fill").font(.title2).foregroundStyle(.mint) }.accessibilityLabel("播放美式发音")
                }
                Divider().overlay(.white.opacity(0.16))
                if showAnswer {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(word.definition).font(.title3.weight(.medium))
                        if let example = word.example, !example.isEmpty {
                            Text(example).font(.body).foregroundStyle(.white.opacity(0.86))
                            if let translation = word.exampleTranslation, !translation.isEmpty {
                                Text(translation).font(.subheadline).foregroundStyle(.white.opacity(0.56))
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    VStack(alignment: .leading, spacing: 6) { Text("先在脑海里回忆释义").font(.headline); Text("点击卡片显示答案").font(.subheadline).foregroundStyle(.white.opacity(0.55)) }.frame(maxWidth: .infinity, minHeight: 98, alignment: .leading)
                }
            }
            .padding(24).frame(maxWidth: .infinity, alignment: .leading)
            .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 30).stroke(.white.opacity(0.15)))
        }
        .buttonStyle(.plain).padding(.horizontal, 20)
    }

    private var finishedCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 44)).foregroundStyle(.mint)
            Text("今日任务完成").font(.title3.weight(.bold))
            Text("当前词书没有到期的复习,也没有新词了。可以换一本词书继续。")
                .font(.subheadline).foregroundStyle(.white.opacity(0.6)).multilineTextAlignment(.center)
            Button("去换词书") { selectedTab = .books }
                .buttonStyle(.borderedProminent).tint(.mint).foregroundStyle(.black)
        }
        .padding(28).frame(maxWidth: .infinity)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 20)
    }

    private func actionButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) { Label(title, systemImage: icon).font(.headline).frame(maxWidth: .infinity).padding(.vertical, 17).background(color.opacity(0.88), in: Capsule()).foregroundStyle(.black) }
    }

    private func advance(_ remembered: Bool) { guard showAnswer else { withAnimation { showAnswer = true }; return }; store.markCurrent(remembered); withAnimation { showAnswer = false } }
}
