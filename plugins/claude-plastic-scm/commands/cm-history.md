---
allowed-tools:
  - Bash(cm history:*)
  - Bash(cm find:*)
  - Bash(cm log:*)
  - Bash(cm wi:*)
description: Show PlasticSCM change history for a file or directory. Use for "파일 이력", "change history", "누가 언제 수정".
argument-hint: "<file-or-directory-path>"
---

## Context

- Workspace info: !`cm wi 2>/dev/null || echo "NOT_A_WORKSPACE"`

## Task

Display change history for the path in `$ARGUMENTS`. If empty, ask the user for a path.

### Step 0 — Workspace guard

If context contains `NOT_A_WORKSPACE` or is empty, stop:
- PlasticSCM workspace가 아님. git repo면 `git log` 사용.

### Query

`cm history "$ARGUMENTS" --format="{changesetid}|{date}|{owner}|{branch}|{comment}" --nototal`

### Present

Last 20 entries as a table: `CS# | Date | Author | Branch | Comment`.
If path doesn't exist or has no history, say so.

⚠️ 공용 계정 환경(예: `accelix.staff@gmail.com`)에서는 owner 필드만으로 작성자를 단정하지
않는다. 브랜치 `att:owner` 속성 → 코멘트 첫 줄 `owner:` 라벨 순으로 확인하고, 계정 fallback일
땐 그렇게 명시.

Use only the tools listed above.
