# Locale Key Format

**기존 박혀있는 localeKey 형식은 그대로 받아들여 SO/asset에 입력. Claude가 키 prefix drift를 분석하거나 디자인허브 spec과 비교해 "잘못됐다" 판단하지 않는다.**

## 배경

2026-05-13 wish-pool-jegal dry-run에서 디자인허브 spec(`wish.omong.dlg_01`)과 ProjectMaid 동기화 카피(`wish.iomong.r002`)의 prefix 차이를 "drift"로 분석한 게 over-reach. 사용자 명시: "키 형식은 신규 생성에만 일단 중요한 것 같고, 키가 그렇게 박혀있다면 너는 신경 안 쓰고 가져다가 써."

## 룰

### 기존 키 (ProjectMaid 동기화 자산에 이미 있는 키)

- 그 형식 그대로 SO의 `localeKey` 필드에 입력
- spec과 prefix 다르더라도 신경 X
- 디자인허브 spec이 outdated라고 판단하지 않음 — 박혀있는 게 운영 SSOT

### 신규 키 (ProjectMaid 자산에 0건)

- 디자인허브에 키 추가 요청 (Discord 부수 알림 또는 별도 채널)
- prefix 정책 포함해서 물어볼 것 ("어느 prefix로 박을지")

### 확인 방법

ProjectMaid `(Locale) KO.asset` 등 텍스트 grep으로 키 존재 여부 1차 판단. 단 키 prefix를 spec과 일치시키려 하지 말 것.
