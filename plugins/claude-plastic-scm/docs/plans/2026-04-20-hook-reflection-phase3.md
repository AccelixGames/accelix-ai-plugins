# Plastic-SCM Hook + Post-task Reflection (Phase 3) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** After a destructive `cm` command (`checkin` / `merge` / `label`) succeeds, automatically remind Claude to run a Post-task Reflection — evaluate session friction, ask the user whether to file a gotcha issue, and create one on confirmation — so gotchas get captured as they happen instead of being lost.

**Architecture:** A plugin-shipped PostToolUse hook matches Bash tool uses whose command contains `cm (checkin|merge|label)` and whose exit code is 0. The hook's shell script emits a `hookSpecificOutput.additionalContext` JSON payload, which Claude Code injects as a system reminder on the next turn. The reminder points Claude to the SKILL.md "Post-task Reflection" protocol, which defines friction heuristic, user question template, and issue-creation flow using the existing `gotcha-template.md` schema. No automatic `/cm-lint` invocation or tool-call chain — hooks cannot trigger those; the protocol is inline dialog.

**Tech Stack:**
- Claude Code plugin hooks (`hooks/hooks.json`, `PostToolUse` event)
- Bash script (POSIX-compatible, runs in Git Bash on Windows + macOS/Linux)
- `jq` for JSON parsing (bundled with most dev environments; Git Bash on Windows includes it)
- Existing infrastructure: `commands/cm-lint.md` v1.12.0, `templates/gotcha-template.md`, `gh` CLI

**Scope of this plan:** the trigger (hook) + protocol (SKILL.md) + user-facing template (reflection-prompt.md) — a single cohesive subsystem that ships as v1.13.0. After this plan ships, every `cm checkin/merge/label` success produces a reflection opportunity; user decides yes/no per event.

**Out of scope:**
- Friction heuristic that scans session logs server-side (Claude does self-eval at reflection time instead)
- Parallel auto-capture for `cm merge --to`, `cm resolveconflict`, etc. (extend regex later if needed)
- Batch "capture all friction since last commit" — one reflection per destructive-command success, no batching
- Phase 4: any auto-promotion of hold-counter or lint auto-run on accumulated inbox

---

## Locked design decisions

| # | Area | Decision | Rationale |
|---|------|----------|-----------|
| P3-1 | Hook event | `PostToolUse` (not `UserPromptSubmit` or `Stop`) | Fires after tool success; exit code 0 is the precise "destructive op landed" signal |
| P3-2 | Hook matcher | `matcher: "Bash"`; regex `cm (checkin\|merge\|label)` inside script | `if:` permission-rule filter doesn't support regex; `matcher: "Bash"` + in-script regex is the official-docs pattern |
| P3-3 | Filter precision | Must exclude `cm status`, `cm log`, `cm find`, `cm diff`, `cm cat` etc. Regex anchored to 3 subcommands only | Over-fires are worse than under-fires — too many spurious reflections trains users to ignore them |
| P3-4 | Output shape | `hookSpecificOutput.additionalContext` JSON; Claude reads as system reminder | Only official way to inject context; command hooks cannot trigger tool calls |
| P3-5 | Friction detection | Claude self-evaluates at reflection time against a 5-signal heuristic in `reflection-prompt.md` | Session-log scanning from the hook is unreliable cross-platform; Claude has session context |
| P3-6 | Friction signals | (1) 재시도, (2) 우회·워크어라운드, (3) 추정·가정 사용, (4) 에러 메시지 처리, (5) 문서 재조회 — ≥1 present = friction | User's original principle (`friction ≥ 1회 → 후보`). 5 signals cover observable friction surface |
| P3-7 | No friction → silent | If Claude's self-eval returns all-zero signals, no user question asked | Anti-spam; consistent with user's "smooth-only session = skip" decision |
| P3-8 | User question format | 1-line summary + Y/N prompt; on Y, Claude drafts issue body inline using `gotcha-template.md` structure | Matches user's earlier feedback "skill 마무리 시점에 ... 개선 의견은 딱 한줄정도만. 정확한 파악은 lint에서 함께" |
| P3-9 | Cross-platform | Script uses POSIX sh + `jq`. Test manually on Git Bash; macOS/Linux assumed via standard POSIX | User is on Windows. Git Bash is primary target. macOS/Linux parity via POSIX discipline |
| P3-10 | Failure mode | If `jq` missing or script errors, hook exits non-zero; Claude Code logs but tool call proceeds | `exit 2` would BLOCK cm command retroactively — wrong. Only informational errors |

