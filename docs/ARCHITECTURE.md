# 目录与开发约定

应用保持单一 SwiftPM executable target，最低 macOS 14。

## 源码

| 目录 | 职责 |
| --- | --- |
| App | 生命周期、菜单命令、应用状态组合与跨功能动作 |
| Models | 倒计时会话、主题清单、主题实例和只读图像数据 |
| Stores | 可观察状态及业务状态转换 |
| Services/Skins | ZIP 预检、解压、主题验证 |
| Services/Animation | 精灵图和缩略图解码 |
| Services/Audio | 完成音效播放 |
| Services/Persistence | 会话文件读写与失败日志 |
| Views/Settings | 设置窗口内容、通用设置和主题管理 |
| Views/Widget | 悬浮组件与菜单栏菜单 |
| Views/Animation | SwiftUI 动画展示 |
| Platform/Windows | AppKit 悬浮窗口与屏幕定位 |
| Platform/Input | 点击、拖拽与辅助功能桥接 |
| Platform/Rendering | 精灵动画的 AppKit 渲染 |
| Platform/Panels | 系统文件选择器 |
| Support | 统一资源入口、本地化与通知订阅生命周期 |
| Resources | 随 App 打包的内置主题和翻译 |

AppModel 组合 Stores，并协调窗口、导入和音效；不在 SwiftUI 视图里直接启动解压进程或读写会话文件。基础模型不依赖 AppModel。AppKit 类型留在 Platform 和应用生命周期边界。

一般设置视图接收 PreferencesStore 和必要回调；需要跨功能协调的窗口根视图和组件可接收 AppModel。只有实际需要替换实现时才新增协议。

## 命名、格式与注释

- 类型和文件使用 UpperCamelCase；成员使用 lowerCamelCase。
- SwiftUI 视图使用 View 后缀；SceneRoot 表示负责环境和窗口路由的根视图。
- 布尔状态使用可读的断言形式，如 isPlaying、hasFailed、showRemainingTime。
- 路径表达用途，如 spriteSheetPath；时间及帧率表达单位，如 durationMinutes、framesPerSecond。
- Swift 属性重命名通过 CodingKeys 保持既有 JSON 的 spritesheet、fps、from 等字段兼容。UserDefaults 键和 Session.json 路径保持不变。
- `.swift-format` 约定四空格缩进、120 列。运行 `./script/check.sh` 检查格式与严格并发构建。
- 仅在行为约定或调用责任容易被误解时写简短文档注释。设计取舍放在文档。

## 资源与并发

AppResources 是资源入口：安装包优先查找 Contents/Resources 中的 SwiftPM bundle，开发模式回退 Bundle.module。L10n 与 SkinStore 共用该入口。

Stores 和 UI 状态隔离到 MainActor。Timer 回调通过 MainActor 更新视图。SpriteAsset 包装只读 CGImage，使用当前 SDK 的 Sendable 声明，不额外使用 unchecked。

主题导入后台准备并校验暂存目录，成功后由主线程安装。取消传播 CancellationError；调用方负责清理暂存父目录。通知订阅随 NotificationObservation 释放，并从各自注册的通知中心移除。

## 素材与工具

- `Examples/Skins/{PixelSprout,BlackCat}/`：正式 JSON、PNG、ZIP 和预览。
- `Design/Skins/{PixelSprout,BlackCat}/`：生成原图、提示词和历史草稿。
- `Design/Skins/PixelSprout/Legacy/`：已停用的五阶段占位素材生成器。
- `script/assets/`：正式素材整理脚本。需安装该目录 requirements.txt 中的 Pillow。
- `script/packaging/`：DMG 布局与图标/背景生成工具。App 图标依据内置主题清单的完成动画首帧生成。
- `script/build_and_run.sh`：本地构建运行入口，仍由 Codex Run 按钮调用。
- `script/package_dmg.sh`：Universal Release 构建与 DMG 打包。
- `docs/releases/`：发布说明。
- `dist/`、`.build/`：忽略的生成产物。

重构不涉及主题重新绘制、发布版本升级、提交远程或上传 Release。关键修复与验证记录见 `REFACTOR.md`。
