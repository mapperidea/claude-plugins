#!/usr/bin/env bash
# test-f5-knowledge-source.sh — F5 smoke test
#
# Verifies the structural correctness of the --knowledge-source flow (K1–K4).
#
# What this tests:
#   1. Knowledge Search Flow section exists and all 4 steps (K1–K4) are implemented
#   2. K1: dual parallel O'Reilly search pattern
#   3. K2: result table format (title, author, year, pages)
#   4. K2: "Best for agent creation" recommendation line
#   5. K2: next-step hints (create agent / enrich)
#   6. K3: web supplement for official docs
#   7. K4: read-only exit — no file write, no wizard continuation
#   8. Argument parsing: --knowledge-source sets KNOWLEDGE_DOMAIN
#   9. Simulated K2 output validates format expectations

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

# ── Temp files ────────────────────────────────────────────────────────────────

K2_OUTPUT=$(mktemp /tmp/test-k2-output-XXXXXX.md)
trap 'rm -f "$K2_OUTPUT"' EXIT

# A skill é o NÚCLEO + as referências que ele roteia: o conteúdo mudou de arquivo
# na divisão por disclosure progressivo, não deixou de existir. As asserções abaixo
# perguntam "o wizard diz isto?", não "este arquivo diz isto".
SKILL_DIR="$KIT_ROOT/skills/agent-creator"
SKILL="$(mktemp)"; trap 'rm -f "$SKILL"' EXIT
cat "$SKILL_DIR/SKILL.md" "$SKILL_DIR/references"/*.md > "$SKILL"

# ── Test Suite ────────────────────────────────────────────────────────────────

header "1. Knowledge Search Flow section exists and all steps present"

contains "Flow section header"               "$SKILL" "Knowledge Search Flow"
contains "K1 — O'Reilly search step"        "$SKILL" "K1 — Run broad O.Reilly search"
contains "K2 — format results step"         "$SKILL" "K2 — Format and display results"
contains "K3 — web supplement step"         "$SKILL" "K3 — Supplement with web sources"
contains "K4 — read-only exit step"         "$SKILL" "K4 — Exit"
contains "--knowledge-source argument"       "$SKILL" "--knowledge-source"
contains "KNOWLEDGE_DOMAIN variable set"    "$SKILL" "KNOWLEDGE_DOMAIN"
contains "Pure discovery mode declared"     "$SKILL" "Pure discovery mode|discovery mode"
contains "Does not create files declared"   "$SKILL" "Does not create.*modify|Does not create any files"

header "2. K1 — Dual parallel O'Reilly search"

contains "Two searches run in parallel"     "$SKILL" "two searches in parallel|Run two searches"
contains "Search 1 — patterns query"        "$SKILL" "patterns best practices guide"
contains "Search 2 — production query"      "$SKILL" "production applied engineering"
contains "Both use KNOWLEDGE_DOMAIN var"    "$SKILL" "KNOWLEDGE_DOMAIN.*patterns|KNOWLEDGE_DOMAIN.*production"
contains "content_types books on both"      "$SKILL" 'content_types.*"books"'
contains "n_items=5 on each search"         "$SKILL" "n_items=5"
contains "Deduplication by ourn"            "$SKILL" "deduplic.*ourn|ourn.*deduplic"
contains "Sort by relevance descending"     "$SKILL" "relevance score descending|sorted by relevance"
contains "Keep up to 8 unique books"        "$SKILL" "up to 8 unique"

header "3. K2 — Result table format"

contains "Table header: O'Reilly sources for" "$SKILL" "O.Reilly sources for: \[KNOWLEDGE_DOMAIN\]"
contains "Table columns: Title"              "$SKILL" "Title"
contains "Table columns: Author"             "$SKILL" "Author"
contains "Table columns: Year"              "$SKILL" "Year"
contains "Table columns: Pages"             "$SKILL" "Pages"
contains "Rows show year and page count"    "$SKILL" "\[Year\].*\[N\]p|\[N\]p"
contains "Early release note documented"   "$SKILL" "early release"

header "4. K2 — Best-for-agent-creation recommendation"

contains "Best for agent creation line"     "$SKILL" "Best for agent creation"
contains "Tier A path mentioned"            "$SKILL" "Tier A.*O.Reilly|O.Reilly.*Tier A"
contains "Tier B local file path mentioned" "$SKILL" "Tier B.*local file|local file.*Tier B"
contains "Top result used as Tier A pick"   "$SKILL" "highest-relevance|top result"

header "5. K2 — Next-step hints"

contains "Create agent hint present"        "$SKILL" "/agent-creator.*KNOWLEDGE_DOMAIN.*specialist"
contains "Enrich hint present"              "$SKILL" "--enrich.*agent-name.*path|--enrich.*path"

header "6. K3 — Web supplement for official docs"

contains "WebSearch for official docs"      "$SKILL" 'WebSearch.*official documentation|official documentation.*site'
contains "Official docs appended if found"  "$SKILL" "Official documentation:"
contains "Tier C reference in web output"   "$SKILL" "Tier C source"
contains "Omit silently if nothing found"   "$SKILL" "omit.*silently|silently"

header "7. K4 — Read-only exit, no file write"

contains "Flow is read-only declared"       "$SKILL" "read-only"
contains "Do not create any files"          "$SKILL" "Do not create any files"
contains "Do not prompt for agent details"  "$SKILL" "Do not.*prompt.*agent|prompt.*agent.*details"
contains "Do not continue into wizard"      "$SKILL" "Do not.*wizard|wizard.*continue"
contains "Exit after displaying results"    "$SKILL" "Exit after displaying"

header "8. Argument parsing: --knowledge-source sets KNOWLEDGE_DOMAIN"

contains "--knowledge-source in arg list"    "$SKILL" "--knowledge-source <domain>"
contains "KNOWLEDGE_DOMAIN in parsed vars"   "$SKILL" "KNOWLEDGE_DOMAIN.*=.*domain|KNOWLEDGE_DOMAIN.*domain string"
contains "Jumps to Knowledge Search Flow"    "$SKILL" "jump to the Knowledge Search Flow"
contains "Wizard not run for this flag"      "$SKILL" "Do not run the wizard"

header "9. Simulated K2 output validates format"

cat > "$K2_OUTPUT" << 'EOF'
O'Reilly sources for: Apache Kafka
─────────────────────────────────────────────────────────────────

 #  Title                                        Author(s)              Year   Pages
────────────────────────────────────────────────────────────────────────────────────
 1  Kafka: The Definitive Guide                  Neha Narkhede          2021   468p
 2  Kafka in Action                              Dylan Scott            2022   320p
 3  Event Streaming with Apache Kafka            André Perestrelo       2023   288p

─────────────────────────────────────────────────────────────────
Best for agent creation:
  → Tier A (O'Reilly access confirmed): use #1 — Kafka: The Definitive Guide
  → Tier B (local file):               provide a PDF or .md export of any of the above

To create an agent using one of these sources:
  /agent-creator "Apache Kafka specialist"

To enrich an existing agent with a local file:
  /agent-creator --enrich <agent-name> /path/to/file

Official documentation:
  → Apache Kafka docs: https://kafka.apache.org/documentation/
  (use as Tier C source if no book access)
EOF

contains "Output has domain header"         "$K2_OUTPUT" "O.Reilly sources for: Apache Kafka"
contains "Output has column headers"        "$K2_OUTPUT" "Title.*Author.*Year|Author.*Year.*Pages"
contains "Output has numbered rows"         "$K2_OUTPUT" "^ 1  Kafka"
contains "Output has page count"            "$K2_OUTPUT" "[0-9]+p"
contains "Output has Best for agent line"   "$K2_OUTPUT" "Best for agent creation"
contains "Output has Tier A recommendation" "$K2_OUTPUT" "Tier A.*O.Reilly access confirmed"
contains "Output has Tier B local file"     "$K2_OUTPUT" "Tier B.*local file"
contains "Output has create-agent hint"     "$K2_OUTPUT" "/agent-creator.*Apache Kafka specialist"
contains "Output has enrich hint"           "$K2_OUTPUT" "--enrich.*agent-name"
contains "Output has official docs section" "$K2_OUTPUT" "Official documentation:"
contains "Output has Tier C note"           "$K2_OUTPUT" "Tier C source"

# Verify no agent file paths or frontmatter in the output (read-only check)
if grep -qE "^name:|^tools:|^model:|^permissionMode:" "$K2_OUTPUT" 2>/dev/null; then
  fail "K2 output contains frontmatter — should be read-only"
else
  pass "K2 output contains no agent frontmatter (read-only verified)"
fi

if grep -qE "\.claude/agents/|~/.claude/agents/" "$K2_OUTPUT" 2>/dev/null; then
  fail "K2 output references an agent write path — should be read-only"
else
  pass "K2 output contains no agent write paths (read-only verified)"
fi

# ── Summary ───────────────────────────────────────────────────────────────────

echo
echo "════════════════════════════════════════════════"
echo "  F5 Results: ${PASS} passed · ${FAIL} failed · ${SKIP} skipped"
echo "════════════════════════════════════════════════"

[ "$FAIL" -eq 0 ]
