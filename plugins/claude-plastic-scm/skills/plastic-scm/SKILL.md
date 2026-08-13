---
name: plastic-scm
description: >
  PlasticSCM (Unity Version Control) knowledge base and cm CLI reference.
  Auto-triggers when the user discusses PlasticSCM, Unity Version Control,
  cm commands, changeset queries, branch management, merge operations,
  workspace status, or VCS workflows in a PlasticSCM workspace.
  Use this skill whenever the user needs help with cm CLI syntax, PlasticSCM
  concepts, or troubleshooting VCS issues — even if they don't explicitly
  mention "PlasticSCM" but are clearly working in a cm-managed workspace.
  Korean triggers: "플라스틱", "체인지셋", "cm 명령", "병합", "브랜치",
  "체크인", "워크스페이스", "변경 이력", "라벨", "커밋", "푸쉬", "푸시",
  "변경사항 올려", "코드 올려", "변경사항 정리", "코멘트 생성", "체크인 코멘트"
  English triggers: "commit", "push", "checkin comment", "pending changes"
---

# PlasticSCM (Unity Version Control) Knowledge Base

This skill provides cm CLI reference and PlasticSCM workflow knowledge.
For detailed command documentation, see `references/cm-commands.md`.

## Core Principles — Read These First

1. **Project wrapper first** — If the workspace ships its own Plastic wrapper at
   `.agents/skills/_plastic-resource/scripts/plastic` (POSIX) / `plastic.cmd` (Windows) —
   ProjectMaid being the canonical case — that wrapper is the **primary interface** for
   status / diff / checkin / branch / merge / pull / push / sync. See
   "Project Wrapper Routing" below. Everything else in this skill (slash commands, raw `cm`
   patterns) is the fallback for workspaces **without** a wrapper.

2. **Slash commands before raw `cm`** — For investigation tasks, prefer the bundled slash
   commands (`/cm-status`, `/cm-branch-info`, `/cm-history`, `/cm-diff`) over directly firing
   `cm find` / `cm status` / `cm diff`. They pack several queries into one call, cutting
   round-trip overhead. Use raw `cm` only for queries not covered by slash commands.

3. **Purpose-first exploration** — When the user asks for a "brief" / "strategy" /
   "recommendation", ask yourself whether the info already gathered is enough to brief with,
   **before** expanding exploration further. Gathering completeness ≠ briefing completeness.
   Most status / merge investigations can be briefed within 3–5 queries; past that you're
   probably drifting from intent.

4. **`cm status` defaults to full; `--short` is a follow-up** — Calling `cm status --short`
   first shows only paths and loses the Added/Changed/Private split. That's how a workspace
   full of **empty private folders** gets mistaken for "a ton of pending changes". Open with
   `cm status` (full) or `/cm-status`; use `--short` later when the category structure is
   already known and you just need a path-only re-listing.

## Project Wrapper Routing — 래퍼 있는 워크스페이스의 1순위 경로

**감지:** 워크스페이스 루트에 `.agents/skills/_plastic-resource/scripts/plastic`(POSIX) /
`plastic.cmd`(Windows)가 있으면 래퍼 워크스페이스 (대표: ProjectMaid).

**룰:** 래퍼 워크스페이스에서 SCM 작업은 **전부 래퍼를 먼저 쓴다**. 체크인·머지·pull 전에
프로젝트의 `.agents/skills/plastic-<작업>/SKILL.md`를 먼저 읽는다 — 래퍼 인자 계약과
하드 룰의 SSOT가 그쪽이다. 이 플러그인의 slash command와 raw `cm` 레시피는 래퍼가 없는
워크스페이스용 fallback.

### 작업 → 래퍼 명령 매핑

