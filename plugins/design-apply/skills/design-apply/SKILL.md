---
name: design-apply
description: >
  디자인허브(mcs-design-workspace)의 spec/ADR을 ProjectMaid(Unity) 워크스페이스에
  적용하는 표준 워크플로우. 7단계 순차 진행 + 확인 2회(사전/사후) + 모드 분기(적용/감사)
  모델. spec 적용 사이클 시작/진단/사전 확인 메시지 작성/적용/마무리 전 과정에서 활용.

  Korean triggers:
  "디자인허브 적용", "스펙 적용", "{spec-id} 적용", "wish-pool 적용",
  "spec dry-run", "적용 사이클 시작", "디자인허브 동기화"

  English triggers:
  "apply design hub spec", "apply {spec-id}", "design hub workflow",
  "spec application cycle"
---

# Design Apply — 디자인허브 → ProjectMaid 적용 워크플로우

## 핵심 모델

```
[0] 관련 문서 읽기 (디자인허브 spec + ProjectMaid Docs)
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

자세한 단계 정의 + Discord 메시지 템플릿 + 백로그 형식 → **`references/PROCESS.md`**.

## 핵심 룰 (압축)

### Spec 종류 분류

- **컨텐츠/수치 spec** (wish-pool, recipe, locale, 가격 등): 이 워크플로우 메인 대상. 기획자 적용.
- **인프라(로직/구조) spec** (wish-system 본체, customer spawner 알고리즘 등): 이 워크플로우 밖. 플머 영역.

### 적용 가능 항목 vs 문의 항목 구분

- **진행 가능한 것을 진행하는 것은 기획자 자기 권한** — 플머에게 OK 묻지 않음, 단순 보고
- **막힌 부분만 플머 문의** — 답이 있어야 진행 가능한 항목

### 사전 점검 룰 (필수)

플머 문의로 올리기 전 ProjectMaid 측에 이미 답이 있는지 점검:

- `Assets/Accelix/Docs/` 4 문서 (references/projectmaid-docs.md)
- 메이드 관련 값 = 메이드 프로필 SO (`Game.Profile/Actor.Maid/`)
- 카페 수치 = `Assets/Accelix/Data/Cafe/`
- 기존 wish/유사 asset grep

답 발견되면 막힌 부분 → 적용 가능 항목으로 이동.

### Discord 메시지 톤 룰

- 자연어, 약어 풀어쓰기 (`commonDialogueOverrides` → "공통 가구 소망을 메이드별 톤으로 말하게 하는 구조" 등)
- 3단 구조: 작업하려는 것 / 제가 진행할 부분 / 막힌 부분
- 부탁/협업 어조 (막힌 부분만)
- **Claude 자체 의견/판단 금지** — 사용자 명시한 경우만
- 자세히 → references/presend-tone.md

### Locale 경계

- Locale은 디자인허브 영역
- 키 존재 확인만, 없으면 디자인허브 측 요청 (Claude 직접 추가 X)
- 박혀있는 키 형식 그대로 사용, 신규 prefix는 디자인허브 결정
- 자세히 → references/locale-boundary.md, references/locale-key-format.md

## 동적 데이터 (plugin 외)

backlog / spec 상세 / 디스코드 첨부 사본 = 사용자 로컬:

```
c:/WorkSpace/AccelixGames/design-apply-local/
├── backlog.md
├── specs/{spec-id}.md
└── discord-attachments/{spec-id}-{pre|post|done}.md
```

## 관련 도구

- `/design-send-pre <spec-id>` — [4]단계 사전 확인 송신 wrapper (commands/)
- 향후: `/design-send-post`, `/design-send-done`, `/design-send-hub-notify`

## References

- `references/PROCESS.md` — 자세한 단계별 룰 + Discord 메시지 템플릿 + 백로그 형식
- `references/presend-tone.md` — 사전 확인 메시지 톤 룰
- `references/projectmaid-docs.md` — ProjectMaid Docs 폴더 인덱스
- `references/locale-boundary.md` — Locale 디자인허브 영역 룰
- `references/locale-key-format.md` — Locale 키 형식 룰
