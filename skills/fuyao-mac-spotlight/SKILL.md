---
name: fuyao-mac-spotlight
description: "用于全盘找文件（mdfind）：md·pdf·docx·图片·音频都能全文搜。"
---

# fuyao-mac-spotlight — macOS Spotlight 搜索（mdfind）

> **fuyao series**: crafted and maintained by **Fuyao (扶摇)**; reusable by any skill-capable agent.
> **Positioning**: macOS only · zero-install（Spotlight 索引系统自带）· 毫秒级全盘检索 · 纯文档型 skill（无脚本，CLI 直接跑）

## 何时用（触发场景）

- 用户说"**我之前有个文件/资料讲 XX 的，找一下**"——文件散落在 Desktop/Documents/Downloads/微信文件等，格式不定（md/PDF/docx/图片）
- 按**文件名**模糊找（比 `find` 全盘扫快几个量级）
- 按**元数据**过滤：类型（PDF/图片/音视频）、时间（今天/最近7天）、作者、尺寸、时长
- 找**非 Markdown** 的内容（笔记搜索类 skill 只搜笔记库；mdfind 搜一切被索引的格式）

## 何时不该用（重要边界）

| 场景 | 用什么 | 原因 |
|---|---|---|
| 代码/文本精确搜索、正则、大小写敏感 | `rg` / `grep` | mdfind 是分词索引：**无正则、大小写不敏感、短语控制弱** |
| agent 自己的数据目录（`~/.pi/`、`~/.claude/` 等**隐藏目录**，dot 开头） | `rg` / 直接 read | **Spotlight 默认不索引隐藏目录**！agent 的知识库/工作区搜不到（实测确认） |
| 笔记库语义搜索 | 笔记搜索类工具/skill | mdfind 是字面匹配，不懂语义 |
| 刚创建几秒的文件 | 等几秒再搜 | 索引异步，有秒级延迟 |

## 已验证的查询模式（2026-09-10 实测，macOS 27）

```bash
# 1. 按文件名（中文可用；-name 是文件名通配搜索）
mdfind -name "命理" -onlyin ~/Desktop

# 2. 全文内容（多词 = 都包含；命中会含缓存噪音，取前几条人工判断）
mdfind -onlyin ~/Desktop "whisper 转写"

# 3. 限定目录（强烈建议总是加 -onlyin，缩小噪音）
mdfind -onlyin ~/Documents "合同 到期"

# 4. 按类型 + 时间（Raw 查询语法，$ 要转义）
mdfind 'kMDItemContentTypeTree == "public.pdf" && kMDItemFSContentChangeDate >= $time.today(-7d)'
mdfind 'kMDItemContentTypeTree == "public.image" && kMDItemPixelWidth >= 3000' -onlyin ~/Pictures

# 5. 文件名 Raw 写法（比 -name 更精确控制）
mdfind 'kMDItemFSName == "*报告*.pdf"' -onlyin ~/Documents

# 6. 只列前 N 条（避免大输出）
mdfind -onlyin ~/Desktop "关键词" | head -10
```

常用 kMDItem 属性：`kMDItemFSName`（文件名）`kMDItemTextContent`（正文）`kMDItemAuthors` `kMDItemNumberOfPages` `kMDItemDurationSeconds` `kMDItemPixelWidth/Height`。全部属性：`mdimport -t -d2 <file>` 或 man mdfind。

## 陷阱清单（实测踩过）

1. **stderr 噪音**：中文 locale 下每次运行先吐一行 `Loading keywords and predicates...`——用 `2>/dev/null` 屏蔽
2. **隐藏目录盲区**：dot 目录全部不索引（`~/.pi`、`~/.claude` 等 agent 目录、git 内部目录部分索引）——找 agent 自己的产出用 rg
3. **多词查询 ≠ 引号短语**：短语用**单引号包双引号**：`mdfind -onlyin ~/Desktop '"精确短语"'`；双引号直接裸奔会被 shell 吃掉返回空。全文通配写法：`kMDItemTextContent == "*词*"cd`（c=忽略大小写，d=忽略变音/拼音声调）
4. **噪音文件**：浏览器缓存/剪映数据/logs 也被索引——**永远加 `-onlyin`** 缩小范围 + `head` 截断
5. `mdfind -name` 只匹配文件名，全文要裸关键词或 kMDItemTextContent

## Workflow（agent 用法）

1. 判断场景：找用户的文件/资料 → 本 skill；搜代码/笔记库 → rg 或笔记搜索工具
2. 构造查询：**优先 `-onlyin`**（问一句大概在哪，或从 Desktop/Documents 试起）+ 2-3 个关键词
3. `2>/dev/null | head -10` 标配
4. 命中后用 `mdls <file>` 看元数据（类型/时间/大小）判断是不是目标
5. 没命中 → 换词（同义词/英文）、扩大目录、或换 rg
