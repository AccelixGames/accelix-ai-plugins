# Design Hub 적용 프로세스 (v2)

**작성일**: 2026-05-13 (v2 — wish-system dry-run 후 재정의, plugin 패키지로 이전)
**대상**: ProjectMaid (Unity) ← mcs-design-workspace (디자인허브)
**주체**: 기획자(편집) 주도, Claude 보조, 플머(김기민/박성범/조영우) 사전/사후 확인

---

## 1. 목적

mcs-design-workspace의 **컨텐츠/수치 spec**(JSON) + ADR을 ProjectMaid Unity 프로젝트에 적용하는 표준 워크플로우. 인프라(로직/구조)는 이미 거의 구현되어 있고, 기획자는 그 위에 **수치·데이터·컨텐츠**를 박는 게 main use case.

**비목표**: 인프라(로직/시스템) 코드 변경. 자동화 시스템 구축. 5분기 같은 추상 모델.

---

## 2. spec 종류 분류

| 분류 | 대상 | 이 프로세스가 다룸? |
|------|------|--------------------|
| **컨텐츠/수치 spec** | wish-pool-*, recipe-book, item-catalog, locale, 가격, quest 데이터, 메이드 스탯, daily-report 수치 등 | **✅ 메인 대상** |
| 인프라(로직/구조) spec | wish-system 본체, customer spawner 알고리즘, asmdef, 도메인 분리 등 | ❌ 이 프로세스 밖 (플머 영역, 이미 거의 구현됨) |

---

## 3. 전체 흐름 (7단계 + 확인 게이트 2회)

```
[0] 관련 문서 읽기
   ↓
[1] 넣을 스펙 선정
   ↓
[2] 유니티 공간 파악
   ↓
[3] 우려 지점 파악 ────→ (우려 0건 + 이미 정합) → 감사 모드 종료 → [7] 마무리
   ↓
[4] 플머 사전 확인 ── OK ──→ [5] 적용
   │
   ├── 추가 정보 필요 → 정보 보강 → 재진입 [4]
   │
   └── 적용 불가 → 디자인허브 알림 + 백로그 blocked → 종료
   ↓
[5] 적용 (수치/컨텐츠 박기)
   ↓
[6] 사후 확인 (문제 있으면 플머 재확인 루프)
   ↓
[7] 마무리 (체크인 / 백로그 / Discord 노티)
```

---

## 4. 단계별 정의

### [0] 관련 문서 읽기

**디자인허브 측**:

- spec의 main `.json` + `.screen.json` 둘 다 (있을 때)
- 관련 ADR (refs에 ADR-NNN 명시되어 있으면)
- 필요 시 refs 1차 추적 (연결된 spec/ADR 1 depth)

**ProjectMaid 측 가이드 (필수)**:

`Assets/Accelix/Docs/` 폴더 4 문서 중 작업 종류 매칭 (references/projectmaid-docs.md 참조):

- Conditional 변환 작업 → `ConditionalGuide.md`
- 가구 약어 변환 → `FurnitureKeyAssetMapping.md`
- HelpPopup 관련 → `HelpPopupConditionSetupGuide.md`
- 메이드 관련 값 = 메이드 프로필 SO / 카페 수치 = `Assets/Accelix/Data/Cafe/`

### [1] 넣을 스펙 선정

기획자가 spec-id 결정. 우선순위 룰 없음 — 작업 순서 기반.

### [2] 유니티 공간 파악

spec이 박힐 ProjectMaid 위치 식별 (SO 필드, locale 키, 컨텐츠, prefab/scene). Claude 주도 grep/find, 기획자 검토.

### [3] 우려 지점 파악 (5 카테고리)

| # | 카테고리 | 예시 |
|---|---------|------|
| 1 | 코드 충돌 | 같은 SO 다른 시스템도 참조 |
| 2 | 의도 모호 | spec 표현이 2개 해석 가능 |
| 3 | 데이터 의존 | locale/price/recipe 연계 갱신 필요 |
| 4 | 다른 spec 영향 | spec A 변경이 spec B 흐름에 영향 |
| 5 | spec 자체 outdated/충돌 | main spec vs screen-spec, 또는 ADR과 불일치 |

**사전 점검 룰 (필수)**:

각 우려를 [4] 플머 문의로 올리기 전, ProjectMaid 측에 이미 답이 있는지 점검:

- `Assets/Accelix/Docs/` 4 문서 매칭
- 메이드 관련 값 → 메이드 프로필 SO
- 카페 수치 → `Assets/Accelix/Data/Cafe/`
- 기존 wish/유사 asset에 패턴 grep

답 발견되면 **적용 가능 항목으로 이동**. 진짜 답 없는 것만 [4]로.

**모드 분기**:

