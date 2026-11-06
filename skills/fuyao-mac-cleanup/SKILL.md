---
name: fuyao-mac-cleanup
description: "用于清理 Mac/磁盘满/腾空间/清缓存。dry-run 先行，删前必确认。"
---

# Mac 存储清理手册（fuyao-mac-cleanup）

> **fuyao series**: crafted and maintained by **Fuyao (扶摇)**; reusable by any skill-capable agent.
> 引擎：[tw93/Mole](https://github.com/tw93/Mole) v1.55+（`brew install mole`）。
> 本 skill 只做三件事：调度 Mole 的可靠用法、补 Mole 没覆盖的检查、守住安全红线。
> 不重复造轮子——Mole 的 81KB clean.sh 里有大量路径校验/白名单/防误删逻辑，直接用它。

## 铁律（红线，违反 = 返工）

1. **dry-run 先行**：任何删除类命令（`clean`/`purge`/`uninstall`）先跑 `--dry-run`，把报告给用户看，**用户点头后才真跑**。唯一例外：用户明说"直接清，别问我"。
2. **绝不 sudo 跑 mole 本身**（`sudo mo …` 禁止）。需要系统级权限时：`sudo -v && mo clean`（先验 sudo 再以普通用户跑），这步让用户在终端里自己跑或明确授权后跑。
3. **绝不自动删的东西**：
   - 聊天工具数据：微信/QQ/Telegram 的聊天记录、收发的文件（只能列大小让用户自己在 App 里清）
   - **AI agent 的记忆与工作目录**：如 `~/.claude/`、`~/.codex/`、`~/.agents/` 及任何 agent 自己的会话/日记/知识库目录——删了等于抹掉它的记忆，只能按该 agent 自己的记忆规则清理，且要单独跟用户确认
   - 用户的工作文档/项目目录（Desktop、Documents 下的项目库、笔记库等）——只报告不删
   - `~/.ollama/models`、`~/Library/Caches/ms-playwright` 等 Mole 默认白名单已在保护，别绕过
4. **purge 前识别活跃项目**：正在开发、频繁构建的项目，其 `dist`/`__pycache__` 删了要重新构建——列为"可删但建议保留"，让用户决定。
5. **⚠️ `git filter-repo` 会硬重置工作区**（2026-09-28 血泪教训）：给 git 历史瘦身时，filter-repo 剔除路径后执行 `reset --hard`，**会把工作区里被剔除路径匹配的文件也真实删除**，不只是改历史。若目录里混有「想保留的文件」（如只删旧 checkpoint 却想留最新版），跑前**必须先把要保留的文件移出被剔除路径**或另存一份。删大文件/瘦身前，先确认 `.gitignore` 是否漏掉了大目录（真实案例：漏掉一个 12G 的模型权重目录，它被每日自动快照反复提交，`.git` 涨到 11G）。

## 标准工作流（五步）

### 第 1 步：摸底

```bash
df -h /System/Volumes/Data | tail -1        # 真实可用空间（别用 df / 的快照卷）
mo clean --dry-run                           # 主力：缓存/日志/Trash/残留（~1-2min）
mo purge --dry-run                           # 项目构建产物 node_modules/dist/__pycache__
```

`mo clean --dry-run` 会生成明细清单 `~/.config/mole/clean-list.txt`，报告时引用它。

### 第 2 步：补充体检（Mole 没覆盖的空间大户）

```bash
# 微信数据（中文用户常是最大头）
du -sh ~/Library/Containers/com.tencent.xinWeChat 2>/dev/null
du -sh ~/Library/Containers/com.tencent.xinWeChat/Data/Library/Application\ Support/com.tencent.xinWeChat/*/*/*/*/Message/MessageTemp 2>/dev/null

# iOS 备份（常见大户）
du -sh ~/Library/"Application Support"/MobileSync/Backup 2>/dev/null

# 安装包残留（等价 mo installer，但非交互）
find ~/Downloads ~/Desktop -maxdepth 2 \( -name '*.dmg' -o -name '*.pkg' -o -name '*.xip' -o -name '*.iso' \) -size +50M -exec du -h {} \; 2>/dev/null | sort -rh

# 待删除归档（用户自建的"确认没用了就整体删"的文件夹，如有）
du -sh ~/Desktop/_to_delete 2>/dev/null

# agent 自己的地盘（sessions/logs 超大时单独汇报，按该 agent 的记忆规则处理）
du -sh ~/.claude ~/.codex ~/.agents 2>/dev/null
```

### 第 2.5 步：SIP 保护区的专项（Mole 与常规手段都碰不到）

**Apple Intelligence 模型（macOS 26/27，常 8–30GB）** 躺在 ` /System/Library/AssetsV2/com_apple_MobileAsset_UAF_*`（Siri 理解/TextToSpeech/写作工具/翻译/摘要…），受 SIP 保护，`du`/`mo clean` 都清不掉，`rm` 也删不动。这条链路的正解是**配置描述文件 + 走苹果自己的 asset service 删模型 + 把模型下载指向关着的本地端口**（防系统悄悄装回）。

现成工具：**`omlahore/RemoveMacAI`**（Swift / MIT / 仅 Apple Silicon + macOS 27；`removemacai status` 只读看现状，App 未公证需手动放行，`revert` 可全还原）。实测可释放 8–30GB，视机型与已下载模型而定。

**红线不变**：这属于改系统设置，**先 `status` 只读摸底 → 报告给用户 → 明确授权再动**；不替用户决定关不关 AI。

### 第 3 步：大文件定位（用户问"到底什么占了空间"时）

```bash
mo analyze --json ~ | jq -r '.entries[] | [.size, .path] | @tsv' | sort -rn | head -15   # 一级目录
mo analyze --json ~/Library | jq -r '.large_files[] | [.size, .path] | @tsv'              # Library 大文件
mo analyze --json ~/Downloads | jq -r '.large_files[] | [.size, .path] | @tsv'
```

把字节换算成 GB/MB 再报告。交互式 TUI（`mo analyze`/`mo uninstall`/`mo installer`）对 agent 不可用，需要时让用户自己在终端跑。

### 第 4 步：出报告 → 等确认

给用户的报告格式（按可释放空间排序）：

```
💾 空间现状：已用 X/Y GB，剩 ZGB（W%）
可释放（建议做）：
  1. 系统缓存+应用缓存 —— 9.1GB   ← mo clean，低风险
  2. 项目构建缓存 —— 9.7GB        ← mo purge，删了重 build 即可
  3. 微信聊天文件 —— XGB          ← 要你在微信里清（设置→通用→存储空间），我不能动
需要你决定：
  - 某大文件/大目录 —— XGB         ← 是什么、删了有什么影响
```

### 第 5 步：执行 + 汇报

用户确认后：

```bash
mo clean          # 真跑主力清理
mo purge --yes    # 仅限确认过的项目（或让用户交互跑 mo purge 自己勾选）
```

汇报：清理前后 `df -h` 对比 + freed 空间 + `mo history` 留痕。完成后 `say "清理完成，释放了 X GB"` 提醒用户。

## 命令速查

| 命令 | 用途 | agent 可用性 |
|---|---|---|
| `mo clean --dry-run` → `mo clean` | 缓存/日志/Trash/应用残留 | ✅ 非交互 |
| `mo purge --dry-run` → `mo purge --yes` | node_modules/dist/__pycache__ 等 | ✅ 非交互 |
| `mo analyze --json <路径>` | 大文件/大目录 JSON 报告 | ✅ 最常用 |
| `mo uninstall` | 卸载 App + 残留 | ⚠️ TUI，用户点名应用后让其在终端跑，或 `mo uninstall --dry-run` 转述 |
| `mo history` | 清理历史留痕 | ✅ |
| `mo status` / `mo optimize` / `mo touchid` / `mo completion` | 系统监控/服务优化/TouchID/补全 | ❌ 与清空间无关，不用 |

## 引擎维护

- mole 由 brew 管理，`brew upgrade mole` 升级。skill 触发时若 `command -v mo` 失败 → `brew install mole` 后继续。
- 清理活动日志：`~/Library/Logs/mole/operations.log`。
- 白名单配置：`~/.config/mole/whitelist`（别动，里面是 Mole 的核心保护规则）。
