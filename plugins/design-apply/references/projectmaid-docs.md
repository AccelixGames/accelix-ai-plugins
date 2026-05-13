# ProjectMaid Docs Index

ProjectMaid 워크스페이스 안의 가이드/매핑 문서 폴더. 디자인허브 적용 사이클의 [0]단계 / [3]단계에서 우선 참조.

## 위치

`Assets/Accelix/Docs/` (ProjectMaid 워크스페이스)

## 문서 목록

| 문서 | 용도 | 언제 활용 |
|------|------|---------|
| `AGENTS.md` | Docs 폴더 작성 기준 + 문서 템플릿 | 새 가이드 추가/편집 시 |
| `ConditionalGuide.md` | `Accelib.Conditional` 개념·사용법·PresetValue·구독 방식 | spec의 `unlockCondition`, `fulfillCondition` 등 조건 변환 시 |
| `HelpPopupConditionSetupGuide.md` | HelpPopup Entry 조건 설정 + HELP ID별 권장 조건 | HelpPopup 관련 작업 |
| `FurnitureKeyAssetMapping.md` | 기획 가구 키(F_JU/F_BR/F_AS 등) ↔ 인게임 가구 SO/프리팹/코드 매핑 | spec의 가구 약어를 인게임 자산으로 변환 시 |

## 박성범 답 룰 (2026-05-13 wish-pool-jegal 응답에서 정리)

- **메이드 관련 값** (인연도, 해금, 스탯 등) = **메이드 프로필 SO 확인** (`Assets/Accelix/Data/Game.Profile/Actor.Maid/`)
- **카페 관련 수치** (카페 레벨, 영업일 등) = **`Assets/Accelix/Data/Cafe/` 내부에서 확인**
- **Conditional 변환** = `ConditionalGuide.md` 참고 (PresetValue / Custom MemberRef 판단 순서)

## 사전 작업/우려 진단에서 사용

PROCESS.md Section 4 [0]단계와 [3]단계에서 ProjectMaid 측 답이 이미 있을 가능성을 먼저 점검:

1. 막힌 부분(우려)이 위 4 문서 중 하나에 답이 있는지 매칭
2. 메이드 관련이면 메이드 프로필 SO 검색
3. 카페 수치면 `Data/Cafe/` SO 검색
4. 위 셋 다 점검 후 진짜 답 없는 우려만 [4] 플머 문의로

이 점검이 누락되면 플머가 이미 답한 정보를 다시 물어보는 실수 발생.
