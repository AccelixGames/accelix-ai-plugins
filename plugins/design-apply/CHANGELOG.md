# Changelog

## [0.1.0] - 2026-05-13

### 추가

- 최초 릴리스. ProjectMaid 워크스페이스에서 작업하던 design-apply 인프라를 plugin으로 패키지화.
- `commands/design-send-pre.md`: 디자인허브 적용 [4]단계 사전 확인 송신 wrapper (요약 본문 + 상세 md 첨부, 자연어 트리거).
- `skills/design-apply/SKILL.md`: 디자인허브 → ProjectMaid 적용 7단계 워크플로우 + 확인 2회(사전/사후) + 모드 분기(적용/감사).
- `references/`: PROCESS 본문, presend 톤 룰, ProjectMaid Docs 인덱스, locale 영역/키 형식 룰.

### 배경

2026-05-13 ProjectMaid 워크스페이스에서 진행한 wish-pool-jegal 적용 사이클의 학습을 그대로 plugin으로 이전.

- 인프라 4 changeset 누적 (cs:4712 v1 도입 → cs:4724 v2 재정의 → cs:4735 첫 dry-run + skill → cs:4739 톤 룰 정비)
- 룰 변경/skill 추가가 ProjectMaid 브랜치 의존이라 브랜치 이동 시 사라지는 문제 → plugin으로 분리하여 브랜치 무관 + 곽한규 공유 가능
- 사용자(편집) + 곽한규(read-only, 마일스톤 시점 참조) 사용 모델
