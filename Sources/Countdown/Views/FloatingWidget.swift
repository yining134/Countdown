import SwiftUI

struct FloatingWidget: View {
    let model: AppModel
    @State private var hovering = false

    var body: some View {
        let timer = model.countdown
        let skin = model.selectedSkin
        VStack(spacing: 0) {
            SpriteView(skin: skin, animationName: skin.manifest.animationName(phase: timer.phase, progress: timer.progress),
                       playing: timer.phase != .paused && model.widgetVisible)
                .frame(width: model.preferences.widgetSize, height: model.preferences.widgetSize)
                .overlay { WidgetPointerSurface { model.primaryAction() } }
                .help(timer.phase == .idle || timer.phase == .completed ? "点击开始倒计时，拖动调整位置" : "拖动调整位置")
            HStack(spacing: 8) {
                if timer.phase == .running || timer.phase == .paused {
                    Button { timer.togglePause() } label: {
                        Image(systemName: timer.phase == .paused ? "play.fill" : "pause.fill")
                    }.help(timer.phase == .paused ? "继续" : "暂停")
                }
                Button { model.reset() } label: { Image(systemName: "arrow.counterclockwise") }.help("重置")
                Button {
                    model.openMainWindow?()
                } label: { Image(systemName: "gearshape") }.help("打开主窗口")
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 10)
            .frame(height: 32)
            .background(.regularMaterial, in: Capsule())
            .opacity(hovering ? 1 : 0)
            .allowsHitTesting(hovering)
            .frame(height: 44)
        }
        .frame(width: max(112, model.preferences.widgetSize))
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .onChange(of: model.preferences.widgetSize) { model.panelController?.resize() }
    }
}
