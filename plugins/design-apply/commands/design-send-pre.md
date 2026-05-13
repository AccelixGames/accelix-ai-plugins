---
allowed-tools: Read, Write, Bash(bash *send.sh*)
description: |
  디자인허브 적용 [4]단계 사전 확인 메시지를 플머에게 송신한다 (요약 본문 + 상세 md 첨부).
  PROCESS 룰 (references/PROCESS.md) Section 5.1 사전 확인 템플릿 기반. 적용 가능 항목과 문의 항목을 구분해 전달.

  Korean triggers:
  "사전 확인 보내", "사전 확인 송신", "{spec-id} 사전 확인", "{spec-id} 플머에게 보내",
  "플머 사전 확인 요청", "디자인허브 사전 확인", "spec 사전 확인", "[4]단계 송신",
  "사전 확인해줘", "{spec-id} 디스코드 보내", "지금 사전 확인 보내"

  English triggers:
  "send pre-check {spec-id}", "design pre-send", "presend {spec-id}",
  "send {spec-id} for review", "discord pre-check"
argument-hint: <spec-id>
---

# Design Apply — 사전 확인 송신

PROCESS 룰 Section 5.1 기반. spec 상세 파일에서 "적용 가능 항목" + "문의 항목" 두 섹션을 추출해 요약 본문으로 만들고, 상세 md 전체를 첨부해 디스코드로 보냄.

## 인자

- `${ARGS}`: spec-id (예: `wish-pool-jegal`)

## Steps

### Step 1: spec 상세 파일 로드

Read `c:/WorkSpace/AccelixGames/design-apply-local/specs/${ARGS}.md`.

파일 없으면 stop:
> "specs/${ARGS}.md 없음. spec 상세 파일 먼저 작성 필요. references/PROCESS.md Section 5.1 사전 확인 템플릿(`적용 가능 항목 (있음)` / `문의 항목 (없음 / 정책 불명)` 두 섹션 포함) 따라 작성하세요."

### Step 2: 필수 섹션 확인

spec 상세 파일에 다음 두 헤딩 모두 있는지 확인:

- `적용 가능 항목 (있음)`
- `문의 항목 (없음 / 정책 불명)`

없으면 stop + 보강 안내.

### Step 2.5: ProjectMaid 측 사전 점검 (필수)

spec 상세의 "막힌 부분" 각 항목이 ProjectMaid 측에 이미 답이 있는지 점검 (references/projectmaid-docs.md 참고):

- `Assets/Accelix/Docs/` 4 문서 매칭
  - Conditional 관련 → `ConditionalGuide.md`
  - 가구 약어 → `FurnitureKeyAssetMapping.md`
  - HelpPopup → `HelpPopupConditionSetupGuide.md`
- 메이드 관련 값 → 메이드 프로필 SO (`Assets/Accelix/Data/Game.Profile/Actor.Maid/`)
- 카페 수치 → `Assets/Accelix/Data/Cafe/`
- 기존 wish/유사 asset/SO grep

답 발견된 항목:

- spec 상세 파일의 "막힌 부분"에서 제외
- "제가 진행할 부분"으로 이동 (자기 권한으로 적용)
- 또는 별도 노트 (예: "ConditionalGuide.md 따라 처리")

이 점검을 거치지 않으면 플머가 이미 답한 정보를 다시 묻는 실수 발생.

### Step 3: 요약 본문 작성

**톤 룰** (references/presend-tone.md 따름):

- 자연어, spec/코드 약어 풀어쓰기
- 3단 구조: **작업하려는 것 / 제가 진행할 부분(보고) / 막힌 부분(문의)**
- "진행할 부분"은 기획자 자기 권한 — 플머에게 OK 묻지 않음, 단순 보고
- 막힌 부분에만 부탁/협업 어조 + 예시 1개씩 + 구체 질문
- **Claude 자체 의견/판단/추정 금지** — "저는 ~ 쪽이 좋아 보입니다" 류는 사용자가 명시적으로 제공한 경우에만

본문 형식:

```
<@390391994314391552> <@389989278865817601> <@1449459616093311220>
**[${ARGS}] 사전 확인 요청 — {spec 한국어 이름}**

**작업하려는 것**
{자연어 1~2문장. 무엇을 박으려고 하는지}

**제가 진행할 부분** (보고)
- {평어 풀어쓰기 한 줄 — 자기 권한, OK 묻지 않음}
- ...

**막힌 부분** (이건 답이 있어야 진행 가능)
1. **{자연어 제목}** — {배경 자연어 1~2문장. 예시 1개 포함.}
   질문: {구체 질문 — "X로 합니까, Y로 합니까?" 식}
   {(사용자가 명시적으로 제공한 경우에만) 기획자 의견 1줄. Claude 임의 추가 금지.}
2. ...

상세는 첨부 md 참조.
spec: data/specs/${ARGS}.json
```

**자가 점검 체크리스트** (본문 작성 후, 사용자에게 보여주기 전):

- [ ] spec 내부 약어를 풀어 썼는가?
- [ ] 막힌 부분 각 항목에 예시 1개씩 있는가?
- [ ] 시스템 보고서 톤이 남아있지 않은가?
- [ ] 한국어 자연어가 본문의 7할 이상인가?
- [ ] "진행해도 될까요?" 류 부탁/허락 어조가 "진행할 부분"에 들어가 있지 않은가?
- [ ] Claude 자체 의견/판단을 임의로 본문에 넣지 않았는가? (사용자 명시한 경우만)
- [ ] ProjectMaid 측 가이드/SO 사전 점검 (Step 2.5) 완료했는가?

### Step 4: 상세 md 첨부 파일 작성

`c:/WorkSpace/AccelixGames/design-apply-local/discord-attachments/${ARGS}-pre.md` 에 Write:

- spec 상세 파일 본문 전체
- 추가 메타: ProjectMaid 측 코드 위치, 진단 결과 요약, 우려 카테고리 매핑

### Step 5: 사용자 확인 게이트

작성된 본문 + 첨부 위치를 사용자에게 보여주고 명시적으로 묻기:

> "이 본문 + 첨부로 디자인허브 채널(`1359366037841117356`)에 송신할까?"

**사용자 OK 없으면 송신 안 함.** 외부 영향 액션, 게이트 필수.

### Step 6: 송신

payload JSON 작성 (Write 도구) — `/tmp/discord-payload-pre.json` 또는 `C:/Users/chris/AppData/Local/Temp/discord-payload-pre.json`:

```json
{"content": "<Step 3 요약 본문, \\n으로 줄바꿈 escape>", "username": "Claude Bot"}
```

본문 안의 `"`는 `\"`, 줄바꿈은 `\n` (JSON 표준 escape).

webhook URL 로드 + send.sh 호출:

```bash
WEBHOOK_URL=$(node -e "console.log(JSON.parse(require('fs').readFileSync('c:/WorkSpace/AccelixGames/ProjectMaid/.discord-webhook/config.json','utf8')).webhooks.default.url)")

bash "C:/Users/chris/.claude/plugins/marketplaces/accelix-ai-plugins/plugins/discord-webhook/scripts/send.sh" \
  "$WEBHOOK_URL" \
  "C:/Users/chris/AppData/Local/Temp/discord-payload-pre.json" \
  --file "c:/WorkSpace/AccelixGames/design-apply-local/discord-attachments/${ARGS}-pre.md"
```

### Step 7: 결과 보고

- HTTP status (200/204면 성공, 그 외 stderr 본문 함께 보고)
- 사용자에게 채널 도착 확인 부탁
- `c:/WorkSpace/AccelixGames/design-apply-local/backlog.md` 단계 `awaiting`으로 갱신 (사용자 확인 후 또는 자동)

## 주의

- 본문/콘솔에 시크릿 (webhook URL, bot token) 절대 출력 X. `WEBHOOK_URL` 변수에만 들고 송신 시 사용.
- 한국어 UTF-8 인코딩 유지 (JSON content escape 신경).
- 첨부 md 파일은 5MB 이하 (Discord 제한). spec 상세 크면 핵심만 첨부.
- 멘션 ID는 references/PROCESS.md Section 7.1 매핑 따름 (김기민 `390391994314391552` / 박성범 `389989278865817601` / 조영우 `1449459616093311220`).
