import SwiftUI

struct BooksView: View {
    @Bindable var store: StudyStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("选择词书").font(.largeTitle.weight(.bold))
                Text("换一本适合现在目标的词书，学习进度会单独保存。")
                    .foregroundStyle(.white.opacity(0.62))
                ForEach(WordBank.books) { book in
                    BookRow(book: book, store: store)
                }
            }.padding(22).padding(.bottom, 84)
        }
    }
}

private struct BookRow: View {
    let book: WordBook
    let store: StudyStore

    private var learned: Int { store.learnedCount(for: book.id) }
    private var detailLine: String { book.detail + " · \(book.total.formatted()) 词" }

    var body: some View {
        Button { withAnimation { store.chooseBook(book) } } label: {
            HStack(spacing: 16) {
                Image(systemName: book.icon).font(.title2).frame(width: 48, height: 48).background(.mint.opacity(0.18), in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 6) {
                    Text(book.title).font(.headline)
                    Text(detailLine).font(.subheadline).foregroundStyle(.white.opacity(0.60))
                    if book.total > 0 {
                        HStack(spacing: 8) {
                            SwiftUI.ProgressView(value: Double(learned), total: Double(book.total))
                                .tint(.mint).frame(maxWidth: 120)
                            Text("已学 \(learned)").font(.caption2).foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }
                Spacer()
                Image(systemName: store.selectedBookID == book.id ? "checkmark.circle.fill" : "circle").font(.title3).foregroundStyle(.mint)
            }
            .padding(16).background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 22))
        }.buttonStyle(.plain)
    }
}

struct ProgressView: View {
    @Bindable var store: StudyStore
    private var upcoming: [String] { ["今天", "1 天后", "2 天后", "4 天后", "7 天后", "15 天后", "30 天后"] }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("学习轨迹").font(.largeTitle.weight(.bold))
                HStack(spacing: 12) {
                    stat("今日完成", "\(store.dailyCount)", "checkmark.circle.fill")
                    stat("待复习", "\(store.reviewDueCount)", "clock.arrow.circlepath")
                    stat("已掌握", "\(store.masteredCount)", "star.fill")
                }
                VStack(alignment: .leading, spacing: 14) {
                    Text("艾宾浩斯复习节奏").font(.headline)
                    Text("答对后会在以下间隔再次出现；答错则 10 分钟后重新出现。")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.62))
                    HStack(spacing: 0) { ForEach(Array(upcoming.enumerated()), id: \.offset) { index, title in VStack(spacing: 8) { Circle().fill(index == 0 ? .mint : .white.opacity(0.38)).frame(width: 10, height: 10); Text(title).font(.caption2).fixedSize() }.frame(maxWidth: .infinity) } }
                    .overlay(alignment: .top) { Rectangle().fill(.white.opacity(0.25)).frame(height: 1).padding(.horizontal, 18).padding(.top, 5) }
                    .padding(.vertical, 8)
                }.padding(18).background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 24))
                HStack { Image(systemName: "flame.fill").foregroundStyle(.orange); Text("已连续学习 \(store.streak) 天").font(.headline); Spacer() }.padding(18).background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 24))
            }.padding(22).padding(.bottom, 84)
        }
    }
    private func stat(_ title: String, _ value: String, _ icon: String) -> some View { VStack(alignment: .leading, spacing: 12) { Image(systemName: icon).foregroundStyle(.mint); Text(value).font(.title.bold()); Text(title).font(.caption).foregroundStyle(.white.opacity(0.6)) }.frame(maxWidth: .infinity, alignment: .leading).padding(14).background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 20)) }
}

struct ProfileView: View {
    @Bindable var store: StudyStore
    @State private var nickname = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("我的").font(.largeTitle.weight(.bold))
            if store.isSignedIn {
                HStack(spacing: 16) { Image(systemName: "person.fill").font(.title).frame(width: 58, height: 58).background(.mint.opacity(0.2), in: Circle()); VStack(alignment: .leading) { Text(store.nickname).font(.title3.bold()); Text("已学 \(store.records.count) 词 · 连续 \(store.streak) 天").font(.subheadline).foregroundStyle(.white.opacity(0.58)) } }
                    .padding(18).background(.black.opacity(0.56), in: RoundedRectangle(cornerRadius: 24))
                Text("你的复习进度按账号保存在本机，退出后再次登录会恢复。后续接入 Sign in with Apple 后可同步到多台设备。")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.58)).padding(.horizontal, 4)
                Button("退出登录", role: .destructive) { store.signOut() }
                    .buttonStyle(.bordered)
            } else {
                Text("登录后保存你的复习进度").font(.title3.weight(.semibold))
                TextField("输入昵称开始", text: $nickname).textFieldStyle(.roundedBorder).textInputAutocapitalization(.never)
                Button("开始使用") { store.signIn(as: nickname.isEmpty ? "单词旅人" : nickname) }.buttonStyle(.borderedProminent).tint(.mint).foregroundStyle(.black)
            }
            Spacer()
        }.padding(22).padding(.bottom, 84)
    }
}
