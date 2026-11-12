import SwiftUI

struct SkinThumbnailView: View {
    let skin: Skin
    let isSelected: Bool
    @State private var preview: SpriteAsset?
    @State private var hasFailed = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let preview {
                    Image(decorative: preview.image, scale: 1)
                        .resizable().interpolation(.none).scaledToFit().padding(8)
                } else if hasFailed {
                    Image(systemName: "photo.badge.exclamationmark")
                } else {
                    ProgressView().controlSize(.small)
                }
            }
            .frame(maxWidth: .infinity).frame(height: 96)
            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
            if isSelected {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor)
                    .padding(6)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12).strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2)
        }
        .task(id: skin.id) {
            do {
                let result = try await AnimationLoader.preview(skin: skin)
                try Task.checkCancellation()
                preview = result
            } catch is CancellationError {
            } catch { hasFailed = true }
        }
    }
}