---

## File Structure

```
plugins/claude-plastic-scm/
├── .claude-plugin/plugin.json                        [MODIFY] 1.12.0 → 1.13.0
├── CHANGELOG.md                                      [MODIFY] 1.13.0 entry
├── hooks/                                            [CREATE dir]
│   ├── hooks.json                                    [CREATE] PostToolUse registration
│   └── reflect-destructive-cm.sh                     [CREATE] matcher script, <= 50 LOC
├── skills/plastic-scm/
│   ├── SKILL.md                                      [MODIFY] + "## Post-task Reflection" section
│   └── templates/
│       └── reflection-prompt.md                      [CREATE] friction heuristic + Q template
└── docs/plans/
    └── 2026-04-20-hook-reflection-phase3.md          [THIS FILE]

.claude-plugin/marketplace.json                       [MODIFY] 1.12.0 → 1.13.0
```

Single responsibility per file:
- `hooks.json` — event registration only (no logic)
- `reflect-destructive-cm.sh` — parse JSON stdin, match regex, emit additionalContext. Nothing else.
- `reflection-prompt.md` — static data: 5 friction signals, user Q template, issue body template
- `SKILL.md` Post-task Reflection section — protocol connecting signal → dialog → gotcha issue

---

## Workspace strategy

Continues the marketplace main-branch pattern established in Phase 1+2. No worktree for this plan — small surface, coordinated commits, plan doc itself commits at end. If any task fails validation, the task-level TDD commit can be reverted before push.

---

## Task 1: Create `hooks/hooks.json` (PostToolUse registration)

**Files:**
- Create: `plugins/claude-plastic-scm/hooks/hooks.json`

The hook manifest registers one PostToolUse handler for Bash tool uses. Script-level regex does the narrow filtering.

- [ ] **Step 1: Write `hooks/hooks.json`**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PLUGIN_ROOT/hooks/reflect-destructive-cm.sh\"",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 2: Verify JSON validity**

Run: `jq . "plugins/claude-plastic-scm/hooks/hooks.json"`
Expected: pretty-printed JSON, no parse errors.

- [ ] **Step 3: Verify `$CLAUDE_PLUGIN_ROOT` env var is the documented one for plugin-shipped hooks**

Per Claude Code hooks docs, `$CLAUDE_PLUGIN_ROOT` expands to the installed plugin's root at hook-exec time. Confirm this usage by `grep -r CLAUDE_PLUGIN_ROOT ~/.claude/plugins/cache` or the skill's docs — if the variable name differs in the installed version, NEEDS_CONTEXT and adjust.

- [ ] **Step 4: Do NOT commit yet** — script file added in Task 2, commit the pair together.

---

## Task 2: Create `hooks/reflect-destructive-cm.sh` (matcher script)

**Files:**
- Create: `plugins/claude-plastic-scm/hooks/reflect-destructive-cm.sh`

The script parses stdin JSON from Claude Code, checks the Bash command matches `cm (checkin|merge|label)` with exit 0, and emits additionalContext.

- [ ] **Step 1: Write script**

