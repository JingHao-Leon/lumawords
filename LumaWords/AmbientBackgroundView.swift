import AVFoundation
import SwiftUI

struct AmbientBackgroundView: View {
    let scene: AmbientScene
    var feedTheme: FeedTheme = .all

    var body: some View {
        Group {
            switch scene {
            case .ocean:
                VideoBackground(prefix: "bg-ocean", dim: 0.28)
            case .classroom:
                VideoBackground(prefix: "bg-classroom", dim: 0.30)
            case .feed:
                ZStack {
                    VideoBackground(prefix: feedTheme.videoPrefix, blur: 4, dim: 0.32, ownAudio: true)
                        .id(feedTheme) // 切主题时重建播放器,换一批视频
                    ShortVideoChrome()
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

// MARK: - 视频背景

/// 全屏实拍视频背景:轮播 Bundle 内指定前缀的 mp4(如 bg-ocean / feed-meme-),压暗。
/// ownAudio 为 true 时,视频音轨跟随白噪音开关解除静音(短视频背景用)。
/// 找不到素材时退化为深色渐变。
private struct VideoBackground: View {
    let prefix: String
    var blur: CGFloat = 0
    var dim: Double = 0.25
    var ownAudio: Bool = false
    @State private var controller = QueueVideoController()
    @Environment(AmbientSoundEngine.self) private var ambientSound

    var body: some View {
        Group {
            if controller.hasItems {
                PlayerLayerView(player: controller.player)
                    .blur(radius: blur)
                    .saturation(0.85)
                    .scaleEffect(blur > 0 ? 1.15 : 1.0)
                    .overlay(Color.black.opacity(dim))
            } else {
                LinearGradient(colors: [Color(red: 0.02, green: 0.08, blue: 0.12), .black],
                               startPoint: .top, endPoint: .bottom)
            }
        }
        .onAppear {
            controller.load(prefix: prefix)
            syncMute()
        }
        .onChange(of: ambientSound.isPlaying) { syncMute() }
    }

    private func syncMute() {
        controller.player.isMuted = ownAudio ? !ambientSound.isPlaying : true
    }
}

/// SwiftUI 的 VideoPlayer 不支持 aspect-fill,用 AVPlayerLayer 填全屏。
private struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerView { PlayerView(player: player) }
    func updateUIView(_ uiView: PlayerView, context: Context) {}
}

private final class PlayerView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    init(player: AVPlayer) {
        super.init(frame: .zero)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}

/// 队列播放器:循环轮播 URL 列表。不能重复插入同一个 AVPlayerItem,
/// 所以每轮都用 URL 新建 item,播完一个就按顺序补一个新的进队尾。
@Observable @MainActor
private final class QueueVideoController {
    let player = AVQueuePlayer()
    private(set) var hasItems = false
    private var loaded = false
    private var urls: [URL] = []
    private var nextIndex = 0
    private nonisolated(unsafe) var observer: NSObjectProtocol?

    func load(prefix: String) {
        guard !loaded else { return }
        loaded = true
        let matches = (Bundle.main.urls(forResourcesWithExtension: "mp4", subdirectory: nil) ?? [])
            .filter { $0.lastPathComponent.hasPrefix(prefix) }
            .shuffled()
        guard !matches.isEmpty else { return }
        urls = matches
        player.isMuted = true
        player.actionAtItemEnd = .advance
        enqueueNext()
        if urls.count > 1 { enqueueNext() } // 队列里始终备着下一条
        observer = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.enqueueNext() }
        }
        hasItems = true
        player.play()
    }

    private func enqueueNext() {
        let url = urls[nextIndex % urls.count]
        nextIndex += 1
        player.insert(AVPlayerItem(url: url), after: nil)
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }
}

// MARK: - 仿短视频界面元素

/// 右侧操作栏 + 左下文案 + 底部播放进度条,让背景看起来像真的在刷短视频。
private struct ShortVideoChrome: View {
    var body: some View {
        VStack {
            Spacer()
            TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
                let progress = (timeline.date.timeIntervalSinceReferenceDate / 12)
                    .truncatingRemainder(dividingBy: 1)
                Capsule()
                    .fill(.white.opacity(0.85))
                    .frame(width: 120 * progress, height: 3)
                    .frame(width: 120, alignment: .leading)
                    .background(Capsule().fill(.white.opacity(0.25)).frame(height: 3))
            }
            .padding(.bottom, 92)
        }
    }
}
