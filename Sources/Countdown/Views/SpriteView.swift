import SwiftUI

struct SpriteView: View {
    let skin: Skin
    let animationName: String
    var playing = true
    @State private var asset: SpriteAsset?
    @State private var error: String?

    private var resourceID: String { skin.directory.path + "/" + skin.manifest.spritesheet }

    var body: some View {
        Group {
            if let asset, let animation = skin.manifest.animations[animationName] {
                SpriteImageView(asset: asset, frameSize: skin.manifest.frameSize, animation: animation,
                                identity: resourceID + ":" + animationName, playing: playing)
            } else if let error {
                Image(systemName: "exclamationmark.triangle").help(error)
            } else {
                ProgressView().controlSize(.small)
            }
        }
        .task(id: resourceID) {
            asset = nil
            error = nil
            do {
                let url = try SkinValidator.resource(skin.manifest.spritesheet, in: skin.directory)
                let result = try await AnimationLoader.load(url)
                try Task.checkCancellation()
                asset = result
            } catch is CancellationError {
            } catch { self.error = error.localizedDescription }
        }
        .accessibilityLabel("\(skin.manifest.name)：\(animationName)")
    }
}
