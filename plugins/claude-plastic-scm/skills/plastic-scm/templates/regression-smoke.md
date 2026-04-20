---
name: regression-smoke
description: Pre-defined smoke-test scenarios for /cm-lint regression verification. Lint Phase C picks 2 scenarios most relevant to the issue being fixed and dispatches them as subagents before/after the fix to confirm no behavioral regression. This file is pure data — add new scenarios as the plugin matures.
---

# Regression Smoke Test Set

Each scenario below is a **single, self-contained cm workflow** that a general-purpose subagent can execute without project-specific knowledge. Scenarios must stay **generic** — no hardcoded branch names, changeset IDs, file paths, or repo assumptions. The user's lint design principle: "script 일반적이어야 함, 프로젝트 특화 X, 특정 케이스 특화 X".

## SM-01: Simple file checkin

**Setup:** A workspace has one modified tracked text file with no conflicts.

**Steps:**
1. `cm status` — confirm the file appears under "변경됨/Changed".
2. `cm checkin <path> -c="smoke test"` — execute.
3. `cm log -l1` — verify the new changeset includes the file.

**Expected observation:** checkin succeeds, new changeset contains exactly the one file, comment matches.

## SM-02: Folder-scope checkin with mixed CH/PR

**Setup:** A workspace folder contains (a) a modified tracked file in "변경됨" state, (b) a new untracked "비공개" file.

**Steps:**
1. `cm status --short` — confirm both states present.
2. `cm add <untracked>` — register private file.
3. `cm checkin <folder> -c="smoke test mixed"` — folder-level checkin.
4. `cm log -l1` — verify both files in the resulting changeset.

**Expected observation:** both files checkin atomically under one changeset.

## SM-03: Label on current changeset with comment

**Setup:** Workspace is on a stable changeset with no pending changes.

**Steps:**
1. `cm wi` — read current changeset id.
2. `cm label create lb:smoke-test-<timestamp> cs:<id> -c="smoke test label"` — single-dash `-c=`.
3. `cm find label "where name='smoke-test-<timestamp>'" --format="{name}|{comment}" --nototal` — verify.

**Expected observation:** label created with attached comment. `--comment=` double-dash MUST fail with "예상치 못한 옵션 --comment" if tested as negative case.

## SM-04: Merge investigation brief

**Setup:** Two branches diverge with at least one changeset on the source.

**Steps:**
1. `bash <plugin>/skills/plastic-scm/scripts/merge_investigate.sh <src-branch> --workspace <path>` — run bundled investigation script.
2. Verify output sections: `=== Workspace ===`, `=== Prior Merges ===`, `=== Source Branch Info ===`, `=== Source Branch Changesets ===`, `=== Source Tip Comment ===`, `=== Source Changes ===`, `=== Effective Merge Delta ===`, `=== Destination Status ===`.

**Expected observation:** all 8 labeled sections present, no section empty unless genuinely so (e.g., no prior merges).

## How lint picks 2 of 4

Lint Phase C selects the 2 scenarios whose command surface most overlaps with the issue being fixed:

| Issue touches | Prefer scenarios |
|---------------|------------------|
| `cm checkin` | SM-01, SM-02 |
| `cm label` | SM-03, SM-01 |
| `cm merge` | SM-04, and the scenario matching any other `cm` call the fix affects |
| `cm status` parsing | SM-02, SM-01 |
| documentation only | SM-01 + one unrelated (e.g., SM-03) as sanity |

When no clear overlap, default to SM-01 + SM-04.
