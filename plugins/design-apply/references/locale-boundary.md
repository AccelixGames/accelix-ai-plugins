# Locale Boundary

**Locale은 디자인허브의 영역. Claude는 ProjectMaid locale 파일에 키를 직접 추가/수정하지 않는다.**

## 배경

2026-05-13 wish-pool-jegal dry-run에서 [2]단계 "박을 위치" 매핑할 때 "ProjectMaid locale 5 files에 wish.jegal.* 키 9개 추가"를 박을 작업으로 자동 가정한 게 잘못. 사용자 명시: "로케일은 디자인허브의 영역. 너는 로케일이 존재하는지, 그리고 있으면 박고, 없으면 요청을 하는 것이다."

## 룰

- spec이 요구하는 localeKey들에 대해:
  - **있는지 확인** — 디자인허브 측 locale 데이터(또는 동기화된 ProjectMaid `Assets/Accelix/Data/System.Locale/` 5 files: KO/EN/JA/ZH/ZH-TW)에서 키 존재 여부
  - **있으면** → ProjectMaid SO/asset의 `localeKey` 필드에 키 문자열 참조 입력 (이건 Claude가 함, "박는다")
  - **없으면** → 디자인허브 측에 키 추가 **요청** 송신 (Discord 부수 알림 또는 PR 등). Claude가 locale 파일 직접 수정 금지.

## "Claude가 박는 것" vs "안 박는 것"

- **박는 것**: SO/asset에 키 참조 입력 (예: `SO_WishEntry.dialogue.requestDialogue.dialogueKey = "wish.jegal.r044.request"`)
- **안 박는 것**: locale 파일 자체에 키:value 쌍 추가

## 적용 단계

- [2] 박을 위치 매핑 시 locale 파일 자체는 박을 위치 후보에서 제외
- 단 키 존재 확인은 [0]~[2]단계 책무
- 신규 키 = 디자인허브 측 작업 (Section 5.4 부수 알림)
