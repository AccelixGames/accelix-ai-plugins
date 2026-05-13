# Changelog — unity-spec-bridge

형식은 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)를 기반으로 하며,
[Semantic Versioning](https://semver.org/spec/v2.0.0.html)을 따른다.

## [0.1.2] - 2026-05-13

### 추가
- `where-am-i` 스킬 이식 (mcs-design-workspace 원본 일반화) — 세션 self-check. "어디까지 했지", "정신차려", `/where-am-i` 등 트리거 시 4섹션 (어쩌다/갈라져/어디까지/방금 뭘) 친근체 보고. 위험 신호 5종 (컨텍스트 단절·다단계 지시·origin confidence 낮음·명시 요청·lane 불일치) 자동 감지로 expensive 쿼리 활성화. 핸드오버와 자연스러운 쌍 — `/handover`(plugin handover)가 다음 세션에 쓰면, `where-am-i`는 현재 세션이 읽음.

## [0.1.1] - 2026-05-13

### 추가
- `unity-cli-reference` 스킬 — unity-cli v0.3.x 명령군·옵션·표준 패턴 reference. 빌트인 명령(editor/console/exec/menu/screenshot/reserialize/test/profiler/list/status/update) 전체 + 커스텀 툴 호출 패턴(`--params '{"k":"v"}'`) + spec→Unity 적용 워크플로 가이드. 프로젝트별 툴 인벤토리는 `unity-cli list`로 발견.

## [0.1.0] - 2026-05-13

### 추가
- 초기 플러그인 스캐폴드 — 기획 데이터를 Unity 에셋으로 옮기는 도메인 스킬들의 컨테이너 역할.
- `new-skill` 스킬 + `/new-skill` 커맨드 — 이 플러그인 안에 새 스킬을 스캐폴딩하는 메타 도구. 폴더·SKILL.md 템플릿 생성, plugin.json 버전 패치 bump, 플러그인 CHANGELOG·루트 CHANGELOG·marketplace.json 동기화, 금지어 보안 grep까지 자동. `git commit`/`push`는 수동.
