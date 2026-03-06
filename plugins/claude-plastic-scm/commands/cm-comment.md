---
allowed-tools: Bash(cm wi:*), Bash(cm status:*), Bash(cm find:*), Bash(cm changeset:*), Read
description: Generate a checkin comment from pending changes without checking in — optionally apply to existing changeset (코멘트 생성/코멘트만)
argument-hint: "[cs:{changesetid}]"
---

## Context

- Workspace info: !`cm wi 2>/dev/null`
- Pending changes: !`cm status --short 2>/dev/null`
- Recent changesets (for comment style reference): !`cm find changeset "where branch = (SELECT cs.branch FROM changeset WHERE changesetid = (SELECT cs.changesetid FROM workspace))" --format="{changesetid}|{date}|{comment}" --nototal 2>/dev/null | tail -5`

## Your task

Generate a checkin comment by analyzing pending changes — without performing a checkin. Optionally apply the comment to an existing changeset.

### Step 1: Determine mode

- If `$ARGUMENTS` contains `cs:{id}`, enter **edit mode** — generate a comment and apply it to that changeset.
- Otherwise, enter **preview mode** — generate a comment and display it for the user to copy.

### Step 2: Load filter patterns

**Built-in ancillary patterns** (always excluded from comment analysis):
- Extensions: `.meta`
- Directories: `Library/`, `Logs/`, `Temp/`, `obj/`, `UserSettings/`
- Files: `*.csproj`, `*.sln`, `Packages/packages-lock.json`

**Project archive** (additional patterns):
- Check if `.claude/checkin-filters.local.md` exists in the workspace root using Read.
- If it exists, load it and merge its "Ancillary Patterns" with the built-in list.
- If it does not exist, use only the built-in patterns.

### Step 3: Classify pending changes

Classify each file from `cm status --short` into:

1. **Primary changes** — Files with extensions commonly edited directly (`.cs`, `.asset`, `.prefab`, `.unity`, `.json`, `.md`, `.txt`, `.shader`, `.cginc`, `.hlsl`, `.asmdef`, `.yaml`, `.yml`, `.xml`, `.png`, `.jpg`, `.wav`, `.mp3`, `.mat`, `.controller`, `.overrideController`, `.playable`, `.signal`, `.renderTexture`, `.lighting`, `.spriteatlas`, etc.)
2. **Ancillary changes** — Files matching ancillary patterns above.

No need to ask about unclassified files — just include them in primary for comment analysis.

### Step 4: Generate comment

Analyze only the **primary changes** and write a comment following these rules:

**Format — bullet point list:**
```
- 작업 내용 1
- 작업 내용 2
```

Each bullet describes one logical change. Group related file changes into a single bullet.

**Prefix rules** — each bullet MUST start with a category prefix:

| Prefix | Usage | Example |
|--------|-------|---------|
| (없음) | 신규 기능·콘텐츠 추가 | `- 플레이 테이블 시스템 구현` |
| `수정:` | 버그 수정 | `- 수정: 연속퇴장 버그` |
| `변경:` | 기존 동작·구조 변경 | `- 변경: CustomerSpawner → SO 기반 파이프라인` |
| `제거:` | 코드·에셋 삭제 | `- 제거: 미사용 CustomerPool 클래스` |
| `리팩토링:` | 동작 변경 없는 구조 개선 | `- 리팩토링: Actor.Customer 네임스페이스 통일` |

- Prefix가 없으면 **신규 추가**로 간주 (가장 흔한 케이스).
- 한 불렛에 prefix와 설명을 함께 쓴다. 별도 줄 분리 없음.
- 최종 언어는 **한국어** 기본. 코드 식별자(클래스명, 메서드명)는 원문 유지.
- If `$ARGUMENTS` contains additional text (beyond cs: spec), treat it as user context and incorporate it.
- If recent changesets have comments, reference their tone but always follow the bullet format above.

### Step 5: Present and apply

**Preview mode** (no cs: argument):
- Show the generated comment.
- Ask: "이 코멘트를 현재 체인지셋에 적용할까요? (적용 / 복사만)"
- If the user wants to apply, run:
  ```
  cm changeset editcomment cs:{current_cs} "{comment}"
  ```
  where `{current_cs}` is the workspace's current changeset ID.

**Edit mode** (cs:{id} argument):
- Show the generated comment.
- Ask: "이 코멘트를 cs:{id}에 적용할까요?"
- If confirmed, run:
  ```
  cm changeset editcomment cs:{id} "{comment}"
  ```

After applying, verify:
```
cm find changeset "where changesetid={id}" --format="{changesetid}|{date}|{comment}" --nototal
```

Do not use any other tools. Do not send any other text or messages besides these tool calls.
