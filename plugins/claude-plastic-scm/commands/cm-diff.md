---
allowed-tools:
  - Bash(cm diff:*)
  - Bash(cm cat:*)
  - Bash(diff:*)
  - Bash(git diff:*)
  - Bash(ls:*)
  - Bash(.agents/skills/_plastic-resource/scripts/plastic:*)
  - Bash(.agents\skills\_plastic-resource\scripts\plastic.cmd:*)
  - Read
description: Compare PlasticSCM changesets/branches/labels or a workspace file vs head — text-only, never GUI. Use for "cm diff", "변경 비교", "파일 diff".
argument-hint: "<spec1> <spec2>  |  <workspace-file>"
---

## Task

Compare PlasticSCM objects or pending changes — **text-only, never GUI**.

### Step 0 — Wrapper routing (ProjectMaid 등)

Check for a project wrapper: `.agents/skills/_plastic-resource/scripts/plastic` (Windows: `plastic.cmd`) at the workspace root.

**If it exists, do NOT run raw `cm diff` in any form** — GUI/SemanticMerge can launch and block the CLI. Route instead:

| Goal | Wrapper command |
|------|-----------------|
| Pending changes diff | `plastic pending-diff [-Paths <p>] [-Changelist <name>]` → read `summary.diffstat.txt` first, then selective `combined.diff` hunks |
| One changeset's content | `plastic changeset-list -Changeset N [-SummaryByArea]`, then `plastic changeset-diff -Changeset N [-Paths <p>]` |

Then stop — the modes below are for workspaces **without** the wrapper.

### ⚠ Critical — avoid GUI

`cm diff <path>` or `cm diff <cs:N> <path>` triggers the Plastic GUI viewer and blocks the CLI.
Use **only** the patterns below.

### Mode 1 — two specs (changesets / branches / labels)

If `$ARGUMENTS` = two specs like `cs:100 cs:200`, `br:/main/dev br:/main`, `lb:v1 lb:v2`:

```
cm diff <spec1> <spec2> --format="{path}|{status}"
```

(`--nototal` is NOT supported on `cm diff` — pipe the total line away if it bothers.)

Categorize by status: **Added**, **Changed**, **Deleted**, **Moved**. List per category + counts.

### Mode 2 — workspace file vs head

If `$ARGUMENTS` = one workspace path (contains `/` or `\`, no `cs:`/`br:`/`lb:` prefix):

```
cm cat "rev:<path>#cs:head" > /tmp/cm-old.tmp
diff -u /tmp/cm-old.tmp "<path>" | head -200
```

For large files (prefab/scene/yaml), pipe to `head` or filter. If `rev:` fails, try:

```
cm cat "serverpath:/full/repo/path/to/file#cs:head" > /tmp/cm-old.tmp
```

### Mode 3 — two changesets, file-scoped

If `$ARGUMENTS` = `cs:100 cs:200 <path>`:

```
cm cat "rev:<path>#cs:100" > /tmp/cm-a.tmp
cm cat "rev:<path>#cs:200" > /tmp/cm-b.tmp
diff -u /tmp/cm-a.tmp /tmp/cm-b.tmp
```

### Invalid args

Ask for one of: `<spec1> <spec2>`, `<workspace-path>`, `<cs:A> <cs:B> <path>`.

### Constraints

- Wrapper workspace → wrapper only (Step 0). **NEVER** raw `cm diff` there, even spec-pair form.
- Elsewhere: **NEVER** invoke `cm diff` without explicit `cs:A cs:B` / `br:A br:B` / `lb:A lb:B` — a path argument opens the GUI.
- Clean up `/tmp/cm-*.tmp` after use.
- Use only the tools listed above.
