import AppKit
import SwiftUI

struct SpriteImageView: NSViewRepresentable {
    let asset: SpriteAsset
    let frameSize: SkinManifest.FrameSize
    let animation: SkinManifest.Animation
    let identity: String
    let isPlaying: Bool

    func makeNSView(context: Context) -> SpriteCanvasView { SpriteCanvasView() }

    func updateNSView(_ view: SpriteCanvasView, context: Context) {
        view.configure(asset: asset, size: frameSize, animation: animation, identity: identity, isPlaying: isPlaying)
    }

    static func dismantleNSView(_ view: SpriteCanvasView, coordinator: ()) { view.stop() }
}
