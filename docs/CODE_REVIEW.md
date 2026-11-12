# 项目评审与目录设计

实施状态：用户已确认修改，具体落地结构见 `ARCHITECTURE.md`，修复与验证记录见 `REFACTOR.md`。下文保留修改前的评审证据及原始路径。

评审日期：2026-11-12。范围为当前工作区，包括上一轮尚未提交的 DMG 布局调整。本次仅新增评审文档，不改动业务代码、单测、目录或远程分支。

## 结论

当前为 SwiftPM 单 executable target，业务源码共 24 个 Swift 文件、约 1,233 行。类型基本采用 UpperCamelCase、成员采用 lowerCamelCase；使用值类型建模，用 @MainActor 管理可观察状态，用 AppKit 封装悬浮窗口，方向合理。现有体量适合保留单 target 和轻量分层，无需引入多模块、通用 Repository/UseCase 层或为每个类型添加协议。

目前还不能称为完整符合现代 Swift 并发与发布要求，应先修复以下问题，再统一命名和格式。

## 已确认的问题

### P1：安装包资源路径与 SwiftPM 资源访问器不一致

- 位置：`Sources/Countdown/Services/Localization.swift:5`、`script/build_and_run.sh:33`。
- `L10n.text` 直接访问 `Bundle.module`；本机 SwiftPM 生成的访问器依次尝试 `<Countdown.app>/Countdown_Countdown.bundle` 和构建目录中的绝对路径。
- 打包脚本将资源复制到 `<Countdown.app>/Contents/Resources/Countdown_Countdown.bundle`。实际检查发现前一个位置不存在，后一个位置存在。
- 设置窗口标题在 App 启动时就调用 L10n，因此在没有原始 `.build` 目录的机器上，资源访问器会触发 fatalError。本机运行成功会被构建目录回退掩盖。此结论来自当前生成访问器与安装包布局，尚未在另一台 Mac 上启动复现。
- 建议：新增统一 AppResources 入口，安装包优先使用 Contents/Resources 内的 bundle，开发模式才回退 Bundle.module；本地化与内置皮肤共用该入口。当前 SkinStore 已局部兼容安装包，避免继续维护两套查找方式。
- 验收：在隔离开发资源路径的环境中，从复制后的 App 启动，验证中英文和内置素材；不应仅以开发目录运行成功作为发布依据。

### P2：精灵 Timer 回调违反主线程隔离约束

- 位置：`Sources/Countdown/Platform/SpriteImageView.swift:57`。
- Timer 的 Sendable 闭包直接读取 animation、修改 cursor 并调用 showFrame，而 SpriteCanvas 作为 NSView 子类具有主线程隔离。
- 已执行严格并发诊断并将警告视为错误，编译在此失败。当前 Swift 5 模式的普通构建仍成功，不代表已经完成 Swift 6 迁移。
- 建议：将计时回调明确切回 MainActor，并把推进动画帧提取为私有方法；参考现有 CountdownStore 的主线程转发方式。不要通过继续增加 unchecked 标记压制诊断。

### P2：继续计时使用了暂停前的时间快照

- 位置：`Sources/Countdown/Stores/CountdownStore.swift:57`。
- 继续时更新 deadline，却未同时刷新 now；now 仍是暂停时的时间。remaining 在下一次 Timer 刷新前会加上暂停经过的时间，导致时间显示增加、进度回退、阶段动画短暂切换。
- 临时诊断直接调用现有 CountdownStore：暂停时剩余约 299.999 秒，等待约 1 秒后继续，立即读取为 301.004 秒，增加约 1.004 秒。没有新增仓库单测。
- 建议：继续时只获取一次当前时间，同时赋给 now 并据此计算 deadline，确保同一次状态转换使用同一时间快照。

## Swift 写法与命名建议

以下是项目约定建议，区别于编译错误。Swift 官方 API 指南强调调用点清楚以及布尔值读起来像断言，并不强制目录名称或所有布尔值都使用 is 前缀。

