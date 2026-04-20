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

1. **Slash commands before raw `cm`** — For investigation tasks, prefer the bundled slash
   commands (`/cm-status`, `/cm-branch-info`, `/cm-history`, `/cm-diff`) over directly firing
   `cm find` / `cm status` / `cm diff`. They pack several queries into one call, cutting
   round-trip overhead. Use raw `cm` only for queries not covered by slash commands.

2. **Purpose-first exploration** — When the user asks for a "brief" / "strategy" /
   "recommendation", ask yourself whether the info already gathered is enough to brief with,
   **before** expanding exploration further. Gathering completeness ≠ briefing completeness.
   Most status / merge investigations can be briefed within 3–5 queries; past that you're
   probably drifting from intent.

3. **`cm status` defaults to full; `--short` is a follow-up** — Calling `cm status --short`
   first shows only paths and loses the Added/Changed/Private split. That's how a workspace
   full of **empty private folders** gets mistaken for "a ton of pending changes". Open with
   `cm status` (full) or `/cm-status`; use `--short` later when the category structure is
   already known and you just need a path-only re-listing.

## Merge Investigation Playbook

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

## Quick Reference — Most Used Commands

| Purpose | Command |
|---------|---------|
| Current branch | `cm wi` |
| Workspace status | `cm status` / `cm status --short` |
| Checkin (commit) | `cm checkin -c="{comment}"` |
| Switch branch | `cm switch br:{branch}` |
| Update workspace | `cm update` |
| Create branch | `cm branch create {name} br:{parent}` |
| Find changesets | `cm find changeset "where branch='{br}'" --format="{changesetid}\|{date}\|{comment}" --nototal` |
| Find merges | `cm find merge "where dstbranch='{br}'" --format="{dstchangeset}\|{srcchangeset}\|{srcbranch}" --nototal` |
| File history | `cm history "{path}" --format="{changesetid}\|{date}\|{owner}\|{comment}" --nototal` |
| Diff changesets | `cm diff cs:{a} cs:{b} --format="{path}\|{status}" --nototal` |
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
| diff | diff (`cm diff`) | Same concept |
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
   - **Y** → draft a gotcha issue body using `templates/gotcha-template.md` schema. Populate 증상 / 재현 단계 / 시도 / 해결 또는 가설 / 개선안 / 영향 범위 from the session. Create via `MSYS_NO_PATHCONV=1 gh issue create --repo AccelixGames/accelix-ai-plugins --label "skill:plastic-scm,gotcha-open" --title "[cm <subcmd>] <summary>" --body-file <tmp-file>`. Report the issue URL.
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
