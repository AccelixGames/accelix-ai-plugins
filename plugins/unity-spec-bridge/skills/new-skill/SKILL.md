---
name: new-skill
description: >
  Scaffold a new skill inside the unity-spec-bridge plugin. Auto-triggers
  when the user wants to add a new spec-to-Unity skill: collecting name,
  description, domain, and input shape, then delegating to the
  `/new-skill` command which performs the file/metadata writes.
  Korean triggers: "새 스킬 만들기", "스킬 스캐폴딩", "스킬 추가",
  "유니티 스펙 브릿지 스킬 만들기", "기획 스킬 만들기"
  English triggers: "new skill", "scaffold a skill", "add a skill"
---

# unity-spec-bridge — New Skill Scaffolder

This skill guides the planner through scaffolding a new skill inside the
`unity-spec-bridge` plugin. The skill ONLY collects intent. File generation
and metadata syncing are delegated to the `/new-skill` slash command at the
end of the flow.

## Core Principles

1. **One question per turn.** The planner is busy; never batch more than
   one unresolved question.
2. **Generic identifiers only.** Skill names, descriptions, and any string
   the user provides must not contain team-internal identifiers (real
   project names, internal server names, personal names, user-specific
   paths like `C:\Users\<name>`). Reject and ask for a generic
   reformulation if they appear.
3. **Skill collects; command writes.** Do not call Write/Edit/Bash here.
   Delegate to `/new-skill` once context is gathered.
4. **Conflict check before delegation.** Use the Read tool to verify
   `plugins/unity-spec-bridge/skills/<name>/SKILL.md` does NOT exist before
   handing off. If it exists, refuse and ask for a new name.

## Flow

### Step 1 — Collect skill name

Ask: "What name? (kebab-case, generic — no project/team identifiers)"

Validate:
- Matches regex `^[a-z][a-z0-9-]+$`
- Length 3–40 characters
- Does not contain forbidden tokens (see Core Principle #2)

### Step 2 — Collect one-line description

Ask: "One-line description in English, plus Korean trigger keywords?"

Expected format the user supplies:
> `English description (한국어 트리거 키워드1, 키워드2)`

If they give Korean only, ask for the English half. If English only,
ask for Korean triggers (essential — this plugin is used by a
Korean-speaking team).

### Step 3 — Collect domain

Ask: "What domain? `quest` / `so-sync` / `locale` / `screen` / `other`"

The values map to spec-to-Unity application categories:

- `quest` — Quest/Task assets (Task chain, locale keys, etc.)
- `so-sync` — JSON spec → ScriptableObject data sync
- `locale` — locale key/text applied across 5 language sheets
- `screen` — screen-spec → prefab/scene UI layout
- `other` — falls outside the above

### Step 4 — Collect input shape

Ask: "How will this skill be invoked? Slash command with args? Natural
language only? Both?"

Capture which `argument-hint` the future command (if any) should have. If
the planner is unsure, default to `Both` and let them refine when actually
writing the skill body.

### Step 5 — Conflict check

Read `plugins/unity-spec-bridge/skills/<name>/SKILL.md`. If it exists,
abort the flow and return to Step 1.

### Step 6 — Hand off

Present a one-line summary back to the user:

> "Scaffolding `<name>` (domain: `<domain>`, input: `<shape>`).
> Description: `<description>`."

Then invoke the slash command:

```
/new-skill <name> --domain <domain>
```

The command will perform the actual file writes and metadata updates.

## What this skill does NOT do

- Write any file.
- Edit any metadata (plugin.json, CHANGELOG.md, marketplace.json).
- Run the security grep.
- Run any git command.

All of the above belong to `/new-skill`.

## References

- `references/skill-template.md` — the template that the `/new-skill`
  command instantiates.
- Marketplace root `CLAUDE.md` — version, CHANGELOG, security rules.
