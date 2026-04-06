---
name: chatgpt-agent
description: "ChatGPT-first subagent dispatch for review/verification — Codex CLI backend, ChatGPT Plus auth. 리뷰·검증·세컨드 오피니언을 ChatGPT에 먼저 위임하여 Claude 토큰 절약. ChatGPT 실패 시 Claude 폴백."
---

# ChatGPT Subagent — Review & Verification Dispatch

서브에이전트로 리뷰/검증 작업을 수행할 때, **ChatGPT를 우선 호출**하고
실패 시 Claude 서브에이전트로 폴백하는 패턴.

**목적:** Claude 토큰 절약 — 리뷰/검증 같은 독립 작업을 ChatGPT에 위임.

## Dispatch Pattern

```
리뷰/검증 필요
    │
    ▼
① ChatGPT 호출 (ask-chatgpt.mjs)
    │
    ├─ 성공 → 결과 사용
    │
    └─ 실패 (timeout, auth error, empty response)
        │
        ▼
② Claude 서브에이전트 폴백 (Agent tool)
```

## Step 1: Try ChatGPT First

```bash
node "<plugins>/chatgpt-agent/skills/chatgpt-agent/scripts/ask-chatgpt.mjs" \
  --prompt "<review prompt>" \
  --system "<review instructions>"
```

Where `<plugins>` = `~/.claude/plugins/marketplaces/accelix-ai-plugins/plugins`

### Script Parameters

| Flag | Default | Description |
|------|---------|-------------|
| `--prompt` / `-p` | (required) | Review prompt with full context |
| `--model` / `-m` | (codex default) | OpenAI model override |
| `--system` / `-s` | (empty) | System prompt for reviewer persona |
| `--sandbox` | `read-only` | Codex sandbox mode |

### Output

- **exit 0 + stdout**: ChatGPT response — use this result
- **exit 1 + stderr**: Failed — proceed to Step 2

## Step 2: Claude Fallback

If Step 1 fails (non-zero exit, empty output, or timeout), dispatch a Claude
subagent with the same prompt:

```
Agent(subagent_type: "general-purpose", prompt: "<same review prompt>")
```

## Use Cases

- **Code review**: diff 검토, 버그 탐지, 보안 점검
- **Spec review**: 기획 문서 교차 검증
- **Second opinion**: Claude 작성물에 대한 독립 검증
- **Translation review**: 번역 품질 교차 확인

## Prompt Template (Review)

```
You are reviewing the following changes. Be direct and specific.
Point out bugs, logic errors, security issues, and missing edge cases.
If everything looks correct, say "LGTM" with a brief explanation.

---
<diff or content to review>
```

## Prerequisites

- `codex` CLI: `npm install -g @openai/codex`
- ChatGPT login: `codex login`
- No API credits needed — uses ChatGPT Plus subscription

## Constraints

- Do NOT send credentials, API keys, or secrets in prompts
- 5-minute timeout on ChatGPT calls
- Always attribute: "ChatGPT 리뷰 결과" vs "Claude 리뷰 결과 (폴백)"
- Read-only sandbox — ChatGPT cannot modify files
