#!/usr/bin/env bash
# test-f4-enrich-flow.sh — F4 smoke test
#
# Verifies the structural correctness of the --enrich flow (E1–E7).
#
# What this tests:
#   1. Enrich Flow section exists and all 7 steps (E1–E7) are implemented
#   2. E1: agent file location logic
#   3. E2: existing agent state extraction (tier, source, memory scope, prompt)
#   4. E3: new knowledge source determination (file vs interactive)
#   5. E4: diff format between old and new knowledge
#   6. E5: confirmation gate before any write (yes/no/memory-only)
#   7. E6: apply updates (MEMORY.md, system prompt, frontmatter comment)
#   8. E7: completion message format
#   9. A sample Tier-E agent (to-be-enriched) passes baseline validation
#  10. A simulated post-enrich Tier-B agent passes updated frontmatter validation

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

contains() {
  local label="$1" path="$2" pattern="$3"
  grep -qE -- "$pattern" "$path" 2>/dev/null \
    && pass "$label" \
    || fail "$label (pattern not found: $pattern)"
}

lacks() {
  local label="$1" path="$2" pattern="$3"
  grep -qE -- "$pattern" "$path" 2>/dev/null \
    && fail "$label (forbidden pattern present: $pattern)" \
    || pass "$label"
}

has_field() {
  local label="$1" path="$2" field="$3"
  awk '/^---/{c++; if(c==2) exit} c==1' "$path" 2>/dev/null \
    | grep -q "^${field}:" \
    && pass "$label has '$field'" \
    || fail "$label missing frontmatter field '$field': $path"
}

# ── Temp files ────────────────────────────────────────────────────────────────

TIER_E_AGENT=$(mktemp /tmp/test-enrich-before-XXXXXX.md)
TIER_B_AGENT=$(mktemp /tmp/test-enrich-after-XXXXXX.md)
trap 'rm -f "$TIER_E_AGENT" "$TIER_B_AGENT"' EXIT

