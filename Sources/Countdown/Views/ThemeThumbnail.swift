import SwiftUI

struct ThemeThumbnail: View {
    let skin: Skin
    let selected: Bool
    @State private var preview: SpriteAsset?
    @State private var failed = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let preview {
                    Image(decorative: preview.image, scale: 1)
                        .resizable().interpolation(.none).scaledToFit().padding(8)
                } else if failed {
                    Image(systemName: "photo.badge.exclamationmark")
                } else { ProgressView().controlSize(.small) }
            }
            .frame(maxWidth: .infinity).frame(height: 96)
            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
            if selected {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor)
                    .padding(6)
            }
        }
        .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(selected ? Color.accentColor : .clear, lineWidth: 2) }
        .task(id: skin.id) {
            do {
                let result = try await AnimationLoader.preview(skin: skin)
                try Task.checkCancellation()
                preview = result
            } catch is CancellationError {
            } catch { failed = true }
        }
    }
}