```bash
#!/usr/bin/env bash
# reflect-destructive-cm.sh — plastic-scm plugin Post-task Reflection trigger
#
# Input (stdin): Claude Code PostToolUse hook JSON.
# Behavior: if the just-run Bash command matches `cm (checkin|merge|label)` and
# exit code was 0, emit a hookSpecificOutput.additionalContext JSON on stdout
# instructing Claude to follow the SKILL.md "Post-task Reflection" protocol.
# Otherwise: silently exit 0 (no output = no injection).
#
# Exit codes: always 0 unless jq is missing. Never exit 2 — we do not want to
# block cm commands retroactively.

set -u

# Dependency check — jq is part of Git Bash and most dev envs. If missing,
# we skip silently rather than fail the tool call.
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

# Read entire stdin
input=$(cat)

# Extract fields
tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty')
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
exit_code=$(printf '%s' "$input" | jq -r '.tool_response.exit_code // .exit_code // empty')

# Gate 1: Must be a Bash tool use
[ "$tool_name" = "Bash" ] || exit 0

# Gate 2: Command must match destructive cm subcommand at a word boundary.
# Regex explicitly lists 3 subcommands (no partial prefix like `cm checkout`).
# Anchored to whitespace or start-of-line before `cm` to avoid matching
# `mycm checkin` or comments.
if ! printf '%s' "$command" | grep -Eq '(^|[[:space:];|&])cm[[:space:]]+(checkin|merge|label)([[:space:];|&]|$)'; then
  exit 0
fi

# Gate 3: Exit code must be 0 (success). Missing exit_code counted as failure
# to be safe — hooks shouldn't fire on ambiguous outcomes.
[ "$exit_code" = "0" ] || exit 0

# All gates passed — emit additionalContext for Claude.
jq -n '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: "A destructive `cm` command (checkin / merge / label) just completed successfully. Per claude-plastic-scm skill SKILL.md `## Post-task Reflection` protocol, evaluate this session against the 5 friction signals in `skills/plastic-scm/templates/reflection-prompt.md`. If ≥1 signal is present, draft a one-line summary and ask the user whether to capture as a gotcha issue. If all signals are absent, proceed silently."
  }
}'
```

- [ ] **Step 2: Make executable (if filesystem supports it)**

Run: `chmod +x plugins/claude-plastic-scm/hooks/reflect-destructive-cm.sh`
Expected: no output. On Windows/NTFS the bit may be ignored, but Git Bash honors shebangs regardless — so the `bash ...` invocation in hooks.json works either way.

- [ ] **Step 3: Dry-run synthesis test — positive case**

Run:
```bash
echo '{
  "tool_name": "Bash",
  "tool_input": {"command": "cm checkin -c=\"test\""},
  "tool_response": {"exit_code": 0}
}' | bash plugins/claude-plastic-scm/hooks/reflect-destructive-cm.sh
```
Expected: JSON output with `hookSpecificOutput.additionalContext` containing "Post-task Reflection".

- [ ] **Step 4: Dry-run synthesis test — negative case (wrong subcommand)**

Run:
```bash
echo '{
  "tool_name": "Bash",
  "tool_input": {"command": "cm status"},
  "tool_response": {"exit_code": 0}
}' | bash plugins/claude-plastic-scm/hooks/reflect-destructive-cm.sh
```
Expected: empty output (no fire — `cm status` is not destructive).

- [ ] **Step 5: Dry-run synthesis test — negative case (non-zero exit)**

Run:
```bash
echo '{
  "tool_name": "Bash",
  "tool_input": {"command": "cm checkin"},
  "tool_response": {"exit_code": 1}
}' | bash plugins/claude-plastic-scm/hooks/reflect-destructive-cm.sh
```
Expected: empty output (cm failed → no reflection).

- [ ] **Step 6: Dry-run test — word-boundary correctness**

Run:
```bash
echo '{
  "tool_name": "Bash",
  "tool_input": {"command": "echo \"cm checkin instructions\""},
  "tool_response": {"exit_code": 0}
}' | bash plugins/claude-plastic-scm/hooks/reflect-destructive-cm.sh
```
Expected: JSON output (the regex matches a `cm checkin` token with whitespace boundary even inside a quoted echo — this is a known false-positive since the script only sees the command string, not its shell semantics). **This is acceptable**: false-positives on `echo` / `cat` / etc. are rare in practice and cost only one reflection prompt. Document this in the script comments.

- [ ] **Step 7: Commit Tasks 1+2 together**

```bash
cd "C:/Users/splus/.claude/plugins/marketplaces/accelix-ai-plugins"
git add plugins/claude-plastic-scm/hooks/hooks.json \
        plugins/claude-plastic-scm/hooks/reflect-destructive-cm.sh
git commit -m "$(cat <<'EOF'
feat(claude-plastic-scm): PostToolUse hook for destructive cm commands

Plugin-shipped PostToolUse hook fires when a Bash tool use whose command
matches `cm (checkin|merge|label)` exits 0. The script emits an
additionalContext JSON instructing Claude to run the Post-task Reflection
protocol (defined in SKILL.md in a following commit).

Gates:
  1. tool_name == "Bash"
  2. command regex-matches destructive cm subcommand at word boundary
  3. exit_code == 0

No blocking behavior — errors in the script are silent (exit 0).
Known false-positive surface: `echo "cm checkin ..."` style commands
trigger the hook. Cost is one spurious reflection prompt; acceptable.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Create `templates/reflection-prompt.md` (heuristic + Q format)

