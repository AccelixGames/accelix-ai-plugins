# design-apply

디자인허브(`mcs-design-workspace`)의 spec/ADR을 ProjectMaid(Unity) 워크스페이스에 적용하는 표준 워크플로우.

## 핵심 모델

```
[Pick spec] → [Pre-try] → [Try] → [Branch by result]
                                       ├ ✅ 성공 → 체크인
                                       ├ ❓ 의문 → 사전 확인 → ...
                                       ├ 🔍 못 찾음 → 사전 확인
                                       ├ 🛠️ 자체 구현 → 검토 요청
                                       └ ❌ 구현 요청
```

7단계 순차 + 확인 2회(사전/사후) + 모드 분기(적용/감사). 자세한 흐름은 `references/PROCESS.md`.

## 사용 모델

- **편집자** (기획자 1명): spec 적용 사이클 실행, 룰 갱신
- **read-only** (다른 기획자/리뷰어): 마일스톤/회고 시 참조

## 구성

```
design-apply/
├── commands/
│   └── design-send-pre.md   ← /design-send-pre <spec-id>
├── skills/
│   └── design-apply/
│       └── SKILL.md         ← 전체 워크플로우 룰
└── references/
    ├── PROCESS.md           ← 자세한 본문
    ├── presend-tone.md      ← 사전 확인 메시지 톤 룰
    ├── projectmaid-docs.md  ← ProjectMaid Docs 폴더 인덱스
    ├── locale-boundary.md   ← Locale 디자인허브 영역 룰
    └── locale-key-format.md ← Locale 키 형식 룰
```

## 동적 데이터 (plugin 외)

backlog / spec 상세 / 디스코드 첨부 사본은 **각 사용자 로컬**에 보존 (편집자 본인 추적용):

```
{사용자 로컬}/design-apply-local/
├── backlog.md
├── specs/{spec-id}.md
└── discord-attachments/{spec-id}-{pre|post|done}.md
```

곽한규 같은 read-only 사용자는 plugin install + Discord 채널 참조로 충분 (backlog 미공유).

## 의존

- `discord-webhook` plugin (사전 확인 메시지 송신용)
- 디자인허브 워크스페이스 (`C:/WorkSpace/github.io/AccelixGames/mcs-design-workspace`)
- ProjectMaid 워크스페이스 (`C:/WorkSpace/AccelixGames/ProjectMaid`)
