import AppKit

final class SpriteCanvasView: NSView {
    private var asset: SpriteAsset?
    private var frameSize = SkinManifest.FrameSize(width: 1, height: 1)
    private var animation = SkinManifest.Animation(startFrame: 0, frameCount: 1, framesPerSecond: 1)
    private var identity = ""
    private var cursor = 0
    private var timer: Timer?
    private var isPlaying = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.contentsGravity = .resizeAspect
        layer?.magnificationFilter = .nearest
        layer?.minificationFilter = .nearest
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    func configure(
        asset: SpriteAsset, size: SkinManifest.FrameSize,
        animation: SkinManifest.Animation, identity: String, isPlaying: Bool
    ) {
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
        if changed || self.isPlaying != isPlaying {
            stop()
            self.isPlaying = isPlaying
            if isPlaying && animation.frameCount > 1 {
                let ticker = Timer(timeInterval: 1 / animation.framesPerSecond, repeats: true) { [weak self] _ in
                    Task { @MainActor [weak self] in
                        self?.advanceFrame()
                    }
                }
                timer = ticker
                RunLoop.main.add(ticker, forMode: .common)
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isPlaying = false
    }

    private func advanceFrame() {
        guard isPlaying else { return }
        cursor = (cursor + 1) % animation.frameCount
        showFrame()
    }

    private func showFrame() {
        guard let image = asset?.image else { return }
        let columns = image.width / frameSize.width
        let index = animation.startFrame + cursor
        let rect = CGRect(
            x: (index % columns) * frameSize.width,
            y: (index / columns) * frameSize.height,
            width: frameSize.width, height: frameSize.height)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer?.contents = image.cropping(to: rect)
        CATransaction.commit()
    }
}
