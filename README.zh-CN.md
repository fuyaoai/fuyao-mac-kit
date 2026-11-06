# fuyao-mac-kit

**给 AI agent 的 macOS 零安装能力包。**

这里收集的 skill 只用 Mac 上本来就有的东西——苹果系统框架和内置命令行工具。不用 `pip install`，不用 `brew install`，不用 API key，数据不出本机。**这个仓库的定义就是零依赖**：需要装东西的，就不属于这里。

> 想清理磁盘？那个需要外部引擎，所以单独成库：[**fuyao-mac-cleanup**](https://github.com/fuyaoai/fuyao-mac-cleanup)。

> **语言：** [English](./README.md) | 中文（简体）
>
> 由 **扶摇（Fuyao）** 维护。`fuyao-*` 是署名前缀——skill 本体就是 `SKILL.md` + 脚本，任何能读 skill 的 agent 都能用。

---

## 为什么做这个

给 agent 加「看」和「听」的能力，通常第一步就是去下载页。在 Mac 上这一步常常是多余的：

| 要做的事 | 常见方案 | Mac 上已经有的 |
|---|---|---|
| 图片提文字 | tesseract、云端 OCR API | **Vision** 框架 |
| 音频转文字 | whisper.cpp、mlx-whisper、云端 API | **SpeechAnalyzer**（macOS 26+），模型系统预装 |
| 按内容找文件 | `find` + grep，或装索引器 | **Spotlight**（`mdfind`） |
| 文字转语音 | Kokoro、ElevenLabs | **`say`** — 几十种音色，离线 |
| PDF 提文字 | pypdf、pdfplumber | **PDFKit** |
| 图片缩放/转格式 | ImageMagick | **`sips`** |
| docx ↔ html ↔ rtf 互转 | pandoc | **`textutil`** |

结果通常更快、零成本，而且文件从头到尾没离开过这台机器。

## Skill 清单

| Skill | 做什么 | 需要 |
|---|---|---|
| [`fuyao-mac-ocr-lite`](./skills/fuyao-mac-ocr-lite/) | 图片 / 截图 / **PDF** 提文字（文字层直读 + 扫描件逐页 OCR 兜底），默认中英混排 | Swift（系统自带） |
| [`fuyao-mac-stt-lite`](./skills/fuyao-mac-stt-lite/) | 语音转文字，带标点和时间戳分段，中文实测 **~38 倍实时** | macOS 26+、Swift |
| [`fuyao-mac-spotlight`](./skills/fuyao-mac-spotlight/) | `mdfind` 全盘找文件——按文件名、正文、类型、时间、尺寸 | 无 |
| [`fuyao-mac-builtin`](./skills/fuyao-mac-builtin/) | 内置命令速查：`say`、`pbcopy`、`sips`、`textutil`、`caffeinate`、系统通知…… | 无 |

每个 skill 目录里有 `SKILL.md`（给 agent 读的说明），需要时带一个 `scripts/`。

## 安装

**方式一 —— skills CLI**

```bash
npx skills add https://github.com/fuyaoai/fuyao-mac-kit --skill -g -y
```

**方式二 —— clone 后拷进 skill 目录**

```bash
git clone https://github.com/fuyaoai/fuyao-mac-kit.git
cp -R fuyao-mac-kit/skills/* ~/.agents/skills/     # 或你自己 agent 的 skill 目录
```

**方式三 —— 直接跑脚本**

不需要任何 skill 运行时，每个脚本都是独立的：

```bash
swift skills/fuyao-mac-ocr-lite/scripts/ocr.swift 截图.png
swift skills/fuyao-mac-stt-lite/scripts/transcribe.swift 播客.m4a
```

## 设计原则

1. **零安装优先。** 装依赖之前先看一眼系统里是不是已经有了。`fuyao-mac-builtin` 就是为这个「看一眼」准备的。
2. **默认本地。** 这里没有任何一个网络请求。截图、录音、文档全留在机器上。
3. **诚实标边界。** 每个 skill 都有「什么时候别用」一节。苹果框架弱的地方就直说不弱装强——比如 `NLEmbedding` 的中文句向量做语义检索完全没用；非中文音频送本地 STT 模型不会报错，只会**返回看着像成功的一堆乱码**，这比报错更危险。
4. **写给 agent 看。** SKILL.md 把触发条件和失效模式放在最前面，因为读者是一个正在决定「要不要加载这个 skill」的模型。

## 环境要求

- macOS（这些都是苹果框架，Linux/Windows 不适用）
- Swift 工具链——随 Command Line Tools 自带，通常已经有了：`xcode-select --install`
- `fuyao-mac-stt-lite` 需要 **macOS 26+**（SpeechAnalyzer API）

## 说明

- 第一次跑 `swift 文件.swift` 会先编译约 2 秒——正常，不是卡住。
- 首次使用「语音识别」「屏幕录制」时系统会弹权限框，点一次同意，之后不再打扰。
- 各 SKILL.md 里的性能数字测于 Apple Silicon + macOS 27，当数量级参考，别当保证。

## 授权

MIT —— 见 [LICENSE](./LICENSE)。
