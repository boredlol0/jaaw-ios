import AVFoundation
import SwiftUI
import UIKit

// MARK: - Entry-screen video

/// Which bundled clip backs the entry screens. Swap these while trialling
/// footage (`bg1` / `bg2`); the clips live in `Resources/`.
enum JaawEntryVideo {
    static let landing = "bg1"
    static let login = "bg1"
}

/// Full-bleed moving backdrop for the landing and login screens: the clip
/// scaled to fill, under a scrim that keeps the foreground copy legible.
struct JaawVideoBackdrop: View {
    var resource: String
    var reduceMotion: Bool
    /// False pauses the clip — the tab pages use this to keep only the
    /// visible tab's backdrop running.
    var isActive: Bool = true

    var body: some View {
        LoopingVideoBackground(
            resource: resource,
            reduceMotion: reduceMotion,
            isActive: isActive
        )
            .overlay {
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.10), location: 0),
                        .init(color: .black.opacity(0.26), location: 0.55),
                        .init(color: .black.opacity(0.52), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()
    }
}

/// Plays a bundled clip on a seamless loop. No controls, no audio, no bouncing.
struct LoopingVideoBackground: UIViewRepresentable {
    /// Resource name without the extension, e.g. `bg1`.
    var resource: String
    var fileExtension: String = "mp4"
    /// With Reduce Motion on, the first frame is held instead of playing.
    var reduceMotion: Bool = false
    /// False holds the first frame — the clip isn't the visible tab's.
    var isActive: Bool = true

    func makeUIView(context: Context) -> LoopingPlayerView {
        let view = LoopingPlayerView()
        view.load(resource: resource, fileExtension: fileExtension, autoplay: !reduceMotion, isActive: isActive)
        return view
    }

    func updateUIView(_ view: LoopingPlayerView, context: Context) {
        view.load(resource: resource, fileExtension: fileExtension, autoplay: !reduceMotion, isActive: isActive)
    }

    static func dismantleUIView(_ view: LoopingPlayerView, coordinator: ()) {
        view.stop()
    }
}

/// A view whose backing layer *is* the player layer, so the clip fills the
/// bounds without any layout hops.
final class LoopingPlayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var loadedResource: String?
    private var shouldPlay = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.videoGravity = .resizeAspectFill
        backgroundColor = .black
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    func load(resource: String, fileExtension: String, autoplay: Bool, isActive: Bool = true) {
        shouldPlay = autoplay && isActive

        // Re-loading the same clip (updateUIView fires often) must not restart it.
        guard loadedResource != resource else {
            syncPlayback()
            return
        }
        guard let url = Bundle.main.url(forResource: resource, withExtension: fileExtension) else {
            assertionFailure("Missing bundled video: \(resource).\(fileExtension)")
            return
        }

        looper?.disableLooping()
        player?.pause()

        let queue = AVQueuePlayer()
        queue.isMuted = true
        queue.preventsDisplaySleepDuringVideoPlayback = false
        looper = AVPlayerLooper(player: queue, templateItem: AVPlayerItem(url: url))
        playerLayer.player = queue

        player = queue
        loadedResource = resource
        syncPlayback()
    }

    func stop() {
        shouldPlay = false
        player?.pause()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // Leaving the hierarchy (or being dismantled) stops the clip.
        syncPlayback()
    }

    private func syncPlayback() {
        guard let player else { return }
        guard window != nil, shouldPlay else {
            player.pause()
            return
        }
        if player.rate == 0 { player.play() }
    }
}
