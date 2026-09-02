import SwiftUI

struct RootView: View {
    @Bindable var store: StudyStore
    @State private var selectedTab: AppTab = .review
    @State private var showScenePicker = false
    @Environment(AmbientSoundEngine.self) private var ambientSound

    var body: some View {
        ZStack {
            AmbientBackgroundView(scene: store.ambientScene, feedTheme: store.feedTheme)
            Group {
                switch selectedTab {
                case .review: StudyView(store: store, selectedTab: $selectedTab)
                case .books: BooksView(store: store)
                case .progress: ProgressView(store: store)
                case .profile: ProfileView(store: store)
                }
            }
            .padding(.bottom, 78)
            .animation(.easeInOut(duration: 0.22), value: selectedTab)
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                AppTabBar(selectedTab: $selectedTab, showScenePicker: $showScenePicker, scene: store.ambientScene)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        // 主界面(复习页)上下滑动切换背景;其他 Tab 有滚动列表,不挂手势
        .simultaneousGesture(swipeToSwitchScene, including: selectedTab == .review ? .all : .none)
        .sheet(isPresented: $showScenePicker) { ScenePicker(store: store) }
    }

    private var swipeToSwitchScene: some Gesture {
        DragGesture(minimumDistance: 40)
            .onEnded { value in
                let dy = value.translation.height
                guard abs(dy) > abs(value.translation.width) else { return }
                cycleScene(forward: dy < 0) // 上滑下一个,下滑上一个
            }
    }

    private func cycleScene(forward: Bool) {
        let scenes = AmbientScene.allCases
        guard let index = scenes.firstIndex(of: store.ambientScene) else { return }
        let next = scenes[(index + (forward ? 1 : scenes.count - 1)) % scenes.count]
        store.chooseScene(next)
        if ambientSound.isPlaying { ambientSound.start(for: next) }
    }
}

enum AppTab: Hashable { case review, books, progress, profile }

private struct AppTabBar: View {
    @Binding var selectedTab: AppTab
    @Binding var showScenePicker: Bool
    let scene: AmbientScene
    @Environment(AmbientSoundEngine.self) private var ambientSound

    var body: some View {
        HStack {
            item(.review, "复习", "brain.head.profile")
            item(.books, "词书", "books.vertical")
            item(.progress, "统计", "chart.line.uptrend.xyaxis")
            item(.profile, "我的", "person")
            Spacer(minLength: 0)
            Button { showScenePicker = true } label: {
                Image(systemName: scene.symbol)
                    .font(.title3).foregroundStyle(.mint)
            }.accessibilityLabel("选择沉浸背景")
            Button { ambientSound.toggle(for: scene) } label: {
                Image(systemName: ambientSound.isPlaying ? "waveform.circle.fill" : "waveform.circle")
                    .font(.title2).foregroundStyle(.mint)
            }.accessibilityLabel("播放或暂停白噪音")
        }
        .padding(.horizontal, 22).padding(.top, 12).padding(.bottom, 5)
        .background(.ultraThinMaterial)
        .background(.black.opacity(0.64))
    }

    private func item(_ tab: AppTab, _ title: String, _ icon: String) -> some View {
        Button { selectedTab = tab } label: {
            VStack(spacing: 4) { Image(systemName: icon); Text(title).font(.caption2) }
                .frame(width: 58).foregroundStyle(selectedTab == tab ? .mint : .white.opacity(0.55))
        }
        .accessibilityLabel(title)
    }
}

struct ScenePicker: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AmbientSoundEngine.self) private var ambientSound
    @Bindable var store: StudyStore

    var body: some View {
        NavigationStack {
            List {
                Section("背景") {
                    ForEach(AmbientScene.allCases) { scene in
                        Button {
                            store.chooseScene(scene)
                            if ambientSound.isPlaying { ambientSound.start(for: scene) }
                            // 选短视频时留在面板里继续挑主题,其他背景直接关闭
                            if scene != .feed { dismiss() }
                        } label: {
                            HStack(spacing: 15) {
                                Image(systemName: scene.symbol).font(.title3).frame(width: 34).foregroundStyle(.mint)
                                VStack(alignment: .leading) {
                                    Text(scene.title).foregroundStyle(.primary)
                                    Text(scene.subtitle).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if store.ambientScene == scene { Image(systemName: "checkmark.circle.fill").foregroundStyle(.mint) }
                            }
                        }
                    }
                }
                if store.ambientScene == .feed {
                    Section("短视频主题") {
                        ForEach(FeedTheme.allCases) { theme in
                            Button {
                                store.chooseFeedTheme(theme)
                                dismiss()
                            } label: {
                                HStack {
                                    Text(theme.title).foregroundStyle(.primary)
                                    Spacer()
                                    if store.feedTheme == theme { Image(systemName: "checkmark.circle.fill").foregroundStyle(.mint) }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("沉浸背景")
        }
    }
}
