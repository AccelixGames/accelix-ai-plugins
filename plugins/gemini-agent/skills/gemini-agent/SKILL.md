---
name: gemini-agent
description: "Gemini-first subagent dispatch — 구현/리뷰 모두 가능. Gemini CLI 백엔드, GEMINI_API_KEY 인증. 단순 구현·리뷰·검증을 Gemini에 위임하여 Claude 토큰 절약. Gemini 실패 시 Claude 폴백."
---

# Gemini Subagent — Implementation & Review Dispatch

서브에이전트로 **구현 또는 리뷰** 작업을 수행할 때, **Gemini를 우선 호출**하고
실패 시 Claude 서브에이전트로 폴백하는 패턴.

**목적:** Claude 토큰 절약 — 단순 구현 및 리뷰/검증을 Gemini에 위임.

## Codex(ChatGPT) vs Gemini 역할 분담

| | ChatGPT (chatgpt-agent) | Gemini (gemini-agent) |
|---|---|---|
| **파일 수정** | read-only | **가능** (yolo 모드) |
| **용도** | 리뷰/검증 전용 | 구현 + 리뷰 겸용 |
| **우선 배치** | 교차 검증, 세컨드 오피니언 | 단순 구현, JSON 수정, 파일 생성 |

## Dispatch Pattern

```
구현 또는 리뷰 필요
    │
    ▼
① Gemini 호출 (ask-gemini.mjs)
    │
    ├─ 성공 → 결과 사용 (구현이면 git diff --stat 확인)
    │
    └─ 실패 (timeout, auth error, empty response)
        │
        ▼
② Claude 서브에이전트 폴백 (Agent tool)
```

## Step 1: Call Gemini

### Review (read-only)

```bash
node "<plugins>/gemini-agent/skills/gemini-agent/scripts/ask-gemini.mjs" \
  --prompt "<review prompt>" \
  --sandbox
```

### Implementation (file modification)

```bash
node "<plugins>/gemini-agent/skills/gemini-agent/scripts/ask-gemini.mjs" \
  --prompt "<implementation prompt>" \
  --approval-mode "yolo" \
  --cwd "<worktree path>"
```

Where `<plugins>` = `~/.claude/plugins/marketplaces/accelix-ai-plugins/plugins`

### Script Parameters

| Flag | Default | Description |
|------|---------|-------------|
| `--prompt` / `-p` | (required) | Task prompt with full context |
| `--model` / `-m` | (gemini default) | Model override (e.g., `gemini-2.5-pro`) |
| `--approval-mode` | `yolo` | `yolo`=auto-approve all, `auto_edit`=auto-approve edits, `plan`=read-only |
| `--cwd` | (current dir) | Working directory (use for worktree isolation) |
| `--sandbox` / `-s` | false | Enable sandbox mode (read-only) |
| `--output-format` | `json` | Output format (`json`, `text`, `stream-json`) |

### Output

- **exit 0 + stdout**: Gemini response text
- **exit 1 + stderr**: Failed — proceed to Step 2
- **stderr**: Stats line with latency/token/file-change info

## Step 2: Claude Fallback

If Step 1 fails (non-zero exit, empty output, or timeout):

```
Agent(subagent_type: "general-purpose", prompt: "<same prompt>")
```

## Approval Modes

| Mode | 파일 수정 | 용도 |
|------|----------|------|
| `yolo` | 모든 도구 자동 승인 | 단순 구현 (worktree 격리 필수) |
| `auto_edit` | 편집만 자동 승인 | 중간 위험 작업 |
| `plan` | read-only | 리뷰/분석 |

## Use Cases

- **단순 구현**: JSON 파일 생성/수정, 설정 파일 업데이트, 보일러플레이트 생성
- **Code review**: diff 검토, 버그 탐지, 보안 점검
- **Spec review**: 기획 문서 교차 검증
- **파일 변환**: 포맷 변환, 데이터 마이그레이션

## Safety Rules

1. **구현 시 반드시 worktree 격리** — `--cwd`로 worktree 경로 지정
2. **완료 후 `git diff --stat` 확인** — 스코프 크리프 방지
3. **브랜치 확인** — 완료 후 `git branch --show-current` 검증
4. Do NOT send credentials, API keys, or secrets in prompts
5. 5-minute timeout
6. Always attribute: "Gemini 구현/리뷰 결과" vs "Claude 결과 (폴백)"

## Prerequisites

- `gemini` CLI: `npm install -g @google/gemini-cli`
- `GEMINI_API_KEY` environment variable set
- Get key: https://aistudio.google.com/apikey
