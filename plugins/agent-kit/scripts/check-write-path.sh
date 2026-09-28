#!/usr/bin/env bash
# check-write-path.sh — PreToolUse hook for Write and Edit tools
#
# Blocks file writes that target paths outside the project directory.
# Protects against path traversal attacks and accidental writes to
# system files, home directory dotfiles, or other sensitive locations.
#
# Receives tool input JSON on stdin from Claude Code's hook system.
#
# Exit 0 = allow the write
# Exit 2 = block the write (stderr is fed back to Claude)
#
# Must be 2, not 1: Claude Code treats any other non-zero exit as a
# NON-blocking error and runs the tool anyway.

set -uo pipefail

# ── Read tool input from stdin ────────────────────────────────────────────────

INPUT=$(cat)

# ── Extract file path from JSON ───────────────────────────────────────────────
# Write tool sends: {"tool_name":"Write","tool_input":{"file_path":"..."},...}
# Edit tool sends:  {"tool_name":"Edit","tool_input":{"file_path":"..."},...}

if command -v jq &>/dev/null 2>&1; then
  FILE_PATH=$(printf '%s' "$INPUT" | jq -r '
    if .tool_input.file_path then .tool_input.file_path
    elif .file_path then .file_path
    else ""
    end' 2>/dev/null || true)
else
  FILE_PATH=$(printf '%s' "$INPUT" \
    | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' \
    | head -1 \
    | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"\(.*\)"/\1/')
fi

# If we could not extract a path, allow it (don't block on parse failure).
if [ -z "${FILE_PATH:-}" ]; then
  exit 0
fi

# ── Resolve project root ──────────────────────────────────────────────────────
# Use the directory this script lives in's parent as the project root,
# falling back to the current working directory if resolution fails.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── Helper ────────────────────────────────────────────────────────────────────

block() {
  local reason="$1"
  printf '\n[check-write-path] BLOCKED: %s\n' "$reason" >&2
  printf 'Path:         %s\n' "$FILE_PATH" >&2
  printf 'Project root: %s\n\n' "$PROJECT_ROOT" >&2
  exit 2
}

# ── Check 1: block raw path traversal sequences ───────────────────────────────
# Catches "../" anywhere in the path before resolution.

printf '%s' "$FILE_PATH" | grep -qE '(^|/)\.\.(/|$)' \
  && block "path traversal sequence (..) is not allowed"

# ── Check 2: resolve the absolute path and compare against project root ───────

# Resolve the path: if relative, treat it as relative to project root.
if printf '%s' "$FILE_PATH" | grep -q '^/'; then
  RESOLVED="$FILE_PATH"
else
  RESOLVED="$PROJECT_ROOT/$FILE_PATH"
fi

# Normalize: collapse redundant slashes and . components without following symlinks.
# We use Python if available for reliable normalization, otherwise use a shell approach.
if command -v python3 &>/dev/null 2>&1; then
  NORMALIZED=$(python3 -c "import os.path; print(os.path.normpath('$RESOLVED'))" 2>/dev/null || echo "$RESOLVED")
elif command -v python &>/dev/null 2>&1; then
  NORMALIZED=$(python -c "import os.path; print(os.path.normpath('$RESOLVED'))" 2>/dev/null || echo "$RESOLVED")
else
  # Shell fallback: strip redundant slashes only.
  NORMALIZED=$(printf '%s' "$RESOLVED" | sed 's|/\+|/|g')
fi

# Ensure the resolved path starts with the project root.
case "$NORMALIZED" in
  "$PROJECT_ROOT"/*)
    # Path is inside the project root — allow.
    ;;
  "$PROJECT_ROOT")
    # Path IS the project root directory itself — block writing to it directly.
    block "cannot write directly to the project root directory"
    ;;
  *)
    block "path is outside the project directory"
    ;;
esac

# ── Check 3: block writes to known sensitive absolute paths ───────────────────
# These are caught by Check 2 for absolute paths, but listed explicitly
# for clarity and to catch any normalization edge cases.

case "$NORMALIZED" in
  /etc/passwd|/etc/shadow|/etc/sudoers|/etc/hosts|/etc/crontab)
    block "write to sensitive system file" ;;
  /etc/ssh/*)
    block "write to SSH configuration" ;;
  ~/.ssh/*)
    block "write to SSH directory" ;;
  ~/.bashrc|~/.zshrc|~/.profile|~/.bash_profile)
    block "write to shell initialization file" ;;
esac

# ── Check 4: block writes to .git internals ───────────────────────────────────
# Writing to .git/ directly can corrupt the repository.

printf '%s' "$NORMALIZED" | grep -qE '(^|/)\.git/' \
  && block "write to .git directory internals is not allowed"

# ── Allow ─────────────────────────────────────────────────────────────────────
exit 0
