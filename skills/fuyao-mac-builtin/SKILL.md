---
name: fuyao-mac-builtin
description: "查 macOS 内置零安装命令：TTS、剪贴板、通知、截图、转码、文档转换、防睡眠、快捷指令。"
---

# fuyao-mac-builtin — macOS 内置命令速查（agent 零安装工具箱）

> **fuyao series**: crafted and maintained by **Fuyao (扶摇)**; reusable by any skill-capable agent.
> **Positioning**: macOS only · **zero-install** · 纯文档型 skill（无脚本，命令直接跑）

这是「这台 Mac 上不用装任何东西就能用的能力」清单。写它的原因是：**装第三方库之前，先看一眼系统里是不是已经有了。**

> 姊妹 skill：`fuyao-mac-ocr-lite`（图像/PDF 提字）、`fuyao-mac-stt-lite`（语音转文字）、`fuyao-mac-spotlight`（全盘搜索）、`fuyao-mac-cleanup`（腾空间）。

## 一、最常被忽略的四件套

### 1. 朗读 / 配音（TTS）

```bash
say "要念的文字"                                   # 直接出声
say -v Tingting "中文文本"                          # 指定音色（中文女声 Tingting）
say -v '?'                                         # 列出系统所有音色
say -v Tingting "文本" -o out.aiff                  # 存成音频
afconvert out.aiff out.m4a -f m4af -d aac          # 转 m4a（体积小 10 倍以上）
```

- 零安装、离线、几十种音色；**质量低于 Kokoro/IndexTTS 之类，但成本为零**，简单配音/任务完成提醒足够
- ⚠️ 新版 say 上 `--data-format` 参数会报错，别加
- 实测：一句 6 秒音频约 29KB（aiff）

### 2. 剪贴板（人机最短通道）

```bash
pbpaste                       # 读剪贴板
echo "hello" | pbcopy         # 写剪贴板
pbpaste | head -c 500         # 先截断再进上下文，别把几 MB 灌进去
```

用户说「我刚复制了一段」，直接 `pbpaste` 拿，不要求他再粘一遍。

### 3. 系统通知（任务完成提醒）

```bash
osascript -e 'display notification "清理完成，释放 12GB" with title "扶摇" sound name "Glass"'
```

长任务跑完弹一条，比往聊天里刷消息轻。

### 4. 防睡眠（长任务必备）

```bash
caffeinate -i <命令>          # 命令跑完自动恢复
caffeinate -dimsu -t 3600    # 或固定阻断 1 小时
```

转写/渲染/下载几十 G 的任务，不加 `caffeinate` 可能中途睡过去。

## 二、文件与媒体

| 需求 | 命令 | 备注 |
|---|---|---|
| 文档格式互转 | `textutil -convert docx a.html` | html/rtf/docx/txt/odt 互转，零安装 |
| 图片缩放/转格式 | `sips -Z 1600 in.png --out out.jpg` | 批量裁切/旋转/改 DPI 都行 |
| 音频转码 | `afconvert in.wav out.m4a -f m4af -d aac` | 系统原生 |
| 音视频转码 | `avconvert --preset PresetMediumQuality --source in.mov --output out.mp4` | 视频压缩/改封装 |
| 截图 | `screencapture -x out.png` | `-x` 静音；`-R x,y,w,h` 指定区域；`-i` 交互 |
| 生成缩略图 | `qlmanage -t -s 1024 -o . file.pdf` | QuickLook 直接出缩略图 |
| 压缩 | `ditto -c -k --sequesterRsrc --keepParent dir out.zip` | 保留资源分叉，比 zip 可靠 |

## 三、系统级

| 需求 | 命令 | 备注 |
|---|---|---|
| 读写配置 | `defaults read <bundle-id>` / `defaults write` | 系统/App 偏好 |
| Plist 处理 | `plutil -p file.plist` / `plutil -convert json` | 看/转 plist |
| 存密钥 | `security add-generic-password -a me -s svc -w 'key'` | 存钥匙串，不落明文 config |
| 触发快捷指令 | `shortcuts list` / `shortcuts run "名称"` | 调用户配好的自动化 |
| 系统日志 | `log show --last 5m --predicate 'process == "X"'` | 调系统级问题 |
| 语言包/资产状态 | `mdls`, `system_profiler SPSoftwareDataType` | 系统信息 |

## 四、用 Swift 直接调系统框架（无需安装 SDK）

`swift xxx.swift` 就能跑，Xcode CLT 自带编译器。已实测过的：

| 能力 | 框架 / API | 实测结论 |
|---|---|---|
| 情感分析 | `NLTagger(.sentimentScore)` | 段落级 -1~+1，中文可用 ✅ |
| 语言识别 | `NLLanguageRecognizer` | 秒判 zh-Hans ✅ |
| 命名实体 NER | `NLTagger(.nameType)` | 人名/地名可用；组织名会误判（"小红书"→人名）⚠️ |
| 视频抽帧 | `AVAssetImageGenerator` | 取封面/关键帧 ✅ |
| 图像相似度 | `VNGenerateImageFeaturePrintRequest` | 可用于图片去重（未逐项实测） |
| PDF 提字 | `PDFKit` | 文字层直读 ✅（scanned 件走 Vision OCR） |
| 语音转写 | `SpeechAnalyzer`（macOS 26+） | 见 `fuyao-mac-stt-lite` ✅ |
| 文字识别 | `Vision` `VNRecognizeTextRequest` | 见 `fuyao-mac-ocr-lite` ✅ |

**探路法**：苹果新 framework 的网上资料常是 beta 旧签名。直接 grep SDK 里的 `.swiftinterface` 文件拿真实 API：

```bash
grep -rn "class SpeechTranscriber" ~/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks/
```

## 五、诚实边界（别默认"苹果内置 = 能用"）

- **NLEmbedding 句向量** ❌ 中文句子相似度无区分度（"视频转文字"≈"晚饭吃什么"），不能当语义检索
- **Translation 离线翻译** ⚠️ API 可建 session，但**语言包 CLI 装不了**，只能在系统 UI 里装一次
- **NER 组织名** ⚠️ 会误判，别拿它做实体抽取的硬依赖
- 苹果原生质量梯度：**STT / OCR / 情感分析** 第一梯队（日常可用）；NER 第二梯队；句向量/CLI 翻译不行

## Workflow

1. 接到任务先扫一眼本表：**系统里有没有现成的？**
2. 有 → 直接用，别装包
3. 质量不够（比如 TTS 要商用级）→ 再去装第三方，并记下为什么内置的不行
4. 用了本表没覆盖的系统能力 → 回来补一行，注明实测结论
