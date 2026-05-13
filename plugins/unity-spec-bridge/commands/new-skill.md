---
allowed-tools:
  - Bash(grep:*)
  - Bash(test:*)
  - Bash(pwd:*)
  - Bash(date:*)
  - Read
  - Write
  - Edit
description: Scaffold a new skill in the unity-spec-bridge plugin — folder, SKILL.md from template, version bump, CHANGELOG entries, marketplace.json sync, security grep. (unity-spec-bridge 새 스킬 스캐폴딩)
argument-hint: "<skill-name> [--domain quest|so-sync|locale|screen|other]"
---

## Context

- Current directory: !`pwd`
- Marketplace root probe: !`test -f .claude-plugin/marketplace.json && echo "OK" || echo "NOT_MARKETPLACE_ROOT"`
- Today (ISO): !`date +%Y-%m-%d`

## Task

Scaffold a new skill inside the `unity-spec-bridge` plugin. The skill's
human-readable `description`, `<TITLE>`, and Korean trigger keywords are
expected to be present in the current conversation context (gathered by
the `new-skill` skill before invocation). The slash command itself only
carries the kebab-case name and the `--domain` value.

### Step 0 — Marketplace root guard

If the "Marketplace root probe" above prints `NOT_MARKETPLACE_ROOT`, stop
immediately:

> Abort: this command must run from the `accelix-ai-plugins` repo root
> (where `.claude-plugin/marketplace.json` exists). Please `cd` there and
> retry.

### Step 1 — Validate the name argument

Parse the first positional argument as `<name>`.

Required:
- Matches regex `^[a-z][a-z0-9-]+$`
- Length 3–40 characters
- Does NOT contain `projectmaid`, `maidcafe`, `c:\users\` (case-insensitive)

If any check fails, abort with the failed rule and an example
(`unity-quest-author`, `so-sync-customer`).

### Step 2 — Resolve --domain

Default: `other`. Accept one of `quest`, `so-sync`, `locale`, `screen`,
`other`. Anything else → abort.

### Step 3 — Conflict check

Verify these paths do NOT exist:
- `plugins/unity-spec-bridge/skills/<name>/SKILL.md`
- `plugins/unity-spec-bridge/skills/<name>/`

If they do, abort: "skill `<name>` already exists; pick a different name".

### Step 4 — Sanity-check the plugin scaffold

Read all of:
- `plugins/unity-spec-bridge/.claude-plugin/plugin.json`
- `plugins/unity-spec-bridge/CHANGELOG.md`
- `.claude-plugin/marketplace.json`
- `CHANGELOG.md` (root)

If any file is missing, abort: "plugin setup looks broken: `<file>`
missing".

In `marketplace.json` the `plugins[]` array must contain an entry with
`"name": "unity-spec-bridge"`. If absent, abort: "register
unity-spec-bridge in marketplace.json before adding skills".

### Step 5 — Compute the bumped version

Parse `version` from `plugin.json` (semver `MAJOR.MINOR.PATCH`).
Increment PATCH by 1. This is the **new** version. Use it consistently in
the rest of the steps.

Examples:
- `0.1.0` → `0.1.1`
- `0.1.9` → `0.1.10`

### Step 6 — Write the new skill files

Read the template:
- `plugins/unity-spec-bridge/skills/new-skill/references/skill-template.md`

Substitute placeholders using values from the conversation context:
- `<NAME>` → `<name>`
- `<ENGLISH_DESCRIPTION>` → English description gathered earlier
- `<KOREAN_TRIGGERS>` → Korean triggers gathered earlier
- `<TITLE>` → human-readable title (English; reasonable derivation from
  the description is fine if not explicitly supplied)

Write to:
- `plugins/unity-spec-bridge/skills/<name>/SKILL.md` — substituted content
- `plugins/unity-spec-bridge/skills/<name>/references/.gitkeep` — empty file

### Step 7 — Bump plugin.json version

Edit `plugins/unity-spec-bridge/.claude-plugin/plugin.json` — replace the
`version` value with the bumped version from Step 5.

### Step 8 — Append entry to plugin CHANGELOG

Edit `plugins/unity-spec-bridge/CHANGELOG.md`. Insert a new section
immediately after the front matter and before the existing
`## [previous-version]` block:

```markdown
## [<new-version>] - <YYYY-MM-DD>

### 추가
- `<name>` 스킬 — <한 줄 한국어 요약> (domain: `<domain>`)
```

### Step 9 — Append entry to root CHANGELOG

Edit `CHANGELOG.md` at the repo root. Insert a new section similarly:

```markdown
## [<root-new-version>] - <YYYY-MM-DD>

### 추가
- unity-spec-bridge v<prev> → v<new>: `<name>` 스킬 추가 — <한 줄 한국어 요약>
```

For the root marketplace version, bump the PATCH of the highest existing
root version found in `CHANGELOG.md`.

### Step 10 — Sync marketplace.json

Edit `.claude-plugin/marketplace.json` — in the `plugins[]` entry whose
`name` is `unity-spec-bridge`, set `version` to the new plugin version
from Step 5.

### Step 11 — Security grep on the new SKILL.md

Run:

```
grep -inE 'projectmaid|maidcafe|c:\\users\\' plugins/unity-spec-bridge/skills/<name>/SKILL.md
```

If it produces output, print a **warning** (do not delete or revert):

> ⚠️ Forbidden token detected in scaffolded SKILL.md. The files are kept
> as-is; replace the offending tokens with generic placeholders
> (`<ProjectName>`, `<Path>`, etc.) and re-run the grep manually before
> committing.

Otherwise: print `Security grep: passed`.

### Step 12 — Report and instruct

Print, in this order:

1. Files created (the two new files).
2. Files edited (plugin.json, plugin CHANGELOG, root CHANGELOG,
   marketplace.json).
3. Security grep result.
4. Next-step block, verbatim (substitute `<name>`):

   ```
   Review changes:
     git status
     git diff

   Commit (when satisfied):
     git add plugins/unity-spec-bridge .claude-plugin/marketplace.json CHANGELOG.md
     git commit -m "feat(unity-spec-bridge): add <name> skill scaffold"

   Push and update marketplace:
     git push
     claude plugin marketplace update accelix-ai-plugins
     claude plugin update unity-spec-bridge@accelix-ai-plugins
   ```

Do not run `git` commands automatically.

Do not use any other tools. Do not send any other text or messages besides
these tool calls.
