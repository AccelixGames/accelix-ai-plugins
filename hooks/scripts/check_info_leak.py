#!/usr/bin/env python3
"""
Information Leak Detection Hook for accelix-ai-plugins.

Checks Edit/Write operations on plugin files for accidental exposure of:
- Team-internal project information (branch names, changeset IDs, server names)
- Personal information (individual names, personal emails, user paths)
- Credentials (API keys, tokens, passwords)

Based on the security-guidance plugin pattern (PreToolUse hook).
"""

import json
import os
import re
import sys

# ---------------------------------------------------------------------------
# Configuration — add patterns as the team discovers new leak vectors
# ---------------------------------------------------------------------------

# Only check files inside the plugins/ directory (plugin content that gets distributed)
WATCH_DIR = "plugins/"

# Patterns that indicate potential information leaks
# Each entry: (compiled_regex, human-readable description)
LEAK_PATTERNS = [
    # --- Windows user paths ---
    (re.compile(r"C:\\Users\\[A-Za-z0-9_]+", re.IGNORECASE),
     "Windows user-specific path detected (e.g., C:\\Users\\username)"),

    # --- Real AccelixGames project names ---
    (re.compile(r"\b(MaidCafe|ProjectMaid|MaidCafeSimulator)\b"),
     "AccelixGames internal project name detected"),

    # --- Real branch names from projects ---
    (re.compile(r"/main/(Alpha\d|MacBuilder|Km-|SB_|BugFix_Alpha)"),
     "Real project branch name detected — use generic placeholders"),

    # --- Personal initials in branch names ---
    (re.compile(r"\b[A-Z]{1,3}[-_][A-Z][a-z]"),
     "Possible personal initials in identifier — review before publishing"),

    # --- Specific changeset IDs > 1000 (likely from real projects) ---
    (re.compile(r"\bcs:([2-9]\d{3,}|[1-9]\d{4,})\b"),
     "High changeset ID likely from a real project — use small placeholder IDs"),

    # --- Personal email patterns (exclude team email) ---
    (re.compile(r"[a-zA-Z0-9._%+-]+@(?!gmail\.com|example\.com)[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"),
     "Non-generic email address detected — verify it's intentionally public"),

    # --- API keys / tokens ---
    (re.compile(r"(api[_-]?key|token|secret|password)\s*[:=]\s*['\"][^'\"]{8,}", re.IGNORECASE),
     "Possible API key or credential detected"),

    # --- Internal server names ---
    (re.compile(r"@(unity|plastic|cloud|internal|corp)\b", re.IGNORECASE),
     "Internal server reference detected — use generic placeholders"),

    # --- IP addresses ---
    (re.compile(r"\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b"),
     "IP address detected — verify it's not an internal address"),
]

# Allowlist — patterns that look like leaks but are intentionally safe
ALLOWLIST = [
    re.compile(r"accelix\.staff@gmail\.com"),        # Official team email
    re.compile(r"user@email\.com"),                   # Placeholder email
    re.compile(r"localhost:8087"),                     # Placeholder server
    re.compile(r"127\.0\.0\.1"),                      # Loopback
    re.compile(r"0\.0\.0\.0"),                        # Wildcard bind
]


def is_allowlisted(match_text: str) -> bool:
    """Check if matched text is in the allowlist."""
    return any(pattern.search(match_text) for pattern in ALLOWLIST)


def check_content(content: str) -> list[tuple[str, str]]:
    """Check content against leak patterns. Returns list of (matched_text, description)."""
    findings = []
    for pattern, description in LEAK_PATTERNS:
        for match in pattern.finditer(content):
            matched_text = match.group(0)
            if not is_allowlisted(matched_text):
                findings.append((matched_text, description))
    return findings


def main():
    """Main hook entry point."""
    try:
        raw_input = sys.stdin.read()
        input_data = json.loads(raw_input)
    except (json.JSONDecodeError, Exception):
        sys.exit(0)  # Allow tool to proceed if we can't parse

    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})

    if tool_name not in ("Edit", "Write"):
        sys.exit(0)

    file_path = tool_input.get("file_path", "")

    # Only check files in the plugins/ directory
    normalized = file_path.replace("\\", "/")
    if WATCH_DIR not in normalized:
        sys.exit(0)

    # Extract content to check
    if tool_name == "Write":
        content = tool_input.get("content", "")
    elif tool_name == "Edit":
        content = tool_input.get("new_string", "")
    else:
        content = ""

    if not content:
        sys.exit(0)

    findings = check_content(content)

    if findings:
        msg_lines = [
            "SECURITY: Potential information leak detected in plugin file.",
            f"File: {file_path}",
            "",
        ]
        for matched_text, description in findings:
            msg_lines.append(f"  - \"{matched_text}\" — {description}")
        msg_lines.append("")
        msg_lines.append("Replace with generic placeholders before publishing.")
        msg_lines.append("If this is intentional, re-apply the edit to proceed.")

        print("\n".join(msg_lines), file=sys.stderr)
        sys.exit(2)  # Block the tool call

    sys.exit(0)


if __name__ == "__main__":
    main()
