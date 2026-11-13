import SwiftUI

struct SkinCyclePreview: View {
    let skin: Skin
    @State private var asset: SpriteAsset?
    @State private var animationName: String?
    @State private var hasFailed = false

    var body: some View {
        Group {
            if let asset, let animationName, let animation = skin.manifest.animations[animationName] {
                SpriteImageView(
                    asset: asset, frameSize: skin.manifest.frameSize, animation: animation,
                    identity: skin.id + ":" + animationName, isPlaying: true)
            } else if hasFailed {
                Image(systemName: "photo.badge.exclamationmark")
            } else {
                ProgressView().controlSize(.small)
            }
        }
        .task(id: skin.id) {
            asset = nil
            animationName = nil
            hasFailed = false
            do {
                let url = try SkinValidator.resource(skin.manifest.spriteSheetPath, in: skin.directory)
                let loaded = try await AnimationLoader.load(url)
                try Task.checkCancellation()
                asset = loaded
                let sequence = skin.manifest.stages.map(\.animation) + [skin.manifest.completed]
                while !Task.isCancelled {
                    for name in sequence {
                        try Task.checkCancellation()
                        guard let animation = skin.manifest.animations[name] else { continue }
                        animationName = name
                        let cycleDuration = Double(animation.frameCount) / animation.framesPerSecond
                        try await Task.sleep(for: .seconds(cycleDuration))
                    }
                }
            } catch is CancellationError {
            } catch {
                hasFailed = true
            }
        }
        .accessibilityHidden(true)
    }
}
