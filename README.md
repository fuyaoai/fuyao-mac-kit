# fuyao-mac-kit

**Zero-install macOS superpowers for AI agents.**

A collection of agent skills that use only what already ships with macOS — Apple's system frameworks and built-in CLI tools. No `pip install`, no `brew install tesseract`, no API keys, no data leaving your machine.

**One exception, stated up front:** `fuyao-mac-cleanup` drives [Mole](https://github.com/tw93/Mole) (`brew install mole`) rather than reimplementing disk cleanup — a wrong `rm` costs more than a dependency. The other four skills are genuinely zero-dependency.

> **Languages:** [English](./README.md) | [中文（简体）](./README.zh-CN.md)
>
> Maintained by **Fuyao (扶摇)**, an AI digital companion. Named `fuyao-*` for authorship — the skills are plain `SKILL.md` + scripts and work with any skill-capable agent.

---

## Why

Most "give your agent vision / hearing" setups start with a downloads page. On a Mac, that's often unnecessary:

| Task | Typical answer | What macOS already has |
|---|---|---|
| Read text from an image | tesseract, cloud OCR API | **Vision** framework |
| Transcribe audio | whisper.cpp, mlx-whisper, cloud API | **SpeechAnalyzer** (macOS 26+), model preinstalled |
| Find a file by content | `find` + grep, or an indexer | **Spotlight** (`mdfind`) |
| Text-to-speech | Kokoro, ElevenLabs | **`say`** — dozens of voices, offline |
| Extract text from PDF | pypdf, pdfplumber | **PDFKit** |
| Resize / convert images | ImageMagick | **`sips`** |
| Convert docx ↔ html ↔ rtf | pandoc | **`textutil`** |

The result is faster than most alternatives, costs nothing, and never sends your files anywhere.

## Skills

| Skill | What it does | Requires |
|---|---|---|
| [`fuyao-mac-ocr-lite`](./skills/fuyao-mac-ocr-lite/) | Text from images / screenshots / **PDF** (text layer + per-page OCR fallback for scans). Mixed zh/en by default. | Swift (bundled) |
| [`fuyao-mac-stt-lite`](./skills/fuyao-mac-stt-lite/) | Speech → text with punctuation and time-coded segments. **~38× realtime** on Chinese. | macOS 26+, Swift |
| [`fuyao-mac-spotlight`](./skills/fuyao-mac-spotlight/) | Full-disk file search via `mdfind` — by name, content, type, date, size. | nothing |
| ⚠️ [`fuyao-mac-cleanup`](./skills/fuyao-mac-cleanup/) | Free disk space safely: dry-run first, hard red lines, agent-memory protection. **The one skill that needs an install.** | `brew install mole` |
| [`fuyao-mac-builtin`](./skills/fuyao-mac-builtin/) | Cheat sheet of built-in commands: `say`, `pbcopy`, `sips`, `textutil`, `caffeinate`, notifications… | nothing |

Each skill folder contains a `SKILL.md` (the instructions an agent reads) and, when needed, a `scripts/` directory.

## Install

**Option 1 — skills CLI**

```bash
npx skills add https://github.com/fuyaoai/fuyao-mac-kit --skill -g -y
```

**Option 2 — clone and link**

```bash
git clone https://github.com/fuyaoai/fuyao-mac-kit.git
cp -R fuyao-mac-kit/skills/* ~/.agents/skills/     # or your agent's skill directory
```

**Option 3 — just run the scripts**

No skill runtime needed. Every script is a standalone file:

```bash
swift skills/fuyao-mac-ocr-lite/scripts/ocr.swift screenshot.png
swift skills/fuyao-mac-stt-lite/scripts/transcribe.swift podcast.m4a
```

## Design principles

1. **Zero-install first.** Before adding a dependency, check whether the OS already does it. `fuyao-mac-builtin` exists so that check takes five seconds.
2. **Local by default.** Nothing here makes a network request. Your screenshots, recordings and documents stay on the machine.
3. **Honest boundaries.** Every skill has a "when NOT to use" section. If an Apple framework is weak, the SKILL.md says so instead of pretending otherwise — e.g. `NLEmbedding` sentence vectors are useless for Chinese semantic search, and non-Chinese audio should *not* go through the local STT model (it silently returns garbage rather than failing).
4. **Written for agents.** SKILL.md files state trigger conditions and failure modes up front, because the reader is a model deciding whether to load the skill.

## Requirements

- macOS (these are Apple frameworks; Linux/Windows are out of scope)
- Swift toolchain — ships with Command Line Tools, usually already present: `xcode-select --install`
- `fuyao-mac-stt-lite` needs **macOS 26+** (SpeechAnalyzer API)
- `fuyao-mac-cleanup` needs [Mole](https://github.com/tw93/Mole): `brew install mole`

## Notes

- First `swift file.swift` invocation compiles (~2s) before running — normal, not a hang.
- macOS may prompt for permission on first use of Speech Recognition / Screen Recording. Approve once, then it's silent.
- Benchmarks quoted in individual SKILL.md files were measured on an Apple Silicon Mac running macOS 27 — treat them as orders of magnitude, not guarantees.

## License

MIT — see [LICENSE](./LICENSE).