| 当前名称或写法 | 建议 | 目的 |
| --- | --- | --- |
| MainWindow: View | SettingsView | 实际是设置内容，不是 NSWindow |
| MainScene: View | SettingsSceneRoot | 实际是 View，不是 SwiftUI Scene；明确窗口路由职责 |
| FloatingWidget | FloatingWidgetView | SwiftUI 视图统一带 View 后缀 |
| CountdownMenu | CountdownMenuView | 与实际 View 类型一致 |
| ThemeThumbnail | SkinThumbnailView | 内部模型沿用 Skin，界面文案继续使用“主题” |
| importing / playing / selected / failed | isImporting / isPlaying / isSelected / hasFailed | 区分状态和动作 |
| widgetVisible / hovering / editingMinutes | isWidgetVisible / isHovering / isEditingMinutes | 状态语义明确 |
| showRemainingTime / showMenuBarIcon | 可保留，或项目统一为 showsRemainingTime / showsMenuBarIcon | 已有动词可读，不必机械添加 is |
| minutes: String（输入框） | minutesText | 与 PreferencesStore.minutes: Int 区分 |
| PreferencesStore.minutes | durationMinutes | 在调用点表达单位和业务用途 |
| fps（Swift 属性） | framesPerSecond | 完整业务名称；通过 CodingKeys 保持 JSON 的 fps 键 |
| Stage.from（Swift 属性） | progressThreshold | 表达完成比例阈值；JSON from 保持兼容 |
| spritesheet（Swift 属性） | spriteSheetPath | 清楚表达文件路径；JSON spritesheet 保持兼容 |
| chooseZIP() | presentSkinImportPanel() | 区分展示系统面板与真正执行导入 |
| SkinValidator.load | loadValidatedSkin(from:) | 方法实际包含读取、解码和校验 |
| fm / file / access | fileManager / sessionFileURL / hasSecurityScopedAccess | 缩写和路径用途清楚 |

Skin 的运行时实例 id 与 manifest.id 是不同概念，前者区分同一主题被多次导入的实例。重命名和文档应明确两者，不能简单统一回 manifest.id，也不应改变已经发布的 ZIP 字段、主题 ID 和 UserDefaults 键。

格式建议保留现有四空格缩进，并落地 `.swift-format` 配置；统一多行属性声明、条件分支和链式调用。移除同一行中的多个语句及分号，避免为了短而把校验和错误处理挤成一行。import 按稳定顺序排列。不要把文件长度当作唯一拆分标准，目前最大文件仅约 117 行。

## 注释与错误处理

当前业务源码几乎没有注释，不存在大量解释性注释需要删除。无需给所有 internal 属性和简单按钮补注释，也无需照搬 Go 的导出符号注释要求。

只在读者可能误解行为的边界补简短 `///`：

- SkinManifest.Stage 阈值的取值范围、首项为零。
- SkinImporter.prepare 返回的是已校验的暂存目录，调用方安装后负责移除暂存父目录。
- Skin.id 表示安装实例，manifest.id 表示主题声明。
- SpriteAsset 跨并发域传递的只读图像约束；先核查 CGImage 在当前 SDK 的 Sendable 能力，再决定是否仍需 unchecked。

设计取舍、兼容策略和资源布局的说明放在文档，不写成长篇代码注释。

错误处理需按用途区分：清理暂存文件失败可保持尽力清理；Session.json 写入失败目前被 try? 静默吞掉，应至少记录可定位的错误。用户目录无法枚举时，SkinStore 会悄悄只显示内置主题，也应与“目录为空”区分。取消导入应统一采用 CancellationError；目前解压轮询取消会抛出普通 SkinError，因而可能弹出失败提示。

FloatingPanelController 的两个通知观察者应明确移除时机，分别从注册的通知中心注销。当前该控制器主要随 App 存活，此项是生命周期完善建议，不作为已复现的运行错误。

## 职责边界

- AppModel：保留应用组合与跨功能动作；117 行本身不构成“大类”。将 NSOpenPanel 展示移到 Platform，再由动作调用，避免继续扩大 AppKit 依赖。
- Stores：管理可观察状态和业务状态转换；文件访问逐步抽到明确的 SessionPersistence 等小类型。只有出现替换实现的实际需求时才增加协议。
- Models：保存值类型和主题格式。Skin、SpriteAsset 从服务文件中移出；无需拆分极短、紧密关联的嵌套 Manifest 类型。
- Views：按设置、悬浮组件和动画三个界面职责分组，尽量传入明确状态和动作；避免所有后续子视图继续接收完整 AppModel。
- Services：皮肤导入校验、图像加载和音效。SkinValidator 里的错误类型移到独立文件；ZIP 校验保留集中实现，不散落到视图中。
- Platform：只放 AppKit 桥接、面板和系统选择器。SpriteCanvas 可改名 SpriteCanvasView，与 SwiftUI 包装层分开文件。
- Support：统一资源入口、本地化和少量明确命名的配置；不新增含义模糊的 Utils.swift 或万能 Manager。

## 建议目录

以下为目标结构；新文件仅在承担实际职责时创建，不预先建立空模块。

