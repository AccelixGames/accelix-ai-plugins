#!/usr/bin/env bash
# reflect-destructive-cm.sh — plastic-scm plugin Post-task Reflection trigger
#
# Input (stdin): Claude Code PostToolUse hook JSON.
# Behavior: if the just-run Bash command matches `cm (checkin|merge|label)` and
# exit code was 0, emit a hookSpecificOutput.additionalContext JSON on stdout
# instructing Claude to follow the SKILL.md "Post-task Reflection" protocol.
# Otherwise: silently exit 0 (no output = no injection).
#
# Exit codes: always 0 unless jq is missing. Never exit 2 — we do not want to
# block cm commands retroactively.

set -u

# Dependency check — jq is part of Git Bash and most dev envs. If missing,
# we skip silently rather than fail the tool call.
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

# Read entire stdin
input=$(cat)

# Extract fields
tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty')
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
exit_code=$(printf '%s' "$input" | jq -r '.tool_response.exit_code // .exit_code // empty')

# Gate 1: Must be a Bash tool use
[ "$tool_name" = "Bash" ] || exit 0

# Gate 2: Command must match destructive cm subcommand at a word boundary.
# Regex explicitly lists 3 subcommands (no partial prefix like `cm checkout`).
# Anchored to whitespace or start-of-line before `cm` to avoid matching
# `mycm checkin` or comments.
if ! printf '%s' "$command" | grep -Eq '(^|[[:space:];|&])cm[[:space:]]+(checkin|merge|label)([[:space:];|&]|$)'; then
  exit 0
fi

# Gate 3: Exit code must be 0 (success). Missing exit_code counted as failure
# to be safe — hooks shouldn't fire on ambiguous outcomes.
[ "$exit_code" = "0" ] || exit 0

# All gates passed — emit additionalContext for Claude.
jq -n '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: "A destructive `cm` command (checkin / merge / label) just completed successfully. Per claude-plastic-scm skill SKILL.md `## Post-task Reflection` protocol, evaluate this session against the 5 friction signals in `skills/plastic-scm/templates/reflection-prompt.md`. If ≥1 signal is present, draft a one-line summary and ask the user whether to capture as a gotcha issue. If all signals are absent, proceed silently."
  }
}'
