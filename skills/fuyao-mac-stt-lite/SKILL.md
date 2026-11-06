---
name: fuyao-mac-stt-lite
description: "用于本地转写音频（视频音轨/录音/播客），中文准，不用 key。"
---
# fuyao-mac-stt-lite — macOS 原生语音转文字（SpeechAnalyzer）

> **fuyao series**: crafted and maintained by **Fuyao (扶摇)**; reusable by any skill-capable agent.
> **Positioning**: macOS 26+ only · zero-install（本地语音模型系统预装）· fully local · **~38x realtime** · 带标点/分段/时间戳

## When to use

- 音频/视频音轨需要转文字（口播稿、会议录音、播客、语音备忘）
- 中文为主的内容（实测中文质量与 whisper-large-v3-turbo 同档，互有胜负，且自带标点）
- 不想装第三方模型（mlx/whisper.cpp/SenseVoice 都不用）

## Usage

```bash
# 中文（默认）
swift "scripts/transcribe.swift" "/path/to/audio.m4a"

# 指定语言
swift "scripts/transcribe.swift" "/path/to/audio.m4a" "en-US"
```

输出：`[start-end s] 分段文本`（带标点）→ `=== FULL (chars, took Xs) ===` 全文。

## 实测基准（2026-09-10，macOS 27.0）

- 133s 中文口播 m4a → 3.5s 转完（38 倍实速，含 Swift 编译共 5.2s）
- 对比：mlx-whisper large-v3-turbo 同段 17s；标点需后处理；两者中文错字率同档
- 支持格式：AVAudioFile 原生可读的（m4a/wav/aiff 实测 m4a ✅；mp3/flac 需先 `afconvert` 转 m4a）
- 已知弱点：数字与字母串偶有怪输出（"20000""no"混入）；人名音译弱（"良木"→"梁木"）；专业术语同音错字与 whisper 同级，重要稿件需人工校对

## Caveats

1. **首次调用**可能弹系统授权（设置 → 隐私与安全性 → 语音识别），脚本会等待 120s
2. 需要 **macOS 26+**（SpeechAnalyzer API）；旧系统用不了
3. 语言支持以 `SpeechTranscriber.supportedLocales` 为准（zh-CN ✅）；不支持的 locale 会直接报错并列出样例
4. 首次用某语言若模型未装，脚本自动下载（进度条）；macOS 27 中文模型出厂已装
5. swift 编译首次约 2s，正常

### ⚠️ 关键：supported ≠ installed，英文要单独下模型（2026-10-10 实测）

**支持 45 种语言（含 en-US/en-GB…），但本机只装了 `zh-CN`、`zh-TW`。** 查已装语言：

```swift
// swift -e '<下面>' 或存成 .swift 跑
// supportedLocales = 支持的全部；installedLocales = 本机已装
print(await SpeechTranscriber.supportedLocales.map { $0.identifier(.bcp47) })
print(await SpeechTranscriber.installedLocales.map { $0.identifier(.bcp47) })
```

**当天实测结论**：
- `en-US` 在 supported 里，但**不在 installed 里** → 传 `en-US` 会触发模型下载。
- 该下载**卡在 0% 不动**（CPU 0%、无网络、进度条永远 0%），裸 swift 脚本环境下**下不动**。不要指望「传 en-US 就自动装好」。
- 把**英文音频送 `zh-CN` 模型** → 得到一个**看似成功、实则乱码**的输出（拉丁字母碎片），**比报错更危险**（会被下游当成功）。

**因此：非中文音频不要走本地 STT。** 走 `agent-reach transcribe`（whisper，自动识别语言，实测英文质量很好）。
fuyao-collect 的 `fetch_video.py` 已内置语言自适应：本地 zh-CN 跑完若 **CJK 占比 < 0.15** 即判为疑似非中文 → 改走 Groq/whisper 重转（见 `transcribe_any` 的 `_cjk_ratio`）。
