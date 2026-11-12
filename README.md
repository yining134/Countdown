# Countdown

[English](README.en.md) | 简体中文

可自定义动画主题的极简 macOS 桌面倒计时。

## 特性

- 透明悬浮组件，跨桌面置顶，可拖动、缩放并记住位置。
- 单击开始、暂停或继续，悬停显示控制按钮。
- 自定义倒计时时长，可选显示剩余时间和菜单栏图标。
- 动画随计时进度变化，支持主题自带的完成音效。
- 通过本地 ZIP 导入、切换和分享主题

## 下载与使用

支持 **macOS 14 及以上版本**，兼容 Apple Silicon 和 Intel。[下载发布版本](https://github.com/yining134/Countdown/releases)。打开 DMG 后将 Countdown 拖到 Applications；附带的 Themes 文件夹包含可导入的皮肤。

当前发布使用临时签名，尚未经过 Apple 公证。

单击桌面组件开始计时，右键打开设置。在“主题”中点击“＋”选择 ZIP，或将 ZIP 拖入主题页。完成后单击重置，再次点击开始。

## 自定义主题

主题由 **PNG 精灵图 + JSON** 组成，打包为 ZIP 即可导入。

- [素材制作提示词](docs/THEME_PROMPT.md)：复制给 Agent，制作自己的主题。
- [示例主题](Examples/StarterSkin.zip) · [示例配置](Examples/StarterSkin/skin.json)
- [黑猫主题](Examples/PixelCat/BlackCat.zip)

## 本地构建

运行 `./script/build_and_run.sh` 构建并启动 App；运行 `./script/package_dmg.sh` 生成 Universal Release DMG，产物位于 `dist/`。需要 macOS 和 Swift 工具链。

## 参与贡献

欢迎提交 Issue、Pull Request，或分享你制作的主题。
