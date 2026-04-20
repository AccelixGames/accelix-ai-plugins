---
name: reflection-prompt
description: Post-task Reflection assets. 5-signal friction heuristic and Korean user-question template used by the claude-plastic-scm skill after PostToolUse hook fires on a successful destructive cm command. Pure data consumed by SKILL.md ## Post-task Reflection.
---

# Post-task Reflection Prompt Assets

## 5 friction signals (self-evaluation)

Claude evaluates the just-ended session against these signals. If **≥ 1** signal is present, friction occurred → proceed to user question. If **all absent**, skip silently (no question asked).

| # | Signal | Examples |
|---|--------|----------|
| 1 | **재시도 (retry)** | 같은 cm 커맨드를 다른 옵션으로 반복, 실패 후 재실행 |
| 2 | **우회·워크어라운드 (workaround)** | 예상 경로가 실패해서 다른 방법으로 우회 (`cm co`로 우회 등) |
| 3 | **추정·가정 (estimation)** | 문서에 없는 동작을 "아마 이럴 것이다"로 진행 → 나중에 검증 필요 |
| 4 | **에러 메시지 처리 (error handling)** | cm/gh/shell 에러 출력 해석 필요했음 |
| 5 | **문서 재조회 (doc re-query)** | skill 문서·CHANGELOG·references를 2회 이상 열거나 grep 반복 |

Notes:
- "session"의 범위 = 이번 destructive cm 커맨드로 이어진 **최근 작업 단위** (최근 ~5-10 tool uses 정도). 세션 전체 아님.
- "smooth" = 5 signals 전부 0회. 이 경우 무조건 skip (유저에게 묻지 않음).
- "borderline" 판단은 보수적으로 — 확신 없으면 물어본다. 유저가 "skip"이라고 말하면 기록 남기고 끝.

## User question template (Korean)

If friction detected, emit this format verbatim (fill `<...>` placeholders):

~~~
이번 `<cm subcommand>` 작업 중 friction 관찰:
- 감지된 signal: <번호:이름> <번호:이름> …
- 증상 요약: <1줄>
- 개선안 아이디어: <1줄>

gotcha issue로 capture할까? (Y/N, skip시 보류)
~~~

예시:

~~~
이번 `cm merge` 작업 중 friction 관찰:
- 감지된 signal: 2:우회 5:문서재조회
- 증상 요약: merge_investigate.sh이 `cm diff` GUI trap 회피 때문에 텍스트 모드 재조회 2회 발생.
- 개선안 아이디어: merge_investigate.sh에 `--text-mode` 강제 옵션 추가 검토.

gotcha issue로 capture할까? (Y/N, skip시 보류)
~~~

## User response handling

- **Y**: draft issue body using `gotcha-template.md` structure, create with `MSYS_NO_PATHCONV=1 gh issue create --repo <marketplace> --label "skill:plastic-scm,gotcha-open" --body-file <tmp> --title "[cm <subcmd>] <summary>"`. Confirm issue URL to user.
- **N**: no action. Acknowledge briefly ("기록 skip").
- **무응답·기타**: treat as skip (no issue).

## Scope

This template does NOT handle:
- Hold counter logic (that's `/cm-lint` Phase B — hold is a triage decision, not a capture decision)
- Non-cm friction (editor bugs, build failures) — out of claude-plastic-scm scope
- Sessions without a destructive cm command — hook never fires, this protocol never runs
