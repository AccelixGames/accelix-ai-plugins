---
name: where-am-i
description: >
  Session self-check — report how the current work started, where it
  branched off from, how far it has progressed, and what was just being
  done, in a friendly conversational tone. Auto-corrects "primitive
  jumps" in long auto-mode sessions where the model loses sight of
  origin/intent. NOT for project orientation (that is what AGENTS.md and
  workspace docs are for) — purely a within-session self-check device.
  Korean triggers: "어디까지 했지", "지금 뭐 하는 중", "정신차려",
  "현재 작업 정리", "where am i", "/where-am-i", "원래 뭐 하던 거였지"
  English triggers: "where am i", "what was i doing", "context check",
  "self check"
---

# where-am-i — session self-check

Adapted from the mcs-design-workspace original; generalized so it works
for any project once installed via the marketplace.

## When to invoke

Activate immediately on any of:

- Slash: `/where-am-i`
- Natural language: "어디까지 했지", "지금 뭐 하는 중", "정신차려",
  "현재 작업 정리", "where am i", "원래 뭐 하던 거였지"
- Self-judgment: context grew long AND a multi-step instruction
  ("등록·수행·완료" style) is about to fire — invoking proactively is
  recommended

## Output format (4 fixed sections)

Labels are friendly conversational questions. Do NOT use internal jargon
("Origin / 파생 / merge-base") — write them out in plain language.

```
🌱 지금 이거 어쩌다 하고 있냐면     — how the work started (user's first ask + intent)
📌 어디서 갈라져 나왔냐면           — which flow / skill / rule / task it branched off from
📊 지금 어디까지 왔냐면             — progress + the latest concrete artifact
🔨 방금 뭘 하던 중이냐면            — the actual action of the previous turn
```

**Tone**: natural endings — "…하고 있어 / …받은 상태야 / …한 번 돌렸음 /
…걸리는 점이 있어". Embed facts (PR numbers, task IDs, SHAs, file paths)
verbatim — do NOT wrap them in system-jargon labels.

Default length is **2–3 lines per section**. When a risk signal fires
(see checklist below), auto-expand to 3–5 lines per section plus a
single `⚠️ 걸리는 점:` line that names the uncertainty or risk.

## Data sources — tiered

### Always query (cheap, every invocation)

1. **Conversation context** — user's first utterance, last N turns
2. **TodoWrite current state** — primary source for progress estimation
3. **Current branch** — `git branch --show-current` (or the project's
   VCS equivalent — for example `cm wi` in a PlasticSCM workspace)
4. **cwd** — worktree location (to confirm we are still in the original
   work lane)

### Query only when a risk signal fires (expensive)

5. **Branch work history** — `git log <base>..HEAD --oneline`
6. **Task entry** — parse a task ID out of the branch name when the
   project uses one, then look it up in the project's task tracker
   (whatever file or system the project uses)
7. **PR body** — `gh pr view` if there is one and the project hosts on
   GitHub
8. **Merge base** — `git merge-base <base> HEAD` (to trace parent flow)

If the project uses something other than git / GitHub for VCS or task
tracking, substitute the equivalents from the project's AGENTS.md /
CLAUDE.md.

## Risk-signal checklist (auto-expand triggers)

If ANY of these match, switch on the expensive queries and add a
`⚠️ 걸리는 점:` line.

| Signal | Detection rule |
|---|---|
| **Context discontinuity** | Session began right after a handover (visible handover-skill output, or user's first turn is "이어서 해줘" / "인계 받았어" style) → origin is not in the in-context conversation |
| **Multi-step instruction** | The most recent user turn has 3+ verbs (e.g., "등록·수행·완료" or "정리·박아·머지") → primitive-sequence jump risk |
| **Low origin confidence** | The work-initiating turn is 5+ messages ago, OR the first turn is vague ("그거 해줘" style) so the inferred origin is shaky |
| **Explicit request** | User invoked with "꼼꼼히", "디테일", or "확장 모드" |
| **Lane mismatch** | Branch name of current worktree does not line up with the topic being worked on (e.g., a `feature/x` worktree but the session is editing skill files) |

## Examples

### Default mode (no risk signal)

```
🌱 지금 이거 어쩌다 하고 있냐면
   유저가 새 데이터 entry 4건 추가해달라고 했어 (turn 1).

📌 어디서 갈라져 나왔냐면
   데이터 변경이라 프로젝트의 표준 데이터 편집 워크플로 타고 들어옴.

📊 지금 어디까지 왔냐면
   5/8 단계. 스키마 검증은 통과, 다음 단계 직전.

🔨 방금 뭘 하던 중이냐면
   대상 파일에 entry append하고 검증 명령 결과 기다리는 중.
```

### Expanded mode (`⚠️ 걸리는 점` detected)

```
🌱 지금 이거 어쩌다 하고 있냐면
   유저가 "스킬 만들게"로 시작 (turn 1).
   목적은 다단계 지시 받으면 primitive로 점프하는 패턴
   자기교정용 장치 만들기.

📌 어디서 갈라져 나왔냐면
   세션 시작 시 brainstorming으로 자동 진입했어.
   ⚠️ task entry는 없음 — hygiene 우회 경로로 가는 중
   (chore/cleanup-<date> 브랜치).

📊 지금 어디까지 왔냐면
   brainstorm 7/8 단계. 지금 SKILL.md 작성하는 중.
   할 일 목록은 별도로 안 만들었어 — 파일 한 개라 안 필요.

🔨 방금 뭘 하던 중이냐면
   해당 워크트리 안에서 SKILL.md 본문을 쓰고 있음.
```

## Forbidden

- **No immediate jumping to external tools** — Don't run expensive tools
  like `git log -S` just because origin is unclear. Walk through the
  cheap sources first (conversation context, TodoWrite, branch SHA), and
  only escalate to expensive queries when a risk signal actually fires.
- **No fabricating** — Sections you do not know stay marked
  `⚠️ 잘 모르겠음 — 핸드오버 이전 컨텍스트라` (or the equivalent in
  natural language). Do not fill blanks with plausible-sounding guesses.
- **No multi-step jumps** — `where-am-i` is **report-only**. After
  reporting, stop. Do not auto-continue the previous work just because
  you have now identified the origin. Wait for the user's next
  instruction.
- **No follow-up questions** — Report and stop. If the user asks a
  follow-up, answer then.
- **No internal-jargon labels** — Don't dress the section labels with
  system terms like "Origin / 파생 / merge-base / lane mismatch". The
  labels stay in plain conversational form ("어쩌다…", "어디서…").
  Inside the body, embedding raw facts (PR numbers, SHAs, file paths) is
  fine — wrapping them in system labels is not.

## Procedure

1. Evaluate the 5 risk signals → decide whether to enable expensive
   queries.
2. Collect data sources (the 4 cheap ones always; the 4 expensive ones
   only when needed).
3. Produce the 4-section text in friendly conversational endings
   ("…하고 있어", "…한 상태야"). Anything you don't know stays marked
   as `⚠️ 잘 모르겠음 …` in natural language.
4. Output and stop. No follow-up actions.

## What this skill does NOT do

- Project orientation. Use the project's AGENTS.md / CLAUDE.md / docs
  for "what is this project?". `where-am-i` only diagnoses the current
  session.
- Bug post-mortem. After-the-fact retros belong to a separate workflow.
- Anything beyond reporting. It never edits, commits, or scaffolds.

## References

- Pairs with the `handover` plugin's `/handover` command — `handover`
  writes the session into a file for the next session; `where-am-i`
  reads the current session for the user.