- **우려 0건 + 코드와 spec 완전 정합** → 감사 모드 종료. [7] 마무리에 부수 발견만 처리.
- **우려 ≥ 1건** → 적용 모드. [4] 진행.

### [4] 플머 사전 확인

[3] 우려 + 적용 계획을 플머에게 송신. Section 5.1 템플릿.

**응답 4 결과**:

| 결과 | 처리 |
|------|------|
| OK | [5] 적용 진행 |
| 추가 정보 필요 | 정보 보강 → [4] 재진입 |
| 적용 불가 | 디자인허브 알림 + 백로그 `blocked` → 종료 |
| **예정 (시점 조건부 OK)** | 부분 적용 가능 부분만 [5]~[7] 진행 + 나머지 `deferred.md`로 이관. 플머 작업 완료 알림 받으면 deferred에서 매핑 → 후속 사이클 |

### [5] 적용

수치·데이터·컨텐츠를 Unity에 박음. SO Inspector / locale 키 참조 / prefab 변경 / 새 SO 인스턴스.

**기획자 주도 (Claude 보조)**. 인프라 부족 발견 시 플머 호출 (구현 요청).

### [6] 사후 확인

검증:

1. 컴파일 — `unity-cli editor refresh --compile`
2. 콘솔 에러 0 — `unity-cli console --type error`
3. 의도 동작 확인
4. 영향 범위 점검

**실패 시 분기**:

| 실패 | 처리 |
|------|------|
| 컴파일 에러 | 시도 미완. 잡고 재시도 |
| 런타임 에러 | 시도 미완. 원인 잡고 재시도 |
| 의도 동작 미달 | Section 5.2 사후 확인 송신 + 보정 |
| 다른 시스템 깨짐 | `cm status --short` 으로 이 세션 변경만 식별 → 보정 체크인 또는 선별 되돌림 |

종료 조건 룰 없음. 자연스러운 종료(해결 또는 포기).

### [7] 마무리

**트리거**: 기획자가 "마무리" / "사이클 종결" / "끝" 등 의사 표명 시 Claude가 아래 6단계 순차 수행.

1. **체크인** — `/cm-checkin` 슬래시 (AGENTS-PlasticSCM.md 룰: 한국어 / 상세 / 제목+`[섹션]` / 검증 명시). 이미 진행한 경우 스킵.
2. **인덱스 갱신** — `c:/WorkSpace/AccelixGames/design-apply-local/`
   - `backlog.md` 해당 행 → `completed.md` 이관 (체크인 cs:N 명시)
   - `specs/{spec-id}.md` 시도 N 블록 마무리
   - `deferred.md` 항목 갱신 (있으면)
3. **Discord 마무리 노티** — Section 5.3 템플릿 (옵션)
4. **부수 발견 처리** — outdated/충돌은 디자인허브 측 작업으로 분리 통보 (Section 5.4)
5. **gd00N → main/beta merge** — `/cm-merge-comment /main/beta` 슬래시 사용 (partial이든 full이든 항상 merge)
   - 성공 → 6단계 진행
   - **컨플릭트 발생 시** → 사용자에게 PlasticSCM GUI 해결 안내 + STOP. 해결 후 기획자가 [7] 5단계 재진입 신호 보내면 다시 시도
6. **새 sandbox 따기** — `gd00N+1-{spec-id}` 명명
   - 다음 spec-id 입력 받음 (예: `gd004-wish-pool-omong`)
   - `cm branch create gd00N+1-{spec-id} br:/main/beta` + `cm switch br:/main/beta/gd00N+1-{spec-id}`
   - 다음 spec-id 미정인 경우 → 5단계까지만 진행, 새 브랜치는 다음 사이클 [1] 단계 시작 시 따기

---

## 5. Discord 메시지 템플릿

### 5.1 사전 확인 — [4]단계 송신

본문(요약) + 첨부 md(상세) 2종 묶음.

**톤 룰** (필수, references/presend-tone.md):

- 자연어, spec/코드 약어는 풀어쓰기
- **3단 구조**: 작업하려는 것 / **제가 진행할 부분(보고)** / 막힌 부분(문의)
- "진행할 부분"은 기획자 자기 권한 — 플머에게 OK 묻지 않음, 단순 보고
- 막힌 부분에 부탁/협업 어조 + 예시 1개씩 + 구체 질문
- **Claude 자체 의견/판단 금지** — 사용자 명시한 경우만

**본문 형식**:

```markdown
<@김기민> <@박성범> <@조영우>
**[{spec-id}] 사전 확인 요청 — {spec 한국어 이름}**

**작업하려는 것**
{자연어 1~2문장}

**제가 진행할 부분** (보고)
- {평어 풀어쓰기 한 줄 — 자기 권한, OK 묻지 않음}
- ...

**막힌 부분** (이건 답이 있어야 진행 가능)
1. **{자연어 제목}** — {배경 + 예시 1개}
   질문: {구체 질문}
   {(사용자 명시한 경우만) 기획자 의견}
2. ...

상세는 첨부 md 참조.
spec: data/specs/{spec-id}.json
```

