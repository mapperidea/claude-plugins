#!/usr/bin/env bash
# validate-bash.sh — PreToolUse hook for the Bash tool
#
# Blocks destructive shell command patterns before Claude executes them.
# Receives tool input JSON on stdin from Claude Code's hook system.
#
# Exit 0 = allow the command
# Exit 2 = block the command (stderr is fed back to Claude)
#
# Must be 2, not 1: Claude Code treats any other non-zero exit as a
# NON-blocking error and runs the tool anyway.

set -uo pipefail

# ── Read tool input from stdin ────────────────────────────────────────────────

INPUT=$(cat)

# ── Extract the command string from JSON ──────────────────────────────────────
# Claude Code sends: {"tool_name":"Bash","tool_input":{"command":"..."},...}
# Try jq first; fall back to grep-based extraction (no external deps required).

if command -v jq &>/dev/null 2>&1; then
  COMMAND=$(printf '%s' "$INPUT" | jq -r '
    if .tool_input.command then .tool_input.command
    elif .command then .command
    else ""
    end' 2>/dev/null || true)
else
  # Portable fallback: extract the value of "command": "..." from raw JSON.
  # Handles simple cases; complex multi-line commands may not parse perfectly,
  # but the pattern checks below are conservative enough to stay safe.
  COMMAND=$(printf '%s' "$INPUT" \
    | grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]*"' \
    | head -1 \
    | sed 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)"/\1/')
fi

# If we could not extract a command, allow it (don't block on parse failure).
if [ -z "${COMMAND:-}" ]; then
  exit 0
fi

# ── Helper: block with a clear reason ────────────────────────────────────────

block() {
  local reason="$1"
  printf '\n[validate-bash] BLOCKED: %s\n' "$reason" >&2
  printf 'Command: %s\n\n' "$COMMAND" >&2
  exit 2
}

# ── Pattern checks ────────────────────────────────────────────────────────────
# Each check is a single grep call. Order: most dangerous first.

# 1. Fork bomb
printf '%s' "$COMMAND" | grep -qE ':\(\)\s*\{.*\|.*&.*\}' \
  && block "fork bomb pattern detected"

# 2. Recursive force delete  (rm -rf, rm -fr, rm --force -r, etc.)
printf '%s' "$COMMAND" | grep -qE '(^|[;&|[:space:]])rm\s+[^;]*(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r|--recursive|--force)[^;]*' \
  && block "recursive force delete (rm -rf or equivalent)"

# 3. Writing to block devices
printf '%s' "$COMMAND" | grep -qE '(>|dd\s.*of=)\s*/dev/(sd|hd|nvme|vd|xvd|sda|sdb|loop)[a-z0-9]*' \
  && block "write to block device"

# 4. Disk formatting tools
printf '%s' "$COMMAND" | grep -qE '(^|[;&|[:space:]])(mkfs|mkswap|fdisk|parted|gdisk|wipefs)\s' \
  && block "disk formatting command"

# 5. Destructive DDL (no WHERE / unconditional)
printf '%s' "$COMMAND" | grep -qiE '(^|[;&|[:space:]])(DROP\s+(TABLE|DATABASE|SCHEMA|INDEX|VIEW)|TRUNCATE\s+(TABLE\s+)?\w)' \
  && block "destructive DDL (DROP / TRUNCATE) — use db-analyst agent for schema changes"

# 6. DELETE without WHERE clause
printf '%s' "$COMMAND" | grep -qiE 'DELETE\s+FROM\s+\w' \
  && ! printf '%s' "$COMMAND" | grep -qiE '\bWHERE\b' \
  && block "DELETE without WHERE clause — would delete entire table"

# 7. World-writable permissions
printf '%s' "$COMMAND" | grep -qE 'chmod\s+[0-9]*777|chmod\s+(a|o)\+w' \
  && block "world-writable permission (chmod 777 / o+w)"

# 8. Pipe output directly to a shell interpreter
printf '%s' "$COMMAND" | grep -qE '\|\s*(sudo\s+)?(bash|sh|zsh|dash|ksh|fish)(\s+-[a-z]+)?\s*$' \
  && block "piping output to a shell interpreter (| bash)"

# 9. Git force push to remote
printf '%s' "$COMMAND" | grep -qE 'git\s+push\s+.*--force|git\s+push\s+.*-f(\s|$)' \
  && block "git force push to remote"

# 10. Overwrite /etc system files
printf '%s' "$COMMAND" | grep -qE '>\s*/etc/(passwd|shadow|sudoers|hosts|crontab|ssh/)' \
  && block "overwrite of sensitive /etc system file"

# 11. Fetch and execute remote scripts (curl/wget piped to shell)
printf '%s' "$COMMAND" | grep -qE '(curl|wget)\s+.*\|\s*(sudo\s+)?(bash|sh|zsh|python|ruby|perl)' \
  && block "fetch-and-execute remote script (curl/wget | shell)"

# 12. Privilege escalation via su/sudo to root shell
printf '%s' "$COMMAND" | grep -qE '(^|[;&|[:space:]])(sudo\s+(-i|-s|su)|su\s+-\s*$|sudo\s+bash|sudo\s+sh)' \
  && block "privilege escalation to root shell"

# ── Allow ─────────────────────────────────────────────────────────────────────
exit 0
