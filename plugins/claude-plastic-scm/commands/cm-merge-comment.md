---
allowed-tools:
  - Bash(cm merge:*)
  - Bash(cm find:*)
  - Bash(cm changeset:*)
  - Bash(cm wi:*)
  - Bash(.agents/skills/_plastic-resource/scripts/plastic:*)
  - Bash(.agents\skills\_plastic-resource\scripts\plastic.cmd:*)
  - Read
description: Server-side merge current PlasticSCM branch into target branch + consolidate sub-branch comments into the resulting merge changeset. Use for "서버 사이드 병합", "merge with comment consolidation", "sub-branch 코멘트 정리".
argument-hint: "<target-branch-path>"
disable-model-invocation: true
---

## Context

- Workspace info: !`cm wi 2>/dev/null || echo "NOT_A_WORKSPACE"`

## Task

Server-side merge (no workspace switch), then collect + consolidate all sub-branch comments into the merge changeset.

### Step 0 — Workspace guard

If context contains `NOT_A_WORKSPACE` or is empty, stop:
- PlasticSCM workspace가 아님. git repo면 `git merge`/PR 사용.

### Step 0.5 — Wrapper routing (ProjectMaid 등)

Check for `.agents/skills/_plastic-resource/scripts/plastic` (Windows: `plastic.cmd`) at the workspace root.

**If it exists**, use the wrapper flow instead of this command's Steps 1–7 — 코멘트 증거 수집
(`comment_context_file`)과 충돌 정책까지 래퍼가 소유한다:

1. Read `.agents/skills/plastic-push/SKILL.md` (main으로) 또는 `plastic-merge/SKILL.md` (임의 대상).
2. current→main이면 `plastic push`, 임의 source→target이면 `plastic merge -Source … -Target …`.
   인라인 `-Title/-Summary`는 거부된다 — 먼저 bare로 실행해 `comment_context_file`을 읽고,
   LLM이 쓴 코멘트를 `-CommentFile`(워크스페이스 밖 temp)로 재실행.
3. 충돌 시: push는 항상 pull-first, merge는 `-WritePolicy` → `-Run -PolicyFile` 2단.
4. 완료 판정은 `push_done=true` / `merge_done=true` 토큰만.

코멘트 본문은 아래 Step 6의 필수 4필드(owner 라벨 등)를 동일하게 지킨다.
Then stop — Steps 1–7 below are the fallback for workspaces **without** the wrapper.

### Args

- `$ARGUMENTS` = target branch path (e.g. `/main/release`).
- If empty, ask: "어떤 브랜치로 병합할까? (예: /main/release)"

Source branch = current workspace branch.

### Step 1 — Confirm direction

Show merge direction and ask confirmation:
- **소스 (현재):** `{source}`
- **대상:** `{target}`
- "위 방향으로 서버 사이드 병합 진행?"

### Step 2 — Execute merge

```
cm merge br:{source} --to=br:{target} --merge
```

- Success → Step 3.
- Conflicts → show error, stop. 래퍼 워크스페이스면 `plastic pull`/`plastic merge`의
  `-WritePolicy` → `-Run -PolicyFile` 2단 플로우로 해결 (GUI 열지 않는다). 래퍼 없으면
  충돌 목록을 보여주고 유저와 해결 방향 합의 후 `cm merge ... --keepsource|--keepdestination`.
- Nothing to merge → inform, stop.

### Step 3 — Latest changesets on target

```
cm find changeset "where branch='{target}'" --format="{changesetid}|{date}|{comment}" --nototal
```

Take last 2 rows: `latest` (last) and `prev` (2nd-to-last).
If only 1 changeset exists, merge created the first one — skip comment collection, use latest only.

### Step 4 — Find merges into target

```
cm find merge "where dstbranch='{target}'" --format="{dstchangeset}|{srcchangeset}|{srcbranch}" --nototal
```

Filter rows where `dstchangeset == latest` — these are new merges since `prev`.

### Step 5 — Collect sub-branch comments

For each merge source, find previous merge from same source to determine changeset range:
```
cm find changeset "where branch='{srcbranch}' and changesetid > {prevSrcCS} and changesetid <= {srcCS}" --format="{changesetid}|{comment}" --nototal
```

**Recursively check sub-branches** (max 3 levels deep):
```
cm find merge "where dstbranch='{srcbranch}' and dstchangeset > {prevSrcCS} and dstchangeset <= {srcCS}" --format="{srcchangeset}|{srcbranch}|{srccomment}" --nototal
```

For each deeper source, collect its changeset comments.

### Step 6 — Format

**필수 필드 (2026-05-19~ 룰, ProjectMaid Discord 공지)**:

1. **owner 라벨** — 첫 줄에 `owner: <작성자 이름>`. `cm whoami`가 공용/자동 계정(예: `accelix.staff@gmail.com`)일 수 있어서 cs의 owner 필드만으로는 실제 작성자 추적이 안 됨. 코멘트 본문 첫 줄에 실제 작성자 명시 필수. 사용자에게 이름 물어보거나 사용자 메모리/AGENTS에서 확인.
2. **브랜치 합류 문장** — 두 번째 단락에 `<source> sandbox의 ... 작업을 <target>로 합칩니다.` 식 자연어 한 줄.
3. **작업 요약** — sub-branch 코멘트 묶음 (아래 형식) 또는 자연어 풀어쓰기.
4. **충돌 처리** — 마지막 줄에 `머지 충돌은 없었습니다.` 또는 `충돌 N건 — <누구 데이터 남겼는지>`. 충돌 해결한 경우 의도 추적 위해 반드시 명시.

**본문 구조**:

- Group by sub-branch (use last path segment as header).
- Format: `[BranchShortName]` header + `- comment` list.
- Skip empty, dedupe.
- 큰 작업은 `[주요 변경]` / `[신규 추가]` / `[삭제]` / `[충돌 해결]` 섹션 분리.
- 작은 작업은 자연어 한두 문단으로 풀어쓰는 게 더 자연스러움 (디코 사전 확인 톤 — 자연어 풀어쓰기 + 짧은 문장).

**예시 1 (sub-branch 묶음 형식)**:

```
owner: 김규혁

feature-login -> /main/beta 병합

[feature-login]
- Added OAuth2 login flow
- Fixed token refresh logic

[hotfix-ui]
- Resolved layout overflow on mobile
- Updated button styles

머지 충돌은 없었습니다.
```

**예시 2 (자연어 풀어쓰기 형식, 작은 작업)**:

```
owner: 김규혁

gd010 sandbox의 task-480 후속수정 작업을 main/beta로 합칩니다.

강아지 NPC 가이드용 wish 5건과 새 풀 자산을 박았고, 미녕 위시리스트 wish는 30초 자동 충족 패턴 폐기하고 "소망 이뤄줬어" 보고 버튼으로 충족하는 신구조로 갈아탔습니다. 충족 추적용 게임 이벤트 4종도 신설했고, 강아지가 소파나 영업종료간판 클릭으로 충족시키는 wish용으로 그 가구 자산 2건도 박혔어요. 로케일 5언어 동기화도 마쳤습니다.

머지 충돌은 없었습니다.
```

Show the combined comment, confirm with user.

### Step 7 — Apply

```
cm changeset editcomment cs:{latest} "{combined}"
```

Verify:
```
cm find changeset "where changesetid={latest}" --format="{changesetid}|{date}|{comment}" --nototal
```

If all collected comments are empty, apply default: "Merged {source} into {target}".

Use only the tools listed above.
