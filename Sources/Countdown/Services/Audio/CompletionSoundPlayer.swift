import AVFoundation

@MainActor
final class CompletionSoundPlayer {
    private var player: AVAudioPlayer?

    func play(skin: Skin) {
        stop()
        guard let path = skin.manifest.completionSound,
            let url = try? SkinValidator.resource(path, in: skin.directory),
            let audio = try? AVAudioPlayer(contentsOf: url)
        else { return }
        player = audio
        audio.play()
    }

    func stop() {
        player?.stop()
        player = nil
    }
}