| 작업 | 래퍼 명령 | 플러그인 fallback |
|------|-----------|-------------------|
| 상태 확인 | `plastic status` / `plastic pending-list` | `/cm-status` |
| pending diff | `plastic pending-diff [-Paths …]` → `summary.diffstat.txt` 먼저 | `/cm-diff` (`cm cat` 경로) |
| changeset 조사 | `plastic changeset-list -Changeset N [-SummaryByArea]` → `changeset-diff` | `/cm-diff cs:A cs:B` |
| 체크인 | `plastic checkin -PathListFile … -Title … -Summary …` | `/cm-checkin` |
| cs 코멘트 수정 | `plastic editcomment -Changeset N -CommentFile …` | `/cm-comment` |
| 브랜치 생성/전환/정리 | `plastic branch -Create/-Switch/-List/-Cleanup …` | raw `cm branch` / `cm switch` |
| main으로 반영 | `plastic push` → `comment_context_file` 읽고 `-CommentFile`로 재실행 | `/cm-merge-comment` |
| main에서 받기 | `plastic pull` (충돌 시 `-WritePolicy` → `-Run -PolicyFile` 2단) | — |
| 임의 브랜치 머지 | `plastic merge -Source … -Target …` (자체 프리뷰 포함) | Merge Investigation Playbook |
| 체크인+pull+push | `plastic sync -Run` | — |
| identical 노이즈 정리 | `plastic cleanup -IdenticalOnly [-Run]` | raw `cm undo` |

### 래퍼 워크스페이스 하드 룰 (프로젝트 Codex 스킬과 공유하는 계약)

- **raw `cm diff` 전면 금지** — 경로든 spec 쌍이든 format 플래그든 어떤 형태든. Plastic GUI /
  SemanticMerge가 떠서 CLI를 블록할 수 있다. diff는 래퍼 `pending-diff` / `changeset-diff`,
  또는 `cm cat --file=` + `git diff --no-index` (exit 1 = 차이 있음).
- **main 직접 체크인 금지** — mainBranch(예: `br:/main/beta`, `.config/plastic-skill.json`)에는
  직접 체크인하지 않는다. 작업은 sandbox 자식 브랜치에서, main 반영은 `plastic push`
  (server-side merge)로만.
- **체크인 authorization** — 유저가 이 턴에 명시적으로 지시했거나 named plan stage 실행 승인이
  있을 때만 체크인. "마무리 커밋", "정리 체크인", 진단/리뷰/상태 턴의 체크인 발명 금지.
  승인 1회 = 체크인 1회 (같은 stage의 구현→수리→검증까지 유지, 성공 후 두 번째 체크인은 별도 승인).
- **머지 2-changeset 규율** — 충돌 정책은 하나만 고른다 (`-WritePolicy`로 정책 파일 생성 →
  `-Run -PolicyFile`). 머지 결과부터 **즉시 체크인**하고, 버려진 쪽 복원·컴파일 수리는
  **별도 changeset**. 머지 결과 안에서 hybrid 편집 금지. 어느 쪽 남길지 유저에게 되묻지 않는다
  (진짜 동급이거나 `ManualWorkspace`일 때만 예외).
- **owner 추적** — 팀 계정이 공용(`cm whoami` = 자동 계정)이라 cs owner 필드로 작성자 추적 불가.
  브랜치 생성 시 `-Owner` 필수 (`att:owner` 속성이 SSOT), 머지 코멘트 첫 줄에 `owner: <이름>`.
- **한글 코멘트는 temp 파일로** — 래퍼가 `-CommentFile` / `-commentsfile=`로 처리한다. argv
  인라인 한글은 터미널 코드페이지에서 깨질 수 있다. 코멘트 파일은 워크스페이스 **밖**(temp)에
  만들 것 — 안에 만들면 push/sync가 dirty 판정으로 막힌다.
- **구조화 출력 읽기** — 래퍼 출력의 `blocked=true` / `blocked_reason=` / `recommended_next=`를
  따르고, 완료 판정은 명시 토큰만 신뢰: `checkin_success=true`+`changeset=N`, `sync_done=true`,
  `push_done=true`, `merge_done=true`. 중간 workspace status로 완료 선언 금지.

## Merge Investigation Playbook

