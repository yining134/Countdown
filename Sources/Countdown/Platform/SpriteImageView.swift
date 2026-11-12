import AppKit
import SwiftUI

struct SpriteImageView: NSViewRepresentable {
    let asset: SpriteAsset
    let frameSize: SkinManifest.FrameSize
    let animation: SkinManifest.Animation
    let identity: String
    let playing: Bool

    func makeNSView(context: Context) -> SpriteCanvas { SpriteCanvas() }

    func updateNSView(_ view: SpriteCanvas, context: Context) {
        view.configure(asset: asset, size: frameSize, animation: animation, identity: identity, playing: playing)
    }

    static func dismantleNSView(_ view: SpriteCanvas, coordinator: ()) { view.stop() }
}

final class SpriteCanvas: NSView {
    private var asset: SpriteAsset?
    private var frameSize = SkinManifest.FrameSize(width: 1, height: 1)
    private var animation = SkinManifest.Animation(startFrame: 0, frameCount: 1, fps: 1)
    private var identity = ""
    private var cursor = 0
    private var timer: Timer?
    private var playing = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.contentsGravity = .resizeAspect
        layer?.magnificationFilter = .nearest
        layer?.minificationFilter = .nearest
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    func configure(asset: SpriteAsset, size: SkinManifest.FrameSize,
                   animation: SkinManifest.Animation, identity: String, playing: Bool) {
        let changed = self.identity != identity || self.asset?.image !== asset.image
        if changed {
            stop()
            self.asset = asset
            frameSize = size
            self.animation = animation
            self.identity = identity
            cursor = 0
            showFrame()
        }
        if changed || self.playing != playing {
            stop()
            self.playing = playing
            if playing && animation.frameCount > 1 {
                let ticker = Timer(timeInterval: 1 / animation.fps, repeats: true) { [weak self] _ in
                    guard let self else { return }
                    self.cursor = (self.cursor + 1) % self.animation.frameCount
                    self.showFrame()
                }
                timer = ticker
                RunLoop.main.add(ticker, forMode: .common)
            }
        }
    }

    func stop() { timer?.invalidate(); timer = nil; playing = false }

    private func showFrame() {
        guard let image = asset?.image else { return }
        let columns = image.width / frameSize.width
        let index = animation.startFrame + cursor
        let rect = CGRect(x: (index % columns) * frameSize.width,
                          y: (index / columns) * frameSize.height,
                          width: frameSize.width, height: frameSize.height)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer?.contents = image.cropping(to: rect)
        CATransaction.commit()
    }
}