**첨부 md** (`design-apply-local/discord-attachments/{spec-id}-pre.md`):

- 배경 / ProjectMaid 매핑 / 제가 진행할 부분 / 막힌 부분 / 부수(locale) / 요청 요약 섹션

### 5.2 사후 확인 — [6]단계 문제 시

```markdown
<@김기민> <@박성범> <@조영우>
**[{spec-id}] 사후 확인 — {문제 요약}**

**적용한 것** (cs:{N})
- {변경 내역}

**발생 문제**
{컴파일/동작 미달/다른 시스템 깨짐}

**파악된 원인** (있으면)
{1~2문장}

**요청**
{진단 / 보정 방향 / 롤백 여부}
```

### 5.3 마무리 노티 — [7]단계 (옵션)

```markdown
**[{spec-id}] 적용 완료** (체크인 cs:{N})

**변경 내역**
- ...

spec: ...
```

- 멘션 없음 (가시성용)

### 5.4 디자인허브 부수 알림

```markdown
<@&기획팀>
**[{spec-id}] 디자인허브 측 갱신 권장**

**발견** (ProjectMaid 적용 작업 중 확인)
{outdated 또는 충돌 내용}

→ 디자인허브 측에서 갱신 진행.
```

---

## 6. 인덱스 + 회고 파일 (사용자 로컬)

위치: `c:/WorkSpace/AccelixGames/design-apply-local/`

3 인덱스 (메타) + spec 상세 회고 (자세히) 책임 분리.

### `backlog.md` — 활성 작업 표

진행 중인 spec ([3]~[6]단계). 한 줄 메타 인덱스.

| spec-id | 단계 | 모드 | 마지막 액션 | 다음 액션 | 체크인 | 노트 |
|---------|------|------|-------------|-----------|--------|------|
| ... | 4 | 적용 | 2026-05-14 | 플머 응답 대기 | - | ... |

**단계**: `try → awaiting → received` ([7] 마무리 즉시 `completed.md`로 이관)
**모드**: `적용` 또는 `감사`
**정렬**: `awaiting > received > try`, 같은 단계 내 마지막 액션 오래된 순.

### `completed.md` — 완료 history

종결된 spec 누적. 회고/마일스톤 참조.

| spec-id | 종결일 | 모드 | 체크인 | 변경 요약 | 노트 |

### `deferred.md` — 대기 큐

[4]단계 응답 "예정" 항목 + 사용자 자체 학습 대기 항목.

| spec-id | 항목 | 의존 | 대기 사유 | 등록일 | 알림 채널 |

알림 받으면 → deferred 매핑 → spec 상세 시도 N 블록 추가 → backlog 재진입.

### `specs/{spec-id}.md` — spec별 상세

```markdown
# {spec-id}

**현재 상태**: 단계 N / 모드 적용 (날짜)
**spec**: `data/specs/{spec-id}.json`

## 시도 1 — {YYYY-MM-DD} (모드: 적용)

**0~3단계 요약**: ...
**우려 (3단계)**: ...
**4단계 결과**: OK / 추가 정보 / 적용 불가
**Discord 사전 메시지**: ...
**플머 응답**: ...
**5단계 변경**: ...
**6단계 검증**: ...
**종결**: 체크인 cs:{N}
```

### `discord-attachments/{spec-id}-{pre|post|done}.md`

Discord 송신 시점 첨부 사본. 회고/추적용. 사용자 로컬만.

---

## 7. 부록

### 7.1 Discord 인프라

- 채널 공유: `1359366037841117356` (디자인허브와 동일)
- 인프라: Windows junction `mklink /J` — ProjectMaid `.discord-webhook` → 디자인허브 `.discord-webhook` (PlasticSCM 추적 안 함 + `ignore.conf` 이중 보호)
- 멘션 매핑: 김규혁(기획) `356348086483943424` / 곽한규(기획) `358545615468363776` / 김기민(플머) `390391994314391552` / 박성범(플머) `389989278865817601` / 조영우(플머) `1449459616093311220` / 기획팀 role `1496480510787195120`

### 7.2 디자인허브 경로

`C:/WorkSpace/github.io/AccelixGames/mcs-design-workspace`

본 문서의 spec/ADR 경로는 디자인허브 기준 상대 경로 (`data/specs/{spec-id}.json`, `intent/ADR-NNN-{name}.md`).

### 7.3 ProjectMaid 경로

`C:/WorkSpace/AccelixGames/ProjectMaid`

### 7.4 사용자 로컬 작업공간

`c:/WorkSpace/AccelixGames/design-apply-local/` — backlog / specs / discord-attachments
