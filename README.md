# accelix-ai-plugins

AccelixGames 팀 전용 Claude Code 플러그인 마켓플레이스입니다.

## 빠른 시작 (신규 팀원)

```bash
# 온보딩 스크립트 1회 실행 — 마켓플레이스 + 플러그인 + CLI 도구 전부 설치
bash <(curl -s https://raw.githubusercontent.com/AccelixGames/accelix-ai-plugins/main/scripts/team-setup.sh)
```

또는 레포를 클론한 뒤:
```bash
bash scripts/team-setup.sh
```

## 수동 설치

```bash
# 1. 마켓플레이스 등록 (최초 1회)
claude plugin marketplace add AccelixGames/accelix-ai-plugins

# 2. 원하는 플러그인 설치
claude plugin install claude-plastic-scm@accelix-ai-plugins
claude plugin install win-file-tools@accelix-ai-plugins
claude plugin install generate-image@accelix-ai-plugins
claude plugin install discord-webhook@accelix-ai-plugins
claude plugin install prof-oak-explain@accelix-ai-plugins
```

## 업데이트

```bash
# 마켓플레이스 + 플러그인 모두 업데이트
claude plugin marketplace update accelix-ai-plugins
claude plugin update claude-plastic-scm@accelix-ai-plugins
claude plugin update win-file-tools@accelix-ai-plugins
claude plugin update generate-image@accelix-ai-plugins
claude plugin update discord-webhook@accelix-ai-plugins
claude plugin update prof-oak-explain@accelix-ai-plugins
```

---

## 플러그인 목록

| 플러그인 | 버전 | 설명 |
|----------|------|------|
| [claude-plastic-scm](plugins/claude-plastic-scm/) | v0.1.0 | PlasticSCM (Unity Version Control) 워크플로우 자동화 |
| [generate-image](plugins/generate-image/) | v0.2.0 | AI 이미지 생성 — Ideation + Detail 모드, MCP + CLI 래퍼 |
| [win-file-tools](plugins/win-file-tools/) | v0.1.0 | Windows 문서 도구 — PDF/DOCX/Excel/HWP 읽기 + HWP 생성 |
| [discord-webhook](plugins/discord-webhook/) | v0.4.0 | Discord 웹훅 메시지 — 채널 선택, 멘션, 파일 첨부 |
| [prof-oak-explain](plugins/prof-oak-explain/) | v0.1.0 | 문과식 설명 + 기술 교육 — 비유 기반 기술 개념 해설 |

---

## 함께 사용하는 외부 도구

온보딩 스크립트가 자동 설치합니다:

| 도구 | 패키지 | 용도 |
|------|--------|------|
| gws | `@googleworkspace/cli` | Google Sheets/Docs/Drive 연동 |
| @google/genai | `@google/genai` | generate-image CLI 래퍼 (서브에이전트용) |
| 공식 플러그인 | `claude-plugins-official` | superpowers, frontend-design 등 |

---

## 라이선스

MIT License