> **래퍼 워크스페이스에서는 이 플레이북 대신 `plastic merge -Source … -Target …`(자체 프리뷰 포함)
> 또는 `plastic pull`을 쓴다.** 아래는 래퍼 없는 워크스페이스용.

When merging a source branch into the current branch, the entire investigation is bundled
into a **single script**: `scripts/merge_investigate.sh`. It runs the six `cm` queries needed
to brief the user, in the right order, in one Bash call — no fragmented round-trips, no
accumulated cwd-reset noise.

### Usage

```bash
bash <skill-dir>/scripts/merge_investigate.sh <src-branch> [--workspace <path>]
```

- `<src-branch>` — source branch spec, with or without `br:` prefix (e.g. `/main/feature/x`).
- `--workspace <path>` — workspace root. Required on systems where the Bash tool resets cwd
  between calls (e.g., Windows + Bash tool); omit if the shell already sits in the workspace.

### What it outputs (raw data, labeled sections)

1. `=== Workspace ===` — `cm wi` + parsed current branch.
2. `=== Prior Merges (src -> dst) ===` — any existing merges of src into current.
3. `=== Source Branch Info ===` — name, parent, created-date, owner.
4. `=== Source Branch Changesets ===` — full list of changesets on the source branch, plus
   count / tip / approx-base.
5. `=== Source Tip Comment ===` — comment of the tip changeset.
6. `=== Source Changes ===` — file list that differs. **Mode auto-selected**:
   - If the source has a **single** changeset → `cm log cs:{tip}` shows exactly what that
     commit touched (captures Move/rename operations, which range-diff reports as
     Added+Deleted and loses).
   - If the source has **multiple** changesets → `cm diff cs:{base} cs:{tip}` over the
     branch range, plus a `Source Tip-Only Changes` follow-up from `cm log cs:{tip}` so you
     can still see Move/rename intent of the latest commit.
   - Outputs > 300 entries are auto-summarized (status counts + top-level-path buckets +
     head 100 + tail 30). Full list re-run command is printed.
7. `=== Effective Merge Delta (dst_tip -> src_tip) ===` — `cm diff` of the current branch's
   tip against the source's tip. This is **what would actually change in the workspace if
   you executed the merge**. It already accounts for parent-branch evolution since source
   branched off, so it's usually narrower than the src-internal range in section 6 and is
   the right view for briefing the user about impact. Same auto-summary rules apply.
8. `=== Destination Status ===` — `cm status` (full) of the current workspace.

### After the script completes — STOP INVESTIGATING

The script is the **single source of truth** for merge investigation. Its output is what
you brief with — do **not** run additional `cm diff` / `cm find` / `cm cat` calls to
"cross-verify" or "go one step deeper". Each extra call compounds time cost fast and
almost never changes the briefing outcome. The empirical baseline: a well-run merge brief
takes **≤ 6 cm calls total**; anything past that is drift, not thoroughness.

There are exactly three legitimate reasons to query further:

1. The script printed `mode=unknown`, an empty required section, or a visible query error.
2. An auto-summarized section cut off a detail you genuinely need. Re-run **only** the
   single command the script printed for that section. Do not expand scope.
3. The user's request hinges on information the script did not collect (rare — name the
   missing piece out loud before querying, so the skill can grow later).

Byte-level file comparisons (`cm cat ... | diff`) are **not investigation, they are
verification**. They belong in the execution phase after the user approves a strategy,
not in the briefing phase. The Effective Merge Delta's per-path status already tells you
whether destination differs from source — that is the information you brief with.

When you find yourself thinking "let me just check one more thing before briefing," stop.
That's the drift instinct. Write the briefing from what you have; the user can ask for a
specific deeper check if they want one.

Move directly to Step 5.

### Step 5+ — Briefing the user

With the raw data in hand, judge:

- **Already merged?** A non-empty `Prior Merges` section means skip — no re-merge needed.
- **Has parent drifted?** Compare source's create-date against current's tip. A wide gap
  plus heavy `Moved` / `Changed` entries in `Source Changes` signals the parent branch
  restructured since the source branched off — a straight merge will fight that.
