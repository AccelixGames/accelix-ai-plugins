#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# AccelixGames 팀 온보딩 스크립트
# 신규 팀원이 1회 실행하면 Claude Code 환경이 세팅됩니다.
# ============================================================

echo "=== AccelixGames Team Setup ==="
echo ""

# ── 0. 전제조건 확인 ──────────────────────────────────────
check_cmd() {
  if ! command -v "$1" &>/dev/null; then
    echo "❌ $1 이(가) 설치되어 있지 않습니다."
    echo "   $2"
    exit 1
  fi
  echo "✅ $1 확인됨"
}

check_cmd "node"   "https://nodejs.org 에서 Node.js 20+ 설치"
check_cmd "npm"    "Node.js 설치 시 함께 설치됩니다"
check_cmd "git"    "https://git-scm.com 에서 Git 설치"
check_cmd "claude" "https://docs.anthropic.com/en/docs/claude-code 에서 Claude Code 설치"

echo ""

# ── 1. 마켓플레이스 등록 ──────────────────────────────────
echo "--- 마켓플레이스 등록 ---"

# 공식 마켓플레이스 (superpowers, frontend-design, skill-creator 등)
echo "📦 claude-plugins-official (Anthropic 공식)"
claude plugin marketplace add anthropics/claude-plugins-official 2>/dev/null || echo "   (이미 등록됨)"

# 팀 마켓플레이스 (generate-image, discord-webhook, plastic-scm, win-file-tools, prof-oak-explain)
echo "📦 accelix-ai-plugins (팀 전용)"
claude plugin marketplace add AccelixGames/accelix-ai-plugins 2>/dev/null || echo "   (이미 등록됨)"

echo ""

# ── 2. 플러그인 설치 ─────────────────────────────────────
echo "--- 플러그인 설치 ---"

# 공식 플러그인
for plugin in frontend-design skill-creator; do
  echo "📥 $plugin (공식)"
  claude plugin install "${plugin}@claude-plugins-official" 2>/dev/null || echo "   (이미 설치됨)"
done

# 팀 플러그인
for plugin in claude-plastic-scm generate-image win-file-tools discord-webhook prof-oak-explain; do
  echo "📥 $plugin (팀)"
  claude plugin install "${plugin}@accelix-ai-plugins" 2>/dev/null || echo "   (이미 설치됨)"
done

echo ""

# ── 3. CLI 도구 설치 ─────────────────────────────────────
echo "--- CLI 도구 설치 ---"

# Google Workspace CLI (gws)
if command -v gws &>/dev/null; then
  echo "✅ gws 이미 설치됨 ($(gws --version 2>/dev/null | head -1))"
else
  echo "📥 gws (Google Workspace CLI) 설치 중..."
  npm install -g @googleworkspace/cli
  echo "✅ gws 설치 완료"
fi

# @google/genai (generate-image CLI 래퍼용)
if node -e "require('@google/genai')" 2>/dev/null; then
  echo "✅ @google/genai 이미 설치됨"
else
  echo "📥 @google/genai 설치 중..."
  npm install -g @google/genai
  echo "✅ @google/genai 설치 완료"
fi

echo ""

# ── 4. 완료 ──────────────────────────────────────────────
echo "=== 설정 완료! ==="
echo ""
echo "다음 단계:"
echo "  1. Gemini API key 설정 (이미지 생성 사용 시):"
echo "     claude mcp add image-gen --scope user -e GEMINI_API_KEY=<key> -- npx -y mcp-image"
echo "  2. gws 인증 (Google Sheets/Docs 사용 시):"
echo "     gws auth login"
echo "  3. Discord 웹훅 설정 (알림 사용 시):"
echo "     프로젝트 루트에 .discord-webhook-config.json 생성"
echo ""
echo "문제가 있으면 규혁님(@neonstarQ)에게 문의하세요."
