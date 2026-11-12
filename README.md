# Countdown

一个可自定义皮肤的极简 macOS 桌面倒计时。让一颗种子随时间发芽、成长，也可以换成你自己的角色和动画。

基于 SwiftUI + AppKit，支持 macOS 14+，无账号、无后端、无第三方依赖。当前提供可本地构建的开发版本，尚未配置分发签名和公证。

## 使用

- 透明、无边框的桌面组件，跨桌面置顶，可拖动、调整大小并记住位置。
- 默认 25 分钟。单击开始、暂停或继续；完成后单击重置，再次点击开始。
- 悬停显示开始、暂停、继续或重置按钮；右键打开设置或退出。
- 设置中调整全局时长、组件大小、剩余时间显示和菜单栏图标；时长调整在重置或下一轮开始时生效。
- 在“主题”中点击预览切换皮肤，点击“＋”选择本地 ZIP，也支持拖入 ZIP。右键自定义主题可直接删除。
- 允许重复导入，每份主题独立管理。完成时循环播放完成动画，可选播放皮肤自带音效，无休息循环或系统通知。

## 本地运行

需要 macOS 14+ 和支持 Swift 5.9+ 的 Xcode Command Line Tools。

```bash
./script/build_and_run.sh
```

脚本构建、组装并进行本机 ad-hoc 签名后启动 `dist/Countdown.app`。使用 `--build-only` 仅构建，`--verify` 构建启动并检查进程。也可以使用 `swift build` 检查源码编译。

## 制作和分享皮肤

皮肤采用 **静态 PNG 精灵图 + JSON**，打包成 ZIP 即可导入。通过 GitHub 或其他方式分享 ZIP，接收者下载后本地导入。

可参考 [示例清单](Examples/StarterSkin/skin.json)、[示例精灵图](Examples/StarterSkin/spritesheet.png)，或直接导入 [示例 ZIP](Examples/StarterSkin.zip)。内置素材是占位像素植物，由 [生成脚本](script/generate_placeholder.swift) 绘制。

### You can copy this prompt to an Agent

将下面的提示词复制给支持生成图片和处理文件的 Agent，把“像素植物”替换成你喜欢的主题：

```text
请为 macOS Countdown App 制作一套可直接导入的“像素植物成长”皮肤，并交付 ZIP 文件。

视觉要求：
- 透明背景、清晰的像素风，无文字、水印和背景场景。
- 5 个阶段：种子、发芽、小树苗、成树、完成庆祝。每阶段 4 帧，循环自然。
- 每帧画布 128×128 像素，主体底部位置一致，四周留透明边距，避免抖动或裁切。
- 完成庆祝用明显的摇晃或闪动，让用户容易注意到。

文件要求：
- 只使用一张静态 RGBA PNG 精灵图 spritesheet.png，不使用 GIF、APNG 或独立帧文件。
- 图集严格为 4 列 × 5 行，即 512×640 像素。不要单元格边框、间距或额外留白。
- 每行一个阶段，帧索引从 0 开始，按从左到右、从上到下排列。
- ZIP 根目录直接包含 skin.json 和 spritesheet.png，不套外层文件夹，排除 .DS_Store 和 __MACOSX。
- skin.json 使用以下结构，可修改 id、name、author，保持帧索引与实际图集一致：

{
  "schemaVersion": 1,
  "id": "my.pixel-plant",
  "name": "Pixel Plant",
  "author": "Your Name",
  "spritesheet": "spritesheet.png",
  "frameSize": { "width": 128, "height": 128 },
  "animations": {
    "seed": { "startFrame": 0, "frameCount": 4, "fps": 4 },
    "sprout": { "startFrame": 4, "frameCount": 4, "fps": 4 },
    "sapling": { "startFrame": 8, "frameCount": 4, "fps": 4 },
    "tree": { "startFrame": 12, "frameCount": 4, "fps": 4 },
    "celebrate": { "startFrame": 16, "frameCount": 4, "fps": 8 }
  },
  "idle": "seed",
  "stages": [
    { "from": 0, "animation": "seed" },
    { "from": 0.25, "animation": "sprout" },
    { "from": 0.5, "animation": "sapling" },
    { "from": 0.75, "animation": "tree" }
  ],
  "completed": "celebrate"
}

生成后请检查 PNG 的真实像素尺寸与透明通道、20 个帧格的对齐、JSON 引用和 ZIP 根目录结构。
如果图片生成工具无法准确生成网格，请先制作素材，再用图像处理工具对齐、裁切并拼接，确保最终文件符合格式。
最后交付可导入的 ZIP，以及一张预览图。
```

### 格式补充

- `stages[].from` 表示已完成比例，第一项必须为 `0`，之后严格递增且小于 `1`；到达 100% 后播放 `completed`。
- 待开始显示 `idle` 的首帧；计时和完成动画循环播放；暂停时冻结。可选 `paused` 动画名用于暂停首帧。
- 每个动画引用连续帧，`fps` 范围 1–30，`frameCount` 范围 1–300；静态素材可设为 1 帧。
- 单帧宽高范围 1–512；图集宽高必须分别为帧宽高的整数倍。图集每边不超过 8192 像素，总面积不超过 16,777,216 像素，单通道位深不超过 8。
- 可选 `completionSound` 字段引用包内 WAV、MP3 或 M4A，时长大于 0 且不超过 10 秒；省略则静音。
- `id` 为 1–80 个字符，以小写字母或数字开头，仅含小写字母、数字、点、横线，不能包含连续两个点；无需全局唯一。
- ZIP 最大 25 MiB，展开最大 100 MiB、最多 200 个条目；使用普通 Store/Deflate ZIP，不支持 ZIP64、加密、符号链接或重复路径。
- 所有资源使用包内相对路径，不允许远程 URL、绝对路径或 `..`。`skin.json` 最大 64 KiB。