- **Which strategy?** Typical shapes:
  - **A. Full merge** — `cm merge br:{src} --merge [--keepdestination]`. Use when most of
    the source's changes are wanted.
  - **B. Path-scoped cherry-pick** — `cm merge cs:{tip} <path> --cherrypicking --merge`
    per path. Use when only a subset is wanted; agree the whitelist with the user first.
  - **C. File-level copy** — `cm cat "serverpath:{path}#cs:{tip}" > <local>`. Use sparingly
    when the parent has restructured the tree in a way that would break a real merge (this
    loses the Plastic merge-edge in history — document the source cs in the checkin comment).
- **About `--keepdestination`**: it resolves only Changed-vs-Changed conflicts. Added /
  Deleted from source still apply, so "everything else stays on destination" is **not**
  literally guaranteed by `--keepdestination` alone. For strict scoping, use B or C.

### Conflict resolution (after executing a merge)

Use `/cm-status` to see conflicts, then `cm resolve <path> --src|--dst` per file.

## Merge Comment Requirements (2026-05-19~)

**main 브랜치 합치는 모든 머지의 cs 코멘트에 두 필드 필수**. 빈 채 머지하면 룰 위반.

1. **머지 코멘트 박기** — `cm merge ... --to= --merge -c="..."` 형식. 이미 박힌 머지 cs는 사후에 `cm changeset editcomment cs:<N> "..."`로 갈음.
2. **owner 라벨** — 코멘트 본문 첫 줄에 `owner: <작성자 이름>`. `cm whoami`가 공용/자동 계정(예: `accelix.staff@gmail.com`)인 환경에서는 cs의 owner 필드만으로 실제 작성자 추적 불가 → 코멘트 본문에 명시 필수.

### 코멘트 본문 형식

- **첫 줄**: `owner: <이름>`
- **두 번째 단락**: `<sandbox> sandbox의 ... 작업을 <target>로 합칩니다.` 자연어 한 줄
- **본문**: sub-branch 코멘트 묶음 또는 자연어 풀어쓰기 (디코 사전 확인 톤 — 자연어 풀어쓰기 + 짧은 문장)
- **마지막 줄**: `머지 충돌은 없었습니다.` 또는 `충돌 N건 — <누구 데이터 남겼는지>` (충돌 해결 시 의도 추적 위해 반드시 명시)

큰 작업은 박성범 패턴 따라 `[주요 변경]` / `[신규 추가]` / `[삭제]` / `[충돌 해결]` 섹션 분리. 작은 작업은 자연어 한두 문단.

### 예시 — 자연어 풀어쓰기

```
owner: 김규혁

gd010 sandbox의 task-480 후속수정 작업을 main/beta로 합칩니다.

강아지 NPC 가이드용 wish 5건과 새 풀 자산을 박았고, 미녕 위시리스트 wish는 30초 자동 충족 패턴 폐기하고 "소망 이뤄줬어" 보고 버튼으로 충족하는 신구조로 갈아탔습니다. 충족 추적용 게임 이벤트 4종도 신설했고, 강아지가 소파나 영업종료간판 클릭으로 충족시키는 wish용으로 그 가구 자산 2건도 박혔어요. 로케일 5언어 동기화도 마쳤습니다.

머지 충돌은 없었습니다.
```

### 의도

머지 cs를 나중에 누가 검토할 때 "왜 이게 main에 박혔지?" 한 줄로 알 수 있게. 특히 **충돌 해결한 머지는 누구 데이터 남겼는지 명시 안 하면 의도 추적 불가**.

### 슬래시 명령 자동화

`/cm-merge-comment` 슬래시 명령 사용 시 위 4필드 자동 박힘 (Step 6 참조). 직접 `cm merge`로 박을 때만 수동으로 신경.

## Quick Reference — Most Used Commands

