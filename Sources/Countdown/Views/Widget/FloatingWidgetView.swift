import SwiftUI

struct FloatingWidgetView: View {
    let model: AppModel
    @State private var isHovering = false

    private var canReset: Bool { model.countdown.phase == .running || model.countdown.phase == .paused }
    private var showsControls: Bool { model.countdown.phase != .completed }
    private var controlLabel: String {
        switch model.countdown.phase {
        case .idle: return L10n.text("开始计时")
        case .running: return L10n.text("暂停计时")
        case .paused: return L10n.text("继续计时")
        case .completed: return L10n.text("重置倒计时")
        }
    }
    private var clickLabel: String {
        switch model.countdown.phase {
        case .idle: return L10n.text("开始倒计时")
        case .running: return L10n.text("暂停倒计时")
        case .paused: return L10n.text("继续倒计时")
        case .completed: return L10n.text("重置倒计时")
        }
    }
    private var timeLabel: String {
        let remaining = model.countdown.phase == .idle ? model.preferences.duration : model.countdown.remaining
        let seconds = max(0, Int(ceil(remaining)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    var body: some View {
        let timer = model.countdown
        let skin = model.selectedSkin
        let phase = timer.phase
        VStack(spacing: 0) {
            SpriteView(
                skin: skin, animationName: skin.manifest.animationName(phase: timer.phase, progress: timer.progress),
                isPlaying: (phase == .running || phase == .completed) && model.isWidgetVisible
            )
            .frame(width: model.preferences.widgetSize, height: model.preferences.widgetSize)
            .overlay {
                WidgetPointerSurface(
                    onClick: { model.primaryAction(expectedPhase: phase) }, onSettings: { model.openSettingsWindow?() },
                    label: clickLabel)
            }
            .help(clickLabel + L10n.text("；拖动移动，右键打开设置"))
            if model.preferences.showRemainingTime {
                Text(timeLabel).font(.system(size: 12, weight: .medium, design: .rounded)).monospacedDigit()
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(.regularMaterial, in: Capsule())
                    .frame(height: 24)
                    .accessibilityLabel(L10n.format("剩余时间 %@", timeLabel))
            }
            HStack(spacing: 8) {
                Button {
                    model.primaryAction(expectedPhase: phase)
                } label: {
                    Image(systemName: phase == .running ? "pause.fill" : "play.fill")
                        .font(.system(size: 11, weight: .medium))
                        .frame(width: 24, height: 24)
                        .background(.regularMaterial, in: Circle())
                }
                .help(controlLabel)
                .accessibilityLabel(controlLabel)
                if canReset {
                    Button {
                        model.reset()
                    } label: {
                        Image(systemName: "arrow.counterclockwise").font(.system(size: 11, weight: .medium))
                            .frame(width: 24, height: 24)
                            .background(.regularMaterial, in: Circle())
                    }
                    .help(L10n.text("重置"))
                    .accessibilityLabel(L10n.text("重置倒计时"))
                }
            }
            .buttonStyle(.plain)
            .opacity(isHovering && showsControls ? 1 : 0)
            .allowsHitTesting(isHovering && showsControls)
            .accessibilityHidden(!isHovering || !showsControls)
            .frame(height: 32)
        }
        .frame(width: model.preferences.widgetSize)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .onChange(of: model.preferences.widgetSize) { model.panelController?.resize() }
        .onChange(of: model.preferences.showRemainingTime) { model.panelController?.resize() }
    }
}
