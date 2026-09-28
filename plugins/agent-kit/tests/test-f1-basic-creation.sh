#!/usr/bin/env bash
# test-f1-basic-creation.sh — F1 smoke test
#
# Verifies the prerequisites and structural correctness for a basic
# Tier-E agent creation (no O'Reilly access, no local files).
#
# What this tests:
#   1. All required skill and agent files exist
#   2. All required scripts are executable
#   3. agent-creator.md has all 6 wizard phases implemented
#   4. A sample Tier-E generated agent passes YAML frontmatter validation
#   5. The generated agent is structured correctly (identity, responsibilities, constraints)

set -uo pipefail

KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"   # raiz do plugin agent-kit
PASS=0
FAIL=0
SKIP=0

# ── Helpers ───────────────────────────────────────────────────────────────────

pass() { echo "  PASS  $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL  $1"; FAIL=$((FAIL + 1)); }
skip() { echo "  SKIP  $1 — $2"; SKIP=$((SKIP + 1)); }
header() { echo; echo "── $1 ──────────────────────────────────────────"; }

# Check a file exists
exists() {
  local label="$1" path="$2"
  [ -f "$path" ] && pass "$label exists" || fail "$label missing: $path"
}

# Check a file is executable
executable() {
  local label="$1" path="$2"
  [ -x "$path" ] && pass "$label is executable" || fail "$label not executable: $path"
}

# Check a file contains a string
contains() {
  local label="$1" path="$2" pattern="$3"
  grep -q "$pattern" "$path" 2>/dev/null \
    && pass "$label" \
    || fail "$label (pattern not found: $pattern)"
}

# Check YAML frontmatter field is present in a .md file
has_field() {
  local label="$1" path="$2" field="$3"
  # Extract content between first --- and second ---
  awk '/^---/{c++; if(c==2) exit} c==1' "$path" 2>/dev/null \
    | grep -q "^${field}:" \
    && pass "$label has '$field'" \
    || fail "$label missing frontmatter field '$field': $path"
}

# ── Test Suite ────────────────────────────────────────────────────────────────

header "1. Required files exist"

exists "agent-creator skill"          "$KIT_ROOT/skills/agent-creator/SKILL.md"
exists "agent-creator-helpers"        "$KIT_ROOT/skills/agent-creator/references/helpers.md"
exists "knowledge-extractor agent"    "$KIT_ROOT/agents/knowledge-extractor.md"
exists "validate-bash.sh"             "$KIT_ROOT/scripts/validate-bash.sh"
exists "check-write-path.sh"          "$KIT_ROOT/scripts/check-write-path.sh"

header "2. Scripts are executable"

executable "validate-bash.sh"         "$KIT_ROOT/scripts/validate-bash.sh"
executable "check-write-path.sh"      "$KIT_ROOT/scripts/check-write-path.sh"

header "3. agent-creator.md has all phases"

# A skill é o NÚCLEO + as referências que ele roteia: o conteúdo mudou de arquivo
# na divisão por disclosure progressivo, não deixou de existir. As asserções abaixo
# perguntam "o wizard diz isto?", não "este arquivo diz isto".
SKILL_DIR="$KIT_ROOT/skills/agent-creator"
SKILL="$(mktemp)"; trap 'rm -f "$SKILL"' EXIT
cat "$SKILL_DIR/SKILL.md" "$SKILL_DIR/references"/*.md > "$SKILL"
contains "Phase 1 (Discovery)"        "$SKILL" "Phase 1 — Discovery"
contains "Phase 2 (Knowledge)"        "$SKILL" "Phase 2 — Knowledge Discovery"
contains "Phase 3 (Architecture)"     "$SKILL" "Phase 3 — Architecture Recommendation"
contains "Phase 4 (Behavior)"         "$SKILL" "Phase 4 — Behavior Design"
contains "Phase 4O (Orchestrator)"    "$SKILL" "Phase 4O — Orchestrator Behavior Design"
contains "Phase 5 (Configuration)"    "$SKILL" "Phase 5 — Configuration"
contains "Phase 6 (Generation)"       "$SKILL" "Phase 6 — Generation, Validation, and Write"
contains "Enrich flow"                "$SKILL" "Enrich Flow"
contains "Knowledge-source flow"      "$SKILL" "Knowledge Search Flow"

header "4. agent-creator.md references helpers correctly"

contains "Reads helpers at startup"   "$SKILL" "agent-creator-helpers.md"
contains "References knowledge-extractor" "$SKILL" "knowledge-extractor"
contains "References O'Reilly MCP"    "$SKILL" "mcp__oreilly__search_oreilly_content"
contains "Tier A–E logic"             "$SKILL" "KNOWLEDGE_TIER"

header "5. Simulate Tier-E agent generation and validate output"

# Generate a minimal valid Tier-E agent file (what Phase 6 would write)
TMPFILE=$(mktemp /tmp/test-agent-XXXXXX.md)
trap 'rm -f "$TMPFILE"' EXIT

cat > "$TMPFILE" << 'EOF'
---
name: readonly-code-reviewer
description: Read-only code reviewer. Use for quick code quality checks, naming, and logic error detection.
# knowledge-tier: E — WARNING: no authoritative source used. Enrich with /agent-creator --enrich readonly-code-reviewer <file>
tools: Read, Glob, Grep
model: sonnet
permissionMode: default
color: blue
---

You are a read-only code reviewer. You analyze code for quality, correctness, and clarity without modifying any files.

## Responsibilities

- Identify logic errors and incorrect conditionals
- Flag poor naming that obscures intent
- Note missing error handling and uncaught edge cases
- Surface security smells (unsanitized input, hardcoded credentials)

## Constraints

- Do not create, modify, or delete any file
- Do not run shell commands or execute code
- Do not rewrite code for the author — describe what needs to change and why
EOF

# Validate the generated file
has_field "Generated agent" "$TMPFILE" "name"
has_field "Generated agent" "$TMPFILE" "description"
has_field "Generated agent" "$TMPFILE" "tools"
has_field "Generated agent" "$TMPFILE" "model"
has_field "Generated agent" "$TMPFILE" "permissionMode"

contains "Has knowledge-tier comment"   "$TMPFILE" "knowledge-tier:"
contains "Has Tier E warning"           "$TMPFILE" "knowledge-tier: E"
contains "Has identity statement"       "$TMPFILE" "You are a"
contains "Has Responsibilities section" "$TMPFILE" "## Responsibilities"
contains "Has Constraints section"      "$TMPFILE" "## Constraints"
contains "Read-only constraint present" "$TMPFILE" "Do not create, modify, or delete"

# Validate name is kebab-case
NAME=$(awk '/^---/{c++; if(c==2) exit} c==1' "$TMPFILE" | grep '^name:' | sed 's/name: *//')
if echo "$NAME" | grep -qE '^[a-z][a-z0-9-]+$'; then
  pass "Agent name is kebab-case: '$NAME'"
