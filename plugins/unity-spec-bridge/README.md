# unity-spec-bridge

기획 워크스페이스의 spec 데이터를 Unity 에셋으로 옮기는 도메인 스킬들의 컨테이너.

## 현재 제공

| 종류 | 이름 | 설명 |
|------|------|------|
| Skill | `new-skill` | 새 스킬 추가를 안내 — 이름·설명·도메인·입력 형태 수집 후 `/new-skill` 위임 |
| Command | `/new-skill <name> [--domain ...]` | 실제 스캐폴딩 — 폴더·SKILL.md·plugin.json·CHANGELOG·marketplace.json 갱신 |

## 사용 흐름

1. 사용자: "새 스킬 만들고 싶어"
2. `new-skill` 스킬이 한 번에 하나씩 질문 (이름·설명·도메인·입력)
3. 마지막에 `/new-skill <name> --domain <d>` 호출
4. 파일 생성 + 메타데이터 동기 + 보안 grep 자동
5. 사용자가 `git diff` 검토 후 commit/push 수동 진행

## 도메인 분류 (`--domain`)

| 값 | 의도 |
|----|------|
| `quest` | 기획 → Quest 에셋 (Task·locale·체인) |
| `so-sync` | JSON spec → ScriptableObject 데이터 동기 |
| `locale` | locale key/text를 5개 언어 시트에 적용 |
| `screen` | screen-spec → 프리팹/씬 UI 배치 |
| `other` | 위 분류에 안 맞는 일반 스킬 |

## 보안

플러그인 파일에 팀 내부 식별자(프로젝트명·실제 경로·개인명) 노출 금지.
스캐폴딩된 SKILL.md는 자동 grep을 한 번 더 거친다.
세부 규칙은 마켓플레이스 루트 `CLAUDE.md` 참조.

## 라이선스

MIT License