**Files:**
- Create: `plugins/claude-plastic-scm/skills/plastic-scm/templates/reflection-prompt.md`

Static data file defining the 5 friction signals, the Korean user-question template, and pointers to `gotcha-template.md` for issue body. No workflow logic — that lives in SKILL.md.

- [ ] **Step 1: Write template**

Write this EXACT content to `plugins/claude-plastic-scm/skills/plastic-scm/templates/reflection-prompt.md`:

```markdown
---
name: reflection-prompt
description: Post-task Reflection assets. 5-signal friction heuristic and Korean user-question template used by the claude-plastic-scm skill after PostToolUse hook fires on a successful destructive cm command. Pure data consumed by SKILL.md ## Post-task Reflection.
---

# Post-task Reflection Prompt Assets

## 5 friction signals (self-evaluation)

Claude evaluates the just-ended session against these signals. If **≥ 1** signal is present, friction occurred → proceed to user question. If **all absent**, skip silently (no question asked).

| # | Signal | Examples |
|---|--------|----------|
| 1 | **재시도 (retry)** | 같은 cm 커맨드를 다른 옵션으로 반복, 실패 후 재실행 |
| 2 | **우회·워크어라운드 (workaround)** | 예상 경로가 실패해서 다른 방법으로 우회 (`cm co`로 우회 등) |
| 3 | **추정·가정 (estimation)** | 문서에 없는 동작을 "아마 이럴 것이다"로 진행 → 나중에 검증 필요 |
| 4 | **에러 메시지 처리 (error handling)** | cm/gh/shell 에러 출력 해석 필요했음 |
| 5 | **문서 재조회 (doc re-query)** | skill 문서·CHANGELOG·references를 2회 이상 열거나 grep 반복 |

Notes:
- "session"의 범위 = 이번 destructive cm 커맨드로 이어진 **최근 작업 단위** (최근 ~5-10 tool uses 정도). 세션 전체 아님.
- "smooth" = 5 signals 전부 0회. 이 경우 무조건 skip (유저에게 묻지 않음).
- "borderline" 판단은 보수적으로 — 확신 없으면 물어본다. 유저가 "skip"이라고 말하면 기록 남기고 끝.

## User question template (Korean)

If friction detected, emit this format verbatim (fill `<...>` placeholders):

```
이번 `<cm subcommand>` 작업 중 friction 관찰:
- 감지된 signal: <번호:이름> <번호:이름> …
- 증상 요약: <1줄>
- 개선안 아이디어: <1줄>

gotcha issue로 capture할까? (Y/N, skip시 보류)
```

예시:

```
이번 `cm merge` 작업 중 friction 관찰:
- 감지된 signal: 2:우회 5:문서재조회
- 증상 요약: merge_investigate.sh이 `cm diff` GUI trap 회피 때문에 텍스트 모드 재조회 2회 발생.
- 개선안 아이디어: merge_investigate.sh에 `--text-mode` 강제 옵션 추가 검토.

gotcha issue로 capture할까? (Y/N, skip시 보류)
```

## User response handling

- **Y**: draft issue body using `gotcha-template.md` structure, create with `MSYS_NO_PATHCONV=1 gh issue create --repo <marketplace> --label "skill:plastic-scm,gotcha-open" --body-file <tmp> --title "[cm <subcmd>] <summary>"`. Confirm issue URL to user.
- **N**: no action. Acknowledge briefly ("기록 skip").
- **무응답·기타**: treat as skip (no issue).

## Scope

This template does NOT handle:
- Hold counter logic (that's `/cm-lint` Phase B — hold is a triage decision, not a capture decision)
- Non-cm friction (editor bugs, build failures) — out of claude-plastic-scm scope
- Sessions without a destructive cm command — hook never fires, this protocol never runs
```

- [ ] **Step 2: Verify file**

Run: `grep -c "^## " plugins/claude-plastic-scm/skills/plastic-scm/templates/reflection-prompt.md`
Expected: 4 (5 friction signals / User question template / User response handling / Scope)

Run: `grep -c "^| [0-9] |" plugins/claude-plastic-scm/skills/plastic-scm/templates/reflection-prompt.md`
Expected: 5 (the 5 signal rows)

- [ ] **Step 3: Commit**