else
  fail "Agent name is not kebab-case: '$NAME'"
fi

# Validate description length
DESC=$(awk '/^---/{c++; if(c==2) exit} c==1' "$TMPFILE" | grep '^description:' | sed 's/description: *//')
DESC_LEN=${#DESC}
if [ "$DESC_LEN" -ge 10 ] && [ "$DESC_LEN" -le 120 ]; then
  pass "Description length valid: ${DESC_LEN} chars"
else
  fail "Description length out of range: ${DESC_LEN} chars (must be 10–120)"
fi

# Validate all tool names are in the known-valid list
VALID_TOOLS="Read Write Edit Glob Grep Bash WebSearch WebFetch Agent AskUserQuestion Skill NotebookEdit"
TOOLS_LINE=$(awk '/^---/{c++; if(c==2) exit} c==1' "$TMPFILE" | grep '^tools:' | sed 's/tools: *//')
INVALID=""
IFS=', ' read -ra TOOL_ARRAY <<< "$TOOLS_LINE"
for tool in "${TOOL_ARRAY[@]}"; do
  tool=$(echo "$tool" | tr -d ' ,')
  [ -z "$tool" ] && continue
  if ! echo "$VALID_TOOLS" | grep -qw "$tool"; then
    INVALID="$INVALID $tool"
  fi
done
if [ -z "$INVALID" ]; then
  pass "All tool names are valid: $TOOLS_LINE"
else
  fail "Invalid tool names found:$INVALID"
fi

# Validate model value
MODEL=$(awk '/^---/{c++; if(c==2) exit} c==1' "$TMPFILE" | grep '^model:' | sed 's/model: *//')
if echo "sonnet opus haiku inherit" | grep -qw "$MODEL"; then
  pass "Model value is valid: '$MODEL'"
else
  fail "Model value is invalid: '$MODEL'"
fi

# Validate permissionMode value
PMODE=$(awk '/^---/{c++; if(c==2) exit} c==1' "$TMPFILE" | grep '^permissionMode:' | sed 's/permissionMode: *//')
if echo "default acceptEdits auto plan bypassPermissions" | grep -qw "$PMODE"; then
  pass "permissionMode is valid: '$PMODE'"
else
  fail "permissionMode is invalid: '$PMODE'"
fi

header "6. All template agents exist"

TEMPLATES=(
  "code-reviewer" "researcher" "refactorer" "tester" "documenter"
  "db-analyst" "devops" "security-auditor" "architect" "data-scientist"
  "dev-orchestrator"
)
for t in "${TEMPLATES[@]}"; do
  exists "Template: $t" "$KIT_ROOT/templates/$t.md"
done

header "7. Template agents have required frontmatter fields"

for t in "${TEMPLATES[@]}"; do
  TFILE="$KIT_ROOT/templates/$t.md"
  [ -f "$TFILE" ] || continue
  has_field "$t" "$TFILE" "name"
  has_field "$t" "$TFILE" "description"
  has_field "$t" "$TFILE" "model"
  has_field "$t" "$TFILE" "permissionMode"
done

# ── Summary ───────────────────────────────────────────────────────────────────

echo
echo "════════════════════════════════════════════════"
echo "  F1 Results: ${PASS} passed · ${FAIL} failed · ${SKIP} skipped"
echo "════════════════════════════════════════════════"

[ "$FAIL" -eq 0 ]   # exit 0 if all passed, exit 1 if any failed