| Purpose | Command |
|---------|---------|
| Current branch | `cm wi` |
| Workspace status | `cm status` / `cm status --short` |
| Checkin (commit) | `cm checkin "{file1}" "{file2}" … -c="{comment}"` (파일 명시 — bare 호출은 GUI 체크 상태만 반영) |
| Switch branch | `cm switch br:{branch}` |
| Update workspace | `cm update` |
| Create branch | `cm branch create {name} br:{parent}` |
| Find changesets | `cm find changeset "where branch='{br}'" --format="{changesetid}\|{date}\|{comment}" --nototal` |
| Find merges | `cm find merge "where dstbranch='{br}'" --format="{dstchangeset}\|{srcchangeset}\|{srcbranch}" --nototal` |
| File history | `cm history "{path}" --format="{changesetid}\|{date}\|{owner}\|{comment}" --nototal` |
| Diff changesets | `cm diff cs:{a} cs:{b} --format="{path}\|{status}"` (⚠️ spec 2개 필수·path 인자 금지=GUI·`--nototal` 미지원. 래퍼 워크스페이스선 raw `cm diff` 자체 금지 → `plastic changeset-diff`) |
| Edit CS comment | `cm changeset editcomment cs:{id} "{comment}"` |
| Merge branch | `cm merge br:{source} --merge` |
| Undo changes | `cm undo "{path}"` |

## Git ↔ PlasticSCM Terminology

When users use Git terminology, map it to PlasticSCM equivalents:

| Git | PlasticSCM | Notes |
|-----|-----------|-------|
| commit | checkin (`cm checkin`) | Immediately syncs to server (no separate push needed) |
| push | (included in checkin) | checkin = commit + push |
| pull | update (`cm update`) | Server → local |
| branch | branch (`cm branch`) | Same concept |
| merge | merge (`cm merge`) | Same concept |
| stash | shelve (`cm shelve`) | Temporary storage |
| log | find changeset / history | History queries |
| diff | diff (`cm diff`) | ⚠️ path 인자 = GUI 팝업. 래퍼 워크스페이스선 전면 금지 (`plastic pending-diff`/`changeset-diff` 사용) |
| status | status (`cm status`) | Same concept |
| clone | workspace create | Create workspace |

**Key difference:** PlasticSCM has no staging area. `cm checkin` sends changes directly to the server — there is no separate commit/push workflow.

## Object Specifications

| Type | Format | Example |
|------|--------|---------|
| Changeset | `cs:{id}` | `cs:150` |
| Branch | `br:{path}` | `br:/main/develop` |
| Label | `lb:{name}` | `lb:v1.0` |
| Shelve | `sh:{id}` | `sh:5` |
| Revision | `rev:{path}#cs:{id}` | `rev:file.cs#cs:100` |
| Repository | `rep:{name}@{server}` | `rep:MyRepo@unity` |

## Find Query System

The `cm find` command supports SQL-like queries against VCS objects.

### Queryable Objects
`changeset`, `branch`, `merge`, `label`, `revision`, `attribute`

### WHERE Conditions
```
cm find changeset "where branch='{path}'"
cm find changeset "where owner='{email}' and date > '{date}'"
cm find merge "where dstbranch='{path}' and dstchangeset > {id}"
cm find branch "where parent='{path}'"
```

**⚠️ Quoting:** Always wrap the entire `where ...` clause in outer `"` double quotes with inner `'` single quotes around values. Never emit the outer quotes via `\'` escapes — that produces unclosed-quote EOF errors on Git Bash. See `references/cm-commands.md` → `find` → "Quoting Trap" for details.

### Format Parameters
`{changesetid}`, `{date}`, `{owner}`, `{comment}`, `{branch}`, `{name}`,
`{path}`, `{type}`, `{status}`, `{repository}`, `{server}`

### Common Options
- `--nototal` — Suppress record count line
- `--format="{...}"` — Custom output format
- `--xml` — XML output

## Available Plugin Commands

This plugin also provides slash commands for common workflows:

