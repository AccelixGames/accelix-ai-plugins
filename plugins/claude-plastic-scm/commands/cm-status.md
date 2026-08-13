---
allowed-tools:
  - Bash(cm status:*)
  - Bash(cm wi:*)
description: Show PlasticSCM workspace pending changes grouped by Added/Changed/Deleted/Moved/Private. Use for "cm status", "워크스페이스 상태", "pending changes".
---

## Context

- Workspace info: !`cm wi 2>/dev/null || echo "NOT_A_WORKSPACE"`
- Full status: !`cm status 2>/dev/null || echo "NOT_A_WORKSPACE"`

## Task

Present the workspace status cleanly.

### Step 0 — Workspace guard

If context above contains `NOT_A_WORKSPACE` or is empty, stop immediately:
- 이 디렉토리는 PlasticSCM workspace가 아님. git repo일 가능성 — `/commit` 계열 사용 권장.

### Step 1 — Branch context

Show current branch + changeset from workspace info.

### Step 2 — Categorize

Group `cm status` output into: **Added**, **Changed**, **Deleted**, **Moved**, **Private** (untracked).

### Step 3 — Summary

Counts per category + total. If no pending changes, state workspace is clean.

### Note — Wrapper workspace (ProjectMaid 등)

`.agents/skills/_plastic-resource/scripts/plastic`가 있는 워크스페이스면 changelist 단위
그룹 뷰는 `plastic status` / `plastic pending-list`가 더 정확하다 (Unity `.meta` 소유
오표시 함정 회피). 후속 SCM 작업(체크인·diff·머지)도 그 래퍼로 라우팅.

Use only the tools listed above.