# A skill é o NÚCLEO + as referências que ele roteia: o conteúdo mudou de arquivo
# na divisão por disclosure progressivo, não deixou de existir. As asserções abaixo
# perguntam "o wizard diz isto?", não "este arquivo diz isto".
SKILL_DIR="$KIT_ROOT/skills/agent-creator"
SKILL="$(mktemp)"; trap 'rm -f "$SKILL"' EXIT
cat "$SKILL_DIR/SKILL.md" "$SKILL_DIR/references"/*.md > "$SKILL"

# ── Test Suite ────────────────────────────────────────────────────────────────

header "1. Enrich Flow section exists and all steps present"

contains "Enrich Flow section header"       "$SKILL" "Enrich Flow"
contains "E1 — locate agent step"          "$SKILL" "E1 — Locate the existing agent"
contains "E2 — read agent state step"      "$SKILL" "E2 — Read existing agent state"
contains "E3 — determine new source step"  "$SKILL" "E3 — Determine new knowledge source"
contains "E4 — diff step"                  "$SKILL" "E4 — Diff old vs new knowledge"
contains "E5 — confirm step"               "$SKILL" "E5 — Confirm before writing"
contains "E6 — apply updates step"         "$SKILL" "E6 — Apply updates"
contains "E7 — completion message step"    "$SKILL" "E7 — Completion message"
contains "--enrich argument documented"    "$SKILL" "--enrich"
contains "ENRICH_TARGET variable set"      "$SKILL" "ENRICH_TARGET"
contains "ENRICH_FILE variable set"        "$SKILL" "ENRICH_FILE"

header "2. E1 — Agent file location logic"

contains "Searches .claude/agents/ first"      "$SKILL" '\.claude/agents/\[ENRICH_TARGET\]'
contains "Searches ~/.claude/agents/ as fallback" "$SKILL" '~/.claude/agents/\[ENRICH_TARGET\]'
contains "Error message if not found"          "$SKILL" "No agent named.*found"

header "3. E2 — Existing agent state extraction"

contains "EXISTING_TIER extracted"             "$SKILL" "EXISTING_TIER"
contains "EXISTING_SOURCE extracted"           "$SKILL" "EXISTING_SOURCE"
contains "EXISTING_MEMORY_SCOPE extracted"     "$SKILL" "EXISTING_MEMORY_SCOPE"
contains "EXISTING_SYSTEM_PROMPT extracted"    "$SKILL" "EXISTING_SYSTEM_PROMPT"
contains "EXISTING_DOMAIN inferred"            "$SKILL" "EXISTING_DOMAIN"
contains "EXISTING_MEMORY read or set null"    "$SKILL" "EXISTING_MEMORY"
contains "Memory path formula: project scope"  "$SKILL" "agent-memory/\[ENRICH_TARGET\]/MEMORY"
contains "Memory path formula: user scope"     "$SKILL" "~/.claude/agent-memory/\[ENRICH_TARGET\]"

header "4. E3 — New knowledge source determination"

contains "ENRICH_FILE path used if provided"   "$SKILL" "ENRICH_FILE.*was provided|If.*ENRICH_FILE"
contains "File-not-found error message"        "$SKILL" "File not found:.*ENRICH_FILE|File not found.*ENRICH_FILE"
contains "knowledge-extractor invoked for file" "$SKILL" "knowledge-extractor.*ENRICH_FILE|ENRICH_FILE.*knowledge-extractor"
contains "NEW_SOURCE set to filename"           "$SKILL" "NEW_SOURCE"
contains "NEW_TIER set to B for file"           "$SKILL" "NEW_TIER.*B|NEW_TIER = .B."
contains "Interactive prompt if no file"        "$SKILL" "no file was provided"
contains "O'Reilly search option available"     "$SKILL" "Option a.*Tier A|Tier A.*option"
contains "Local file option available"          "$SKILL" "Provide a local file|Option b.*local"
contains "Tier C web refresh option available"  "$SKILL" "Tier C refresh|Option c.*web search"

header "5. E4 — Diff format between old and new knowledge"

contains "Diff header format"                  "$SKILL" "Knowledge diff for \[ENRICH_TARGET\]"
contains "Added entries shown"                 "$SKILL" "Added \(\[N\]\)|Added.*entries"
contains "Updated entries shown"               "$SKILL" "Updated \(\[N\]\)|Updated.*entries"
contains "Removed entries shown"               "$SKILL" "Removed \(\[N\]\)|Removed.*entries"
contains "Unchanged count shown"               "$SKILL" "Unchanged:"
contains "Tier transition shown"               "$SKILL" "Knowledge tier:.*EXISTING_TIER.*NEW_TIER"
contains "New source shown"                    "$SKILL" "New source: \[NEW_SOURCE\]"
contains "No-change exit path"                 "$SKILL" "already up to date"

header "6. E5 — Confirmation gate before any write"

contains "Confirm prompt shown"                "$SKILL" "Apply these changes to \[ENRICH_TARGET\]"
contains "MEMORY.md listed in will-update"     "$SKILL" "MEMORY_FILE_PATH.*MEMORY\.md"
contains "System prompt listed in will-update" "$SKILL" "responsibilities.*identity|system prompt"
contains "Frontmatter comment listed"          "$SKILL" "knowledge-tier comment in frontmatter"
contains "yes option applies all changes"      "$SKILL" "yes.*update MEMORY|yes.*→.*update"
contains "no option exits without changes"     "$SKILL" "no.*exit without|no.*→.*exit"
contains "memory-only option exists"           "$SKILL" "memory-only"
contains "memory-only skips system prompt"     "$SKILL" "memory-only.*system prompt.*untouched|leave system prompt.*untouched"

header "7. E6 — Apply updates"

# Até 2026-09-25 estas asserções exigiam "rebuild" e "Replace the Responsibilities" — e
# era essa a regra errada: num agente tier D as regras do time só existem no MEMORY.md,
# e reconstruir a partir da fonte nova as apagava. O enrich MESCLA; só a mesma fonte
# pode remover o que é dela.
contains "MEMORY.md merged, not rebuilt"          "$SKILL" "Update MEMORY.md.*merge .NEW_KNOWLEDGE. into .EXISTING_MEMORY."
contains "Entries from other sources are kept"    "$SKILL" "keep every entry from other"
contains "Removed only from the same source"      "$SKILL" "Removed.*only when it came from the .*same"
contains "Tier D rule never listed as Removed"    "$SKILL" "Tier D team rule.*never Removed"
contains "Sections labelled with their source"    "$SKILL" "Label each section with its source"
contains "Write to existing path or create"        "$SKILL" "existing path.*create|create if needed"
contains "Identity statement updated"              "$SKILL" "identity statement.*new source|trained on.*new"
contains "Responsibilities merged, others kept"    "$SKILL" "Merge new bullets into the Responsibilities"
lacks "No instruction to replace Responsibilities" "$SKILL" "Replace the Responsibilities"
lacks "No instruction to rebuild MEMORY.md"        "$SKILL" "rebuild from .NEW_KNOWLEDGE."
contains "Constraints section preserved"           "$SKILL" "Keep Constraints"
contains "Frontmatter comment updated"             "$SKILL" "Update frontmatter comment|frontmatter.*replace"
contains "Updated date appended to comment"        "$SKILL" "updated.*today|today.*date"

header "8. E7 — Completion message"

contains "Success message format"             "$SKILL" "enriched successfully"
contains "Updated file paths shown"           "$SKILL" "AGENT_FILE_PATH"
contains "Tier transition in completion"      "$SKILL" "OLD_TIER.*NEW_TIER|Knowledge tier:.*→"
contains "Change counts in completion"        "$SKILL" "added.*updated.*removed"
contains "Invoke example provided"            "$SKILL" 'Invoke to verify|@".*agent"'

header "9. Sample Tier-E agent (pre-enrich) passes baseline validation"

cat > "$TIER_E_AGENT" << 'EOF'
---
name: sql-query-optimizer
description: SQL query optimizer. Analyzes slow queries, recommends indexes, and rewrites inefficient SQL for PostgreSQL and MySQL.
# knowledge-tier: E — WARNING: no authoritative source used. Enrich with /agent-creator --enrich sql-query-optimizer <file>
tools: Read, Bash, Glob
model: sonnet
permissionMode: plan
color: orange
---

You are a SQL query optimizer. You analyze slow queries, suggest indexes, and rewrite inefficient SQL for PostgreSQL and MySQL.

## Responsibilities

- Identify slow queries using EXPLAIN and EXPLAIN ANALYZE output
- Recommend indexes: B-tree, partial, covering, composite
- Rewrite correlated subqueries, N+1 patterns, and cross-join anti-patterns
- Estimate cardinality and flag missing statistics

## Constraints

- Do not run data-modifying SQL (INSERT, UPDATE, DELETE) without explicit user approval
- Do not recommend schema changes without first confirming the database version
- Always use EXPLAIN (not EXPLAIN ANALYZE) on production systems to avoid execution cost
EOF

has_field "Tier-E (pre-enrich)" "$TIER_E_AGENT" "name"
has_field "Tier-E (pre-enrich)" "$TIER_E_AGENT" "description"
has_field "Tier-E (pre-enrich)" "$TIER_E_AGENT" "tools"
has_field "Tier-E (pre-enrich)" "$TIER_E_AGENT" "model"
has_field "Tier-E (pre-enrich)" "$TIER_E_AGENT" "permissionMode"

contains "Has Tier E warning comment"          "$TIER_E_AGENT" "knowledge-tier: E — WARNING"
contains "Enrich hint in Tier E comment"       "$TIER_E_AGENT" "--enrich.*sql-query-optimizer"
contains "Has identity statement"              "$TIER_E_AGENT" "You are a"
contains "Has Responsibilities section"        "$TIER_E_AGENT" "## Responsibilities"
contains "Has Constraints section"             "$TIER_E_AGENT" "## Constraints"

# Validate name
NAME=$(awk '/^---/{c++; if(c==2) exit} c==1' "$TIER_E_AGENT" | grep '^name:' | sed 's/name: *//')
echo "$NAME" | grep -qE '^[a-z][a-z0-9-]+$' \
  && pass "Agent name is kebab-case: '$NAME'" \
  || fail "Agent name is not kebab-case: '$NAME'"