| Command | Purpose |
|---------|---------|
| `/cm-checkin` | Checkin with auto-generated comment |
| `/cm-comment` | Generate comment only (preview or apply to changeset) |
| `/cm-merge-comment` | Consolidate merge comments |
| `/cm-branch-info` | Branch overview and merge history |
| `/cm-status` | Categorized workspace status |
| `/cm-history` | File/directory change history |
| `/cm-compile-check` | Check Unity compile errors |
| `/cm-hidden` | View and manage hidden changes and ignore patterns |
| `/cm-diff` | Compare changesets/branches/labels |
| `/cm-lint` | Skill auto-diagnosis + repair — triage `skill:plastic-scm` issues, fix with 4-gate verification |

## Troubleshooting

### Common Issues

- **"cm: command not found"** — PlasticSCM CLI is not installed or not in PATH.
  Install from Unity Hub or download from plasticscm.com.

- **"not in a workspace"** — The current directory is not a PlasticSCM workspace.
  Navigate to a workspace root or create one with `cm workspace create`.

- **Merge conflicts** — Use `cm merge br:{source} --merge` and resolve conflicts
  with `cm resolveconflict`.

- **Korean output** — The cm CLI outputs messages in the system locale.
  Branch info from `cm wi` may be in Korean (e.g., "브랜치" instead of "Branch").
  Parse accordingly.

### Information Supplementation

If this skill lacks information about a specific cm command or feature:
1. Run `cm help {command}` to get the built-in documentation
2. Check `references/cm-commands.md` for detailed option lists
3. If the information is useful, consider adding it to the reference file

## Post-task Reflection

**Triggered by:** PostToolUse hook `reflect-destructive-cm.sh` injecting an `additionalContext` system reminder after a successful `cm checkin`, `cm merge`, or `cm label`.

**When the reminder arrives:**

1. **Evaluate friction.** Open `templates/reflection-prompt.md` and self-evaluate the recent ~5-10 tool uses against the 5 signals (재시도 / 우회 / 추정 / 에러처리 / 문서재조회). Count how many are present.

2. **Zero signals → skip silently.** Do not interrupt the user. Log nothing. Smooth sessions are not capture material.

3. **≥ 1 signal → emit the user question** using the exact Korean template in `reflection-prompt.md` § "User question template". Fill the placeholders — subcommand, signal list, 1-line symptom, 1-line improvement idea.

4. **On user response:**
   - **Y** → draft a gotcha issue body using `templates/gotcha-template.md` schema. Populate 증상 / 재현 단계 / 시도 / 해결 또는 가설 / 개선안 / 영향 범위 from the session. Create via `MSYS_NO_PATHCONV=1 gh issue create --repo AccelixGames/accelix-ai-plugins --label "skill:plastic-scm" --title "[cm <subcmd>] <summary>" --body-file <tmp-file>`. Report the issue URL.
   - **N** or no clear response → acknowledge "기록 skip" in one line. No issue created.

5. **Do not auto-run `/cm-lint`.** Capture is intentionally decoupled from processing. The user processes accumulated issues at their own cadence.

**Scope of this protocol:**
- Fires only for destructive cm success (hook's 3-gate filter). Never for `cm status`, `cm log`, etc.
- Reflection is about the *recent work unit* that led to this command, not the whole conversation.
- Rejecting the capture does not create `gotcha-rejected` — rejection is for triaged issues in `/cm-lint`, not pre-capture skips.

**False-positive note:** the hook regex can fire on non-cm commands that contain the literal string `cm checkin` etc. (e.g., `echo "cm checkin"`). When this happens, your friction signals will be all-zero and step 2 silently skips — no user burden.

## Environment Notes

- **Windows + Bash tool** — The Bash tool resets cwd between invocations, so repeated
  `cd "<workspace>" && cm ...` accomplishes nothing and floods the output with "Shell cwd
  was reset" lines. Either pass `--workspace` to bundled scripts like `merge_investigate.sh`,
  use absolute paths in raw `cm` args, or switch to the `PowerShell` tool (which keeps cwd
  across calls).
