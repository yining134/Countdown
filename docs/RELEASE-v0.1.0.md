## Countdown v0.1.0

首个公开发布版本：支持动画皮肤的 macOS 桌面倒计时。

- 透明悬浮组件，支持拖动、调整大小、开始、暂停和重置。
- 倒计时时长、剩余时间显示和菜单栏图标可配置。
- 内置种子成长主题：种子、嫩芽、花苞、开花，共 16 帧。
- 附带黑猫主题：准备、工作、放松和扑屏幕光点，共 16 帧。
- 支持本地 ZIP 主题导入、切换和删除，以及主题完成音效。
- 提供简体中文和英文界面、主题制作提示词。

### 安装

要求 macOS 14 或更新版本。`Countdown-0.1.0-universal.dmg` 同时包含 Apple Silicon 和 Intel 代码。打开 DMG，将 Countdown 拖到 Applications。DMG 内 Themes 文件夹和 Release 附件中的 ZIP 可在设置的“主题”页导入。

此版本使用临时签名（ad hoc），没有 Developer ID 签名或 Apple 公证。Gatekeeper 可能阻止首次打开；仅在确认下载来源后，按 macOS 提示在“系统设置 → 隐私与安全性”中允许打开。

### 校验

Release 附带 DMG 的 SHA-256 校验文件。下载到同一目录后运行：

```sh
shasum -a 256 -c Countdown-0.1.0-universal.dmg.sha256
```