```bash
git add plugins/claude-plastic-scm/skills/plastic-scm/templates/reflection-prompt.md
git commit -m "$(cat <<'EOF'
feat(claude-plastic-scm): add reflection-prompt template

5-signal friction heuristic + Korean user-question template +
Y/N response handling. Consumed by SKILL.md Post-task Reflection
section (following commit).

Signals: 재시도 / 우회 / 추정 / 에러처리 / 문서재조회. ≥1 present → ask.
All absent → skip silently. Borderline → conservative (ask).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Add `## Post-task Reflection` to SKILL.md

**Files:**
- Modify: `plugins/claude-plastic-scm/skills/plastic-scm/SKILL.md` (insert new section between "Troubleshooting" and "Environment Notes")

SKILL.md already has 9 `## ` sections (v1.12.0). Insert Post-task Reflection as a new section. The skill is auto-triggered, so this protocol is always in context when cm work is happening.

- [ ] **Step 1: Locate insertion anchor**

Run: `grep -n "^## Troubleshooting\|^## Environment Notes" plugins/claude-plastic-scm/skills/plastic-scm/SKILL.md`
Expected: two line numbers — Troubleshooting comes before Environment Notes. Insert the new section between them.

- [ ] **Step 2: Use Edit to insert new section**

Edit:
- old_string:
```
## Environment Notes
```
- new_string:
```
## Post-task Reflection

**Triggered by:** PostToolUse hook `reflect-destructive-cm.sh` injecting an `additionalContext` system reminder after a successful `cm checkin`, `cm merge`, or `cm label`.

**When the reminder arrives:**

1. **Evaluate friction.** Open `templates/reflection-prompt.md` and self-evaluate the recent ~5-10 tool uses against the 5 signals (재시도 / 우회 / 추정 / 에러처리 / 문서재조회). Count how many are present.

2. **Zero signals → skip silently.** Do not interrupt the user. Log nothing. Smooth sessions are not capture material.

3. **≥ 1 signal → emit the user question** using the exact Korean template in `reflection-prompt.md` § "User question template". Fill the placeholders — subcommand, signal list, 1-line symptom, 1-line improvement idea.

4. **On user response:**
   - **Y** → draft a gotcha issue body using `templates/gotcha-template.md` schema. Populate 증상 / 재현 단계 / 시도 / 해결 또는 가설 / 개선안 / 영향 범위 from the session. Create via `MSYS_NO_PATHCONV=1 gh issue create --repo AccelixGames/accelix-ai-plugins --label "skill:plastic-scm,gotcha-open" --title "[cm <subcmd>] <summary>" --body-file <tmp-file>`. Report the issue URL.
   - **N** or no clear response → acknowledge "기록 skip" in one line. No issue created.

5. **Do not auto-run `/cm-lint`.** Capture is intentionally decoupled from processing. The user processes accumulated issues at their own cadence.

**Scope of this protocol:**
- Fires only for destructive cm success (hook's 3-gate filter). Never for `cm status`, `cm log`, etc.
- Reflection is about the *recent work unit* that led to this command, not the whole conversation.
- Rejecting the capture does not create `gotcha-rejected` — rejection is for triaged issues in `/cm-lint`, not pre-capture skips.

**False-positive note:** the hook regex can fire on non-cm commands that contain the literal string `cm checkin` etc. (e.g., `echo "cm checkin"`). When this happens, your friction signals will be all-zero and step 2 silently skips — no user burden.

## Environment Notes
```

- [ ] **Step 3: Verify SKILL.md now has 10 sections**

Run: `grep -c "^## " plugins/claude-plastic-scm/skills/plastic-scm/SKILL.md`
Expected: 10 (previously 9)

Run: `grep -n "^## Post-task Reflection" plugins/claude-plastic-scm/skills/plastic-scm/SKILL.md`
Expected: one match

- [ ] **Step 4: Commit**

```bash
git add plugins/claude-plastic-scm/skills/plastic-scm/SKILL.md
git commit -m "$(cat <<'EOF'
docs(claude-plastic-scm): SKILL.md adds Post-task Reflection protocol

5-step protocol consumed when the PostToolUse hook injects the
reflection reminder: friction eval → zero/skip or ≥1/ask → Y→issue
or N→skip. Uses gotcha-template.md schema + reflection-prompt.md
question format.

Capture is decoupled from processing: /cm-lint remains manual.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Version bump + CHANGELOG + plan doc commit

**Files:**
- Modify: `plugins/claude-plastic-scm/.claude-plugin/plugin.json` — `1.12.0` → `1.13.0`
- Modify: `.claude-plugin/marketplace.json` — `1.12.0` → `1.13.0`
- Modify: `plugins/claude-plastic-scm/CHANGELOG.md` — new `## [1.13.0]` entry
- Add: `plugins/claude-plastic-scm/docs/plans/2026-04-20-hook-reflection-phase3.md` (this file)

