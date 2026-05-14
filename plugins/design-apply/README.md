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

## VCS 책임 분담

워크플로우 중 여러 시스템이 등장. 각각 다른 도구로 작업:

| 시스템 | 대상 | 도구 | 언제 |
|--------|------|------|------|
| **PlasticSCM** | ProjectMaid 워크스페이스 (Wish asset, 코드 fix 등) | `cm` CLI / `claude-plastic-scm` plugin (`cm-checkin` 등) | spec 적용 [5]단계 결과 박은 후 |
| **Git** | accelix-ai-plugins marketplace (design-apply plugin 자체) | `git` CLI | design-apply 룰/skill 갱신 후 |
| (VCS 없음) | 사용자 로컬 (backlog / specs / 첨부) | 일반 파일 — 로컬 보존 | 적용 사이클 중 갱신 |
| (별도 관리) | 디자인허브 (`mcs-design-workspace`) | 디자인허브 측 워크플로우 (이 plugin 책임 외) | spec/ADR 확인만, 갱신 X |

→ 같은 세션에 cm + git 둘 다 등장 가능. 헷갈리지 않게 위 표 참조.

## 의존

- `discord-webhook` plugin (사전 확인 메시지 송신용)
- `claude-plastic-scm` plugin (ProjectMaid 체크인용)
- 디자인허브 워크스페이스 (`C:/WorkSpace/github.io/AccelixGames/mcs-design-workspace`)
- ProjectMaid 워크스페이스 (`C:/WorkSpace/AccelixGames/ProjectMaid`)