# Validate description length
DESC=$(awk '/^---/{c++; if(c==2) exit} c==1' "$TIER_E_AGENT" | grep '^description:' | sed 's/description: *//')
DESC_LEN=${#DESC}
[ "$DESC_LEN" -ge 10 ] && [ "$DESC_LEN" -le 120 ] \
  && pass "Description length valid: ${DESC_LEN} chars" \
  || fail "Description length out of range: ${DESC_LEN} chars"

header "10. Simulated post-enrich Tier-B agent passes updated validation"

cat > "$TIER_B_AGENT" << 'EOF'
---
name: sql-query-optimizer
description: SQL query optimizer. Analyzes slow queries, recommends indexes, and rewrites inefficient SQL for PostgreSQL and MySQL.
# knowledge-tier: B — user-provided: postgresql-query-tuning.md (updated 2026-06-04)
tools: Read, Bash, Glob
model: sonnet
permissionMode: plan
memory: project
color: orange
---

You are a SQL query optimizer, trained on the team's PostgreSQL query tuning guide (postgresql-query-tuning.md). You analyze slow queries, recommend indexes, and rewrite inefficient SQL following the team's documented patterns and conventions.

## Responsibilities

- Run EXPLAIN ANALYZE and identify seq scans on large tables (>100k rows) as primary optimization targets
- Recommend B-tree indexes for equality/range filters; partial indexes for low-cardinality filtered queries
- Rewrite N+1 patterns using EXISTS or JOIN; convert correlated subqueries to lateral joins
- Check pg_stat_user_tables for bloat: dead_tuple_ratio > 10% warrants VACUUM ANALYZE
- Identify missing statistics: tables not analyzed in > 7 days are unreliable for planner estimates

## Constraints

- Do not run data-modifying SQL (INSERT, UPDATE, DELETE) without explicit user approval
- Do not recommend schema changes without first confirming the database version
- Always use EXPLAIN (not EXPLAIN ANALYZE) on production systems to avoid execution cost
EOF

has_field "Tier-B (post-enrich)" "$TIER_B_AGENT" "name"
has_field "Tier-B (post-enrich)" "$TIER_B_AGENT" "description"
has_field "Tier-B (post-enrich)" "$TIER_B_AGENT" "tools"
has_field "Tier-B (post-enrich)" "$TIER_B_AGENT" "model"
has_field "Tier-B (post-enrich)" "$TIER_B_AGENT" "permissionMode"
has_field "Tier-B (post-enrich)" "$TIER_B_AGENT" "memory"

contains "Tier B comment replaces Tier E"       "$TIER_B_AGENT" "knowledge-tier: B —"
contains "Tier B comment has user-provided"     "$TIER_B_AGENT" "user-provided:"
contains "Tier B comment has source filename"   "$TIER_B_AGENT" "\.md"
contains "Updated date appended to comment"     "$TIER_B_AGENT" "updated [0-9]{4}-[0-9]{2}-[0-9]{2}"
contains "Identity updated with new source"     "$TIER_B_AGENT" "trained on.*guide|guide.*trained on"
contains "Responsibilities enriched from file"  "$TIER_B_AGENT" "pg_stat_user_tables|VACUUM ANALYZE"
contains "Constraints section preserved"        "$TIER_B_AGENT" "Do not run data-modifying SQL"

# Confirm name unchanged after enrich
POST_NAME=$(awk '/^---/{c++; if(c==2) exit} c==1' "$TIER_B_AGENT" | grep '^name:' | sed 's/name: *//')
[ "$POST_NAME" = "$NAME" ] \
  && pass "Agent name unchanged after enrich: '$POST_NAME'" \
  || fail "Agent name changed after enrich: '$POST_NAME' (was '$NAME')"

# ── Summary ───────────────────────────────────────────────────────────────────

echo
echo "════════════════════════════════════════════════"
echo "  F4 Results: ${PASS} passed · ${FAIL} failed · ${SKIP} skipped"
echo "════════════════════════════════════════════════"

[ "$FAIL" -eq 0 ]
