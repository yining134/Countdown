# 主题制作提示词 / Theme Creation Prompt

将下面的提示词复制给支持生成图片和处理文件的 Agent，填写你喜欢的主题和动画描述。

Copy the prompt below to an Agent that can generate images and process files. Replace the theme placeholder with your own idea.

```text
请为 macOS Countdown App 制作一套可直接导入的“[填写主题名称与风格]”皮肤，并交付 ZIP 文件。

视觉要求：
- 透明背景、清晰的像素风，无文字、水印和背景场景。
- 4 个阶段：进度 0%、33%、67% 和完成。根据主题设计逐步变化的动作或外观，每阶段 4 帧，循环自然。
- 每帧画布 128×128 像素，主体底部位置一致，四周留透明边距，避免抖动或裁切。
- 完成庆祝用明显的摇晃或闪动，让用户容易注意到。

文件要求：
- 只使用一张静态 RGBA PNG 精灵图 spritesheet.png，不使用 GIF、APNG 或独立帧文件。
- 图集严格为 4 列 × 4 行，即 512×512 像素。不要单元格边框、间距或额外留白。
- 每行一个阶段，帧索引从 0 开始，按从左到右、从上到下排列。
- ZIP 根目录直接包含 skin.json 和 spritesheet.png，不套外层文件夹，排除 .DS_Store 和 __MACOSX。
- skin.json 使用以下结构，可修改 id、name、author，保持帧索引与实际图集一致：

{
  "schemaVersion": 1,
  "id": "my.custom-theme",
  "name": "My Theme",
  "author": "Your Name",
  "spritesheet": "spritesheet.png",
  "frameSize": { "width": 128, "height": 128 },
  "animations": {
    "stage1": { "startFrame": 0, "frameCount": 4, "fps": 4 },
    "stage2": { "startFrame": 4, "frameCount": 4, "fps": 4 },
    "stage3": { "startFrame": 8, "frameCount": 4, "fps": 4 },
    "celebrate": { "startFrame": 12, "frameCount": 4, "fps": 6 }
  },
  "idle": "stage1",
  "stages": [
    { "from": 0, "animation": "stage1" },
    { "from": 0.33, "animation": "stage2" },
    { "from": 0.67, "animation": "stage3" }
  ],
  "completed": "celebrate"
}

生成后请检查 PNG 的真实像素尺寸与透明通道、20 个帧格的对齐、JSON 引用和 ZIP 根目录结构。
如果图片生成工具无法准确生成网格，请先制作素材，再用图像处理工具对齐、裁切并拼接，确保最终文件符合格式。
最后交付可导入的 ZIP，以及一张预览图。
```

## 格式补充

- `stages[].from` 表示已完成比例，第一项必须为 `0`，之后严格递增且小于 `1`；到达 100% 后播放 `completed`。
- 待开始显示 `idle` 的首帧；计时和完成动画循环播放；暂停时冻结。可选 `paused` 动画名用于暂停首帧。
- 每个动画引用连续帧，`fps` 范围 1–30，`frameCount` 范围 1–300；静态素材可设为 1 帧。
- 单帧宽高范围 1–512；图集宽高必须分别为帧宽高的整数倍。图集每边不超过 8192 像素，总面积不超过 16,777,216 像素，单通道位深不超过 8。
- 可选 `completionSound` 字段引用包内 WAV、MP3 或 M4A，时长大于 0 且不超过 10 秒；省略则静音。
- `id` 为 1–80 个字符，以小写字母或数字开头，仅含小写字母、数字、点、横线，不能包含连续两个点；无需全局唯一。
- ZIP 最大 25 MiB，展开最大 100 MiB、最多 200 个条目；使用普通 Store/Deflate ZIP，不支持 ZIP64、加密、符号链接或重复路径。
- 所有资源使用包内相对路径，不允许远程 URL、绝对路径或 `..`。`skin.json` 最大 64 KiB。

