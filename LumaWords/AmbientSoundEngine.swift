import AVFoundation
import Observation
import SwiftUI

@Observable @MainActor
final class AmbientSoundEngine {
    private(set) var isPlaying = false
    private var player: AVAudioPlayer?

    func toggle(for scene: AmbientScene) {
        isPlaying ? stop() : start(for: scene)
    }

    func start(for scene: AmbientScene) {
        stop()
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { return }
        switch scene {
        case .ocean, .classroom:
            startRealAudio(scene)
        case .feed:
            // 短视频背景的声音来自视频本身的音轨,由 VideoBackground 解除静音。
            isPlaying = true
        }
    }

    /// 海面/教室:循环播放真实环境音素材(Bundle 内 ocean.mp3 / classroom.mp3)。
    private func startRealAudio(_ scene: AmbientScene) {
        guard let url = Bundle.main.url(forResource: scene.rawValue, withExtension: "mp3"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.numberOfLoops = -1
        player.volume = scene == .classroom ? 0.7 : 0.55
        player.play()
        self.player = player
        isPlaying = true
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
