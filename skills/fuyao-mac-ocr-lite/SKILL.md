---
name: fuyao-mac-ocr-lite
description: "用于从图片/截图提文字（本地 OCR）。"
---
# fuyao-mac-ocr-lite — Local OCR for macOS (Vision)

> **fuyao series**: crafted and maintained by **Fuyao (扶摇)**, an AI digital companion; reusable by any skill-capable agent.
> **Positioning**: macOS-only · lightweight · **zero-install** · fully local · privacy-safe

## ⚠️ Platform constraint (read first)

- **macOS only** (depends on Apple's Vision framework + AppKit/NSImage; not available on Windows/Linux)
- **Zero-install**: uses only built-in macOS capabilities — no tesseract, no pip, no API keys

## When to use

- The user uploads an image/screenshot and you need to read its text (job posts, chat logs, document pages, table screenshots, etc.)
- The user sends a **PDF** — text-layer extraction first, automatic per-page OCR fallback for scanned PDFs (v1.1)
- The model does not support multimodal input (`view_image` only shows the image to the user; the model cannot see it)
- Image content needs to be converted to text for further processing (summarizing, extracting keywords, writing copy, etc.)

## How it works

- Uses the **macOS Vision framework** (`VNRecognizeTextRequest`) — Apple's neural-network text recognition
- **Fully local**: no network requests, no API keys, no third-party dependencies, privacy-safe
- **Zero-install**: built into macOS, works out of the box
- **PDF (v1.1)**: dual-engine — text layer extracted via **PDFKit** first; if avg. text < 20 chars/page (scanned PDF), each page is rendered to bitmap and OCR'd by Vision as fallback
- Limitation: extracts **text only** — it cannot see image content/colors/layout; complex handwriting recognition is limited

## Usage

### 1. Single-file OCR (most common)

```bash
swift "scripts/ocr.swift" "/path/to/image.png"
```

Default: mixed zh-Hans + en-US, accurate mode. Output printed line by line in reading order.

> Note: adjust the path to your actual skill location (e.g. from the repo root: `swift "skills/fuyao-mac-ocr-lite/scripts/ocr.swift" "<image-path>"`).

### 2. Specify languages

```bash
swift "scripts/ocr.swift" "/path/to/image.jpg" "zh-Hans,en-US,ja-JP"
```

### 3. Fast mode (large images / when speed matters)

```bash
swift "scripts/ocr.swift" "/path/to/image.png" "zh-Hans,en-US" fast
```

### 4. PDF (text layer + OCR fallback, v1.1)

```bash
swift "scripts/ocr.swift" "/path/to/document.pdf"
```

- Text-layer PDF → extracted directly, pages tagged `=== Page N ===`
- Scanned/image-only PDF (avg. < 20 chars/page) → automatic per-page Vision OCR, pages tagged `=== Page N (OCR) ===`
- A one-line stderr note tells you which engine kicked in

## Workflow (for agents)

1. User sends an image **or PDF** → confirm the file path (usually the workspace `media/` dir or a user-specified path)
2. Run `swift "scripts/ocr.swift" "<path>"`
3. Read the output text and continue the task
4. Note: the first `swift` run compiles for a few seconds — this is normal; if it errors, first verify the file exists

## Caveats

- **State the limitation up front**: OCR reads text, not "the image". If the user asks about visual content (colors/composition/aesthetics), be honest that you cannot see it and suggest a multimodal model
- Chinese recognition: Vision handles printed Chinese (screenshots/JDs/news) well; handwriting/very blurry images perform poorly
- Output: one recognized line per line, ordered by position; multi-column layouts may be concatenated — use context to interpret

## File structure

```
fuyao-mac-ocr-lite/
├── SKILL.md          # skill instructions (agents read this)
├── agents/
│   └── openai.yaml   # UI metadata (skill list/display)
└── scripts/
    └── ocr.swift     # OCR script (Vision framework)
```

> Open-source extras (needed for the GitHub repo, not part of the skill itself): README.md / README.zh-CN.md (docs), LICENSE (MIT), .gitignore (excludes local metadata)

## Changelog

- **v2.0.0** (2026-11-06): Renamed from `miao-mac-ocr-lite` to `fuyao-mac-ocr-lite` and moved into the [fuyao-mac-kit](https://github.com/fuyaoai/fuyao-mac-kit) collection. No functional change.

- **v1.2.0** (2026-08-03): Internationalized to English; added README.zh-CN.md (Chinese docs).
- **v1.1.0** (2026-08-03): Generalized — removed business-specific examples; added open-source README.
- **v1.0.0** (2026-08-03): First release. Supports mixed zh-Hans/en-US, accurate/fast recognition levels, reading-order output.
