# unity-spec-bridge Skill Scaffolder — Design

- **Date**: 2026-05-13
- **Status**: Draft (pending user review)
- **Domain**: 기획→Unity 적용 워크플로 인프라
- **Author session**: Brainstorming with planner

## Goal

Build the pipeline that turns "I want to make a new 기획→Unity skill" into a scaffolded skill that lives inside the `accelix-ai-plugins` marketplace and is shareable with the design team across machines. The skill content itself (Quest authoring, ScriptableObject sync, etc.) is **out of scope** for this session — only the scaffolding pipeline is in scope.

## Context

- Design team works across multiple machines; sharing requires version-controlled location (`~/.claude/` per-user folders won't do).
- `accelix-ai-plugins` is the team's existing Claude Code plugin marketplace (git-tracked), with:
  - 6 plugins already operating (`chatgpt-agent`, `claude-plastic-scm`, `discord-webhook`, `generate-image`, `prof-oak-explain`, `win-file-tools`).
  - Strict information-leak prevention via `check_info_leak.py` hook — team-internal identifiers (`ProjectMaid`, `MaidCafe`, `C:\Users\{name}`, …) must NOT appear in plugin files.
  - Mandatory version/CHANGELOG/marketplace-manifest update workflow on every change (see `accelix-ai-plugins/CLAUDE.md`).
  - Distribution via `claude plugin install/update`.
- Target Unity project: `C:/WorkSpace/AccelixGames/ProjectMaid` (Unity 6000.3.10f1, PlasticSCM).
- Planning workspace SSOT: `C:/WorkSpace/github.io/AccelixGames/mcs-design-workspace` (JSON specs, ADRs, GDD).

## Decisions

| # | Decision | Why |
|---|---|---|
| D1 | Skills live in `accelix-ai-plugins` (git), not `~/.claude/` | Team sharing across machines. |
| D2 | One new plugin `unity-spec-bridge` as the domain container | Plugin name is generic (security rule). All future 기획→Unity skills accumulate here. |
| D3 | Hybrid invocation: **skill** for guidance, **command** for execution | Skill collects intent and disambiguates; command writes files and updates metadata. |
| D4 | Automation stops at file generation + metadata update + security grep | Git `commit`/`push` stays manual — destructive ops require human gate. |
| D5 | Spec lives in `accelix-ai-plugins/docs/specs/` | Spec ↔ implementation in the same repo. |

## Architecture

```
accelix-ai-plugins/                          (existing marketplace, git repo)
├── .claude-plugin/marketplace.json          ← add unity-spec-bridge entry
├── CHANGELOG.md                             ← add summary entry per release
└── plugins/
    └── unity-spec-bridge/                   ★ NEW plugin
        ├── .claude-plugin/plugin.json       (v0.1.0 initial)
        ├── CHANGELOG.md                     (initial entry)
        ├── commands/
        │   └── new-skill.md                 ★ scaffolding executor
        └── skills/
            └── new-skill/                   ★ guidance / decision flow
                ├── SKILL.md
                └── references/
                    └── skill-template.md    (template for skills it generates)
```

Roles:
- **Skill `new-skill`** — Triggered by natural language ("새 스킬 만들기", "스킬 스캐폴딩"). Collects name, description, domain, input shape. Validates no conflict. Delegates to the command.
- **Command `/new-skill`** — Performs the scaffold: writes files, bumps versions, syncs CHANGELOGs, syncs marketplace manifest, runs security grep, prints next-step instructions.
- **Plugin `unity-spec-bridge`** — Container for this scaffolder and all future 기획→Unity skills (Quest authoring, SO data sync, locale apply, screen-spec apply, …).

## Components

### 1. `plugins/unity-spec-bridge/.claude-plugin/plugin.json`

Initial:
```json
{
  "name": "unity-spec-bridge",
  "version": "0.1.0",
  "description": "Bridge skills/commands between spec data and Unity assets",
  "author": "AccelixGames",
  "repository": "https://github.com/AccelixGames/accelix-ai-plugins",
  "license": "MIT",
  "keywords": ["unity", "spec", "scaffolding"]
}
```

### 2. `plugins/unity-spec-bridge/CHANGELOG.md`

Standard Keep-a-Changelog format. Initial entry:
```markdown
## [0.1.0] - 2026-05-13
### Added
- Initial scaffold of `unity-spec-bridge` plugin.
- `new-skill` skill + `/new-skill` command for creating new skills in this plugin.
```

### 3. `plugins/unity-spec-bridge/skills/new-skill/SKILL.md`

Frontmatter:
```yaml
---
name: new-skill
description: Scaffold a new skill in unity-spec-bridge plugin (새 스킬 스캐폴딩, 새 스킬 만들기)
---
```

Body (English, per marketplace rule). Flow:
1. **Collect context** — ask one question at a time:
   - `name` — kebab-case, generic, no team-internal identifiers
   - `description` — one-line English + Korean trigger keywords
   - `domain` — one of: `quest`, `so-sync`, `locale`, `screen`, `other`
   - `input-shape` — slash command args? natural-language trigger? both?
2. **Conflict check** — verify `plugins/unity-spec-bridge/skills/<name>/` does not exist.
3. **Delegate** — invoke `/new-skill <name> --domain <d>` (and any extra args), passing the collected info through.

### 4. `plugins/unity-spec-bridge/commands/new-skill.md`

Frontmatter:
```yaml
---
allowed-tools: Bash(grep:*), Bash(test:*), Edit, Write, Read
description: Scaffold a new skill in unity-spec-bridge (새 unity-spec-bridge 스킬 생성)
argument-hint: "<skill-name> [--domain quest|so-sync|locale|screen|other]"
---
```

Steps:
1. Validate argument format (regex: `^[a-z][a-z0-9-]+$`).
2. Verify we are inside the `accelix-ai-plugins` repo (check `.claude-plugin/marketplace.json` exists at repo root).
3. Re-check conflict.
4. Write `skills/<name>/SKILL.md` from `references/skill-template.md`, substituting placeholders.
5. Write `skills/<name>/references/.gitkeep`.
6. Edit `plugins/unity-spec-bridge/.claude-plugin/plugin.json` — bump patch version.
7. Append a new entry under the **newly bumped** version in `plugins/unity-spec-bridge/CHANGELOG.md` (e.g., a new `## [0.1.1] - YYYY-MM-DD` block).
8. Append summary entry in root `accelix-ai-plugins/CHANGELOG.md`.
9. Sync `unity-spec-bridge.version` in root `.claude-plugin/marketplace.json`.
10. Run security grep on the new `SKILL.md` for forbidden tokens — warn (do not delete) on hit.
11. Print: file list, grep result, next-step commands (`git add`, `git commit`, `git push`, `claude plugin marketplace update`).

End with: "Do not use any other tools. Do not send any other text or messages besides these tool calls." (per marketplace command convention).

### 5. `plugins/unity-spec-bridge/skills/new-skill/references/skill-template.md`

Template for generated skills:
```markdown
---
name: <NAME>
description: <ENGLISH_DESCRIPTION> (<KOREAN_TRIGGERS>)
---

# <TITLE>

## When to use

<WHEN>

## How to use

<HOW>

## References

- `references/...`
```

Placeholders `<NAME>`, `<ENGLISH_DESCRIPTION>`, `<KOREAN_TRIGGERS>`, `<TITLE>`, `<WHEN>`, `<HOW>` get substituted from the command's collected args; sections without a provided value receive a `TODO: …` line.

## Data Flow

```
User (natural language)
  → Skill `new-skill` activates
    → asks name, description, domain, input-shape (1 question per turn)
    → conflict check on filesystem
    → invokes `/new-skill <name> --domain <d>`
      → command validates, writes files, bumps versions, syncs manifests
      → security grep on new SKILL.md
      → prints next-step instructions
User reviews `git status` / `git diff`
  → runs git commit / push / `claude plugin marketplace update` manually
```

Key interface contract: skill→command hand-off is via slash-command argument list. The skill MUST encode all collected fields into the command invocation so the command can run statelessly.

## Error Handling

| Situation | Behavior |
|---|---|
| Invalid name format (uppercase, space, special char) | Command aborts, prints regex and example. |
| Name collision | Skill catches first; command re-validates and aborts on conflict. |
| Forbidden token (`ProjectMaid`, `MaidCafe`, `C:\Users\`) in new SKILL.md | Files remain; **warning** printed; user is instructed to replace with placeholder and re-run grep manually. |
| Missing `plugin.json` or `CHANGELOG.md` in plugin folder | Command aborts before touching anything — "plugin setup looks broken". |
| `unity-spec-bridge` entry absent in root `marketplace.json` | Command aborts — "register the plugin in marketplace first". |
| Edit step fails mid-flight | Command prints "completed up to step N"; user uses `git status` + `git restore` to roll back. |
| Run from outside `accelix-ai-plugins` repo | Command aborts after the marketplace.json check. |
| Git working tree dirty before scaffold | Warning only (does not abort) — user decides. |

**Rollback strategy**: No transactional rollback. Print git state at start and end so user can `git diff` and `git restore` selectively.

**Security-grep scope**: Only the newly created `skills/<name>/SKILL.md`. Pre-existing files are not touched; the marketplace-wide PreToolUse hook already covers global leak detection.

## Testing

No automated test infrastructure in this marketplace. Manual verification:

### Happy path (pre-push)

1. Dry-run with a throwaway name:
   ```
   /new-skill test-scaffold-demo --domain other
   ```
2. Verify:
   - [ ] `skills/test-scaffold-demo/SKILL.md` exists with placeholders substituted
   - [ ] `skills/test-scaffold-demo/references/.gitkeep` exists
   - [ ] `plugin.json` version patch+1
   - [ ] `plugins/unity-spec-bridge/CHANGELOG.md` has new entry
   - [ ] root `CHANGELOG.md` synced
   - [ ] `marketplace.json` `unity-spec-bridge.version` synced
   - [ ] security grep reports `passed`
3. `git diff` — confirm changes are scoped to `unity-spec-bridge` (no foreign file edits).
4. `git restore .` — undo dry run.

### Error paths

Each one runs once; abort/warn message inspected:
- `/new-skill Test Skill` (uppercase + space) → abort
- `/new-skill test-scaffold-demo` after the file exists → abort on second call
- Invoked from a path outside `accelix-ai-plugins` → abort
- Forbidden token planted in description → warning printed

### Integration (post-push)

After git push:
```
claude plugin marketplace update accelix-ai-plugins
claude plugin update unity-spec-bridge
```
Confirm new plugin visible and the dummy skill (if real) is callable. The dummy-skill round-trip belongs to a follow-up validation session.

## Open Questions

None blocking. Items to revisit when authoring the first real skill (Quest or SO sync):
- Whether to extend the command to also generate a matching slash command (most domain skills will probably pair with a command).
- Whether the skill template should differ per `--domain` value.

## Out of Scope

- Authoring actual 기획→Unity skills (Quest authoring, SO data sync, Locale apply, Screen-spec apply).
- CI / hooks for auto-running security grep on all skills.
- Multi-machine roll-out automation beyond `claude plugin marketplace update`.

## Follow-up

After this spec is approved and the implementation plan is written and executed, the next sessions will use this scaffolder to create the first real skill — most likely Quest authoring, per planner preference.