```text
Countdown/
├── Package.swift
├── .swift-format
├── README.md
├── README.en.md
├── Sources/Countdown/
│   ├── App/
│   │   ├── CountdownApp.swift
│   │   ├── AppDelegate.swift
│   │   ├── AppModel.swift
│   │   └── AppCommands.swift
│   ├── Models/
│   │   ├── CountdownSession.swift
│   │   ├── Skin.swift
│   │   ├── SkinManifest.swift
│   │   └── SpriteAsset.swift
│   ├── Stores/
│   │   ├── CountdownStore.swift
│   │   ├── PreferencesStore.swift
│   │   └── SkinStore.swift
│   ├── Services/
│   │   ├── Skins/
│   │   │   ├── SkinImporter.swift
│   │   │   ├── SkinValidator.swift
│   │   │   ├── SkinError.swift
│   │   │   └── ZIPPreflight.swift
│   │   ├── Animation/
│   │   │   └── AnimationLoader.swift
│   │   ├── Audio/
│   │   │   └── CompletionSoundPlayer.swift
│   │   └── Persistence/
│   │       └── SessionPersistence.swift
│   ├── Views/
│   │   ├── Settings/
│   │   │   ├── SettingsSceneRoot.swift
│   │   │   ├── SettingsView.swift
│   │   │   ├── GeneralSettingsView.swift
│   │   │   ├── SkinSettingsView.swift
│   │   │   └── SkinThumbnailView.swift
│   │   ├── Widget/
│   │   │   ├── FloatingWidgetView.swift
│   │   │   └── CountdownMenuView.swift
│   │   └── Animation/
│   │       └── SpriteView.swift
│   ├── Platform/
│   │   ├── Windows/FloatingPanelController.swift
│   │   ├── Input/WidgetPointerView.swift
│   │   ├── Input/WidgetPointerSurface.swift
│   │   ├── Rendering/SpriteImageView.swift
│   │   ├── Rendering/SpriteCanvasView.swift
│   │   └── Panels/SkinImportPanel.swift
│   ├── Support/
│   │   ├── AppResources.swift
│   │   └── Localization.swift
│   └── Resources/
│       ├── StarterSkin/
│       ├── en.lproj/
│       └── zh-Hans.lproj/
├── Examples/
│   └── Skins/                 # 可导入 ZIP、对应 JSON/PNG、最终预览
│       ├── PixelSprout/
│       └── BlackCat/
├── Design/
│   └── Skins/                 # 草稿、生成原图和提示词
│       ├── PixelSprout/
│       └── BlackCat/
├── script/
│   ├── build_and_run.sh        # 保留现有 Run 按钮入口
│   ├── package_dmg.sh
│   ├── packaging/
│   │   ├── dmg_settings.py
│   │   └── release_art.swift
│   └── assets/
│       ├── build_sprout_assets.py
│       └── build_cat_assets.py
├── docs/
│   ├── CODE_REVIEW.md
│   ├── THEME_PROMPT.md
│   └── releases/
│       └── v0.1.0.md
└── dist/                      # 忽略的打包产物
```

迁移资源目录时必须同步 Package.swift 的 resource 声明；迁移脚本需同步 Run 按钮配置、README、脚本内部相对路径及主题生成脚本的 root 推导。旧占位素材生成器 `generate_placeholder.swift` 会生成已废弃的五阶段设计，建议明确归档或移除，避免误覆盖正式主题。先保留资源目录结构，仅迁移代码与设计稿，可降低首轮重构风险。

App 图标当前按固定坐标截取第四行精灵（release_art.swift），主题布局一改就可能截错；后续可采用独立图标源文件，或从 manifest.completed 读取实际帧位置。这是打包工具的耦合问题，不是 Swift 命名问题。

## 检查记录与实施顺序

已执行：

1. 阅读全部业务 Swift 文件、Package.swift、打包脚本及本地化资源。
2. `swift build`：通过。
3. `swift build -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors`：失败，定位到 SpriteCanvas Timer 的主线程隔离问题。
4. `xcrun swift-format lint --recursive Sources`：默认配置给出 1,251 行诊断输出，1,020 行为缩进差异，其余主要为长行、分号和换行。该工具默认使用两空格，而仓库使用四空格，不能把这批差异全当成 Swift 规范错误；应先明确配置，再统计。
5. 临时 CountdownStore 调用诊断：复现继续计时后剩余时间短暂增加。
6. 对比当前生成的 SwiftPM 访问器与安装包路径：确认资源位置不匹配。

建议实施顺序：先修资源访问、主线程 Timer 和继续计时快照，再统一命名与格式，最后迁移目录、整理设计稿和补行为文档。修复和纯结构调整分开提交，便于复查。遵守工作区约定，本轮不创建或修改单测；后续用户确认代码改动后，再补关键行为验证。

参考：[Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)、[Apple：Bundling resources with a Swift package](https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package)。目录方案属于针对本项目的设计建议，不是 Apple 规定的唯一目录规范。