Two commits: release, then plan doc.

- [ ] **Step 1: Bump `plugin.json`**

Edit:
- old_string: `"version": "1.12.0",`
- new_string: `"version": "1.13.0",`

- [ ] **Step 2: Bump `marketplace.json`**

Edit (scope by claude-plastic-scm block):
- old_string:
```
      "name": "claude-plastic-scm",
      "description": "PlasticSCM (Unity Version Control) workflow automation — checkin, merge comments, branch info, status, history, diff",
      "version": "1.12.0",
```
- new_string:
```
      "name": "claude-plastic-scm",
      "description": "PlasticSCM (Unity Version Control) workflow automation — checkin, merge comments, branch info, status, history, diff",
      "version": "1.13.0",
```

- [ ] **Step 3: Add CHANGELOG entry**

Edit:
- old_string: `## [1.12.0] - 2026-04-20`
- new_string:
```
## [1.13.0] - 2026-04-20

### 추가 — Phase 3: Hook 기반 auto-capture + Post-task Reflection 프로토콜

- **PostToolUse hook** (`hooks/hooks.json` + `hooks/reflect-destructive-cm.sh`) — Bash tool 사용이 `cm (checkin|merge|label)`와 매칭되고 exit 0이면 `additionalContext` JSON으로 reflection 알림 inject. 3-gate 필터(tool_name=Bash, regex 매칭, exit 0)로 과도 발화 차단.
- **SKILL.md `## Post-task Reflection` 섹션** — 5-step 프로토콜: friction 평가 → 0시 skip, ≥1시 유저 질문 → Y→gotcha 이슈 생성, N→기록 skip. `/cm-lint` 자동 실행 없음 (capture와 processing 의도적 분리).
- **`templates/reflection-prompt.md`** — 5개 friction signal(재시도 / 우회 / 추정 / 에러처리 / 문서재조회) + 유저 질문 한국어 템플릿 + Y/N 응답 핸들링. 모든 signal=0이면 묻지 않음.

### 설계 결정 (locked)

- 트리거: **PostToolUse** (아님: UserPromptSubmit, Stop)
- 매처: `matcher: "Bash"` + script 내부 regex (if:는 정규식 미지원)
- 필터 정확성: `cm status/log/find/diff/cat` 등 read-only 제외
- 출력: `additionalContext` JSON (도구 호출 트리거 불가)
- Friction 판단: Claude 자가 평가 (세션 로그 scanning은 크로스플랫폼 불안정)
- 실패 모드: hook script 에러는 exit 0으로 조용히 삼킴 (cm 커맨드 retroactive 차단 금지)

### 알려진 한계

- 인용문 내 `cm checkin` 같은 false-positive 가능 — friction signal 0으로 자연 필터됨
- `jq` 미설치 환경에서 hook 조용히 skip (Windows Git Bash / 대부분 dev env 기본 포함)
- `cm merge --to=<branch>`는 현재 regex 매치됨 (원한 바). 다른 server-side 변형 필요 시 regex 확장

### 검증

- 합성 stdin 테스트 3건 (positive / wrong-subcmd / non-zero exit) 수동 통과
- live 검증은 v1.13.0 릴리스 후 첫 실사용에서 자동 발생

## [1.12.0] - 2026-04-20
```

- [ ] **Step 4: Verify all 3 files**

Run:
```bash
grep version plugins/claude-plastic-scm/.claude-plugin/plugin.json
grep -A2 '"name": "claude-plastic-scm"' .claude-plugin/marketplace.json | grep version
head -5 plugins/claude-plastic-scm/CHANGELOG.md | grep 1.13.0
```
Expected: all three show `1.13.0`.

- [ ] **Step 5: Commit release**

```bash
git add plugins/claude-plastic-scm/.claude-plugin/plugin.json \
        .claude-plugin/marketplace.json \
        plugins/claude-plastic-scm/CHANGELOG.md
git commit -m "$(cat <<'EOF'
release(claude-plastic-scm): v1.13.0 — Phase 3 hook + reflection

PostToolUse hook + SKILL.md protocol + reflection-prompt.md template.
Destructive cm commands (checkin/merge/label) now trigger a friction
self-evaluation; ≥1 signal prompts the user to capture as a gotcha
issue. Zero-friction sessions skip silently.

Synthetic tests passed (3 dry-runs); live validation occurs on first
real use post-release.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 6: Commit plan doc**

```bash
git add plugins/claude-plastic-scm/docs/plans/2026-04-20-hook-reflection-phase3.md
git commit -m "$(cat <<'EOF'
docs(claude-plastic-scm): add Phase 3 hook + reflection plan

Design doc for v1.13.0. Captures 10 locked decisions (hook event,
matcher strategy, filter precision, output shape, friction detection
model, 5 friction signals, skip-on-smooth, Q format, cross-platform,
failure mode).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Push to origin

- [ ] **Step 1: Push**

```bash
cd "C:/Users/splus/.claude/plugins/marketplaces/accelix-ai-plugins"
git push origin main
```

Expected: push succeeds. Marketplace consumers will see `1.13.0` on next update.

- [ ] **Step 2: Verify remote**

```bash
git log --oneline origin/main -6
```

Expected (newest first):
```
<sha> docs(claude-plastic-scm): add Phase 3 hook + reflection plan
<sha> release(claude-plastic-scm): v1.13.0 — Phase 3 hook + reflection
<sha> docs(claude-plastic-scm): SKILL.md adds Post-task Reflection protocol
<sha> feat(claude-plastic-scm): add reflection-prompt template
<sha> feat(claude-plastic-scm): PostToolUse hook for destructive cm commands
2f29279 merge cm-lint cluster docs-overhaul — label schema + bootstrap + MSYS guard (closes #2 #3 #4)
```

- [ ] **Step 3: Reload plugin locally (for live validation)**

In Claude Code: `/plugin` → update to 1.13.0 → `/reload-plugins`.

Expected output: `Reloaded: 9 plugins · X skills · Y agents · 6 hooks · ...` (hook count should increase by 1 from previous 5).

---

## Done criteria

- [ ] `hooks/hooks.json` exists and parses as valid JSON
- [ ] `hooks/reflect-destructive-cm.sh` exists, is shebang'd, passes 3 synthetic dry-run tests
- [ ] `templates/reflection-prompt.md` has 5-signal table + Korean Q template + Y/N response spec
- [ ] SKILL.md has `## Post-task Reflection` section (total 10 sections)
- [ ] Version = `1.13.0` across plugin.json / marketplace.json / CHANGELOG.md
- [ ] 6 commits pushed to `origin main`:
  - feat: hook (files 1+2)
  - feat: reflection-prompt template
  - docs: SKILL.md protocol
  - release: v1.13.0
  - docs: plan
- [ ] Local Claude Code reloaded and hook count increased by 1
- [ ] Live validation occurs on first real post-release `cm checkin/merge/label` (not a plan task — observational)

---

## Deferred to next plan (Phase 4 and beyond)

- **Hook regex expansion** — `cm resolveconflict`, `cm shelve`, `cm move`, `cm move --on-destination` as they're deemed worth reflecting on
- **Friction signal calibration** — if many false-positives / false-negatives emerge, adjust the 5-signal heuristic (e.g., weight by severity)
- **Cross-session friction accumulation** — if a pattern repeats across sessions, `/cm-lint` clustering already handles it; no new infra
- **Reflection latency telemetry** — measure hook-to-question time; optimize if > 1s
- **Automatic `gotcha-hold` bump** — if user answers Y but the issue already exists (title match), bump hold counter instead of creating duplicate. Requires fuzzy-match logic in the protocol.

---

## Integration with existing Phase 1+2 infrastructure

This plan strictly **adds** to v1.12.0. No existing file's contract changes:
- `commands/cm-lint.md` — untouched. Still the manual processing entry point.
- `templates/gotcha-template.md` — untouched. Still the issue body schema; this plan's auto-capture uses it.
- `templates/regression-smoke.md` — untouched.
- `scripts/merge_investigate.sh` — untouched.
- `references/cm-commands.md` — untouched.

Backward compatibility: users who never trigger destructive cm commands see zero behavior change. Users who do, get a new in-conversation prompt on friction. Uninstalling the plugin removes the hook.
