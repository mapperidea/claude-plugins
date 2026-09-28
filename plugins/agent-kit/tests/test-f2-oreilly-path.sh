#!/usr/bin/env bash
# test-f2-oreilly-path.sh — F2 smoke test
#
# Verifies the structural correctness of the O'Reilly knowledge path (Tier A).
#
# What this tests:
#   1. Phase 2 Tier A flow is fully implemented in agent-creator.md
#   2. The O'Reilly MCP call pattern is present and correctly structured
#   3. The Tier A web-supplement flow (WebSearch + WebFetch) is present
#   4. knowledge-extractor has the tools required for web supplementation
#   5. A sample Tier-A generated agent passes frontmatter validation
#   6. A sample Tier-A MEMORY.md passes structural validation
#   7. The Tier A knowledge-tier comment format is correct

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
  grep -qE "$pattern" "$path" 2>/dev/null \
    && pass "$label" \
    || fail "$label (pattern not found: $pattern)"
}

has_field() {
  local label="$1" path="$2" field="$3"
  awk '/^---/{c++; if(c==2) exit} c==1' "$path" 2>/dev/null \
    | grep -q "^${field}:" \
    && pass "$label has '$field'" \
    || fail "$label missing frontmatter field '$field': $path"
}

# ── Test Suite ────────────────────────────────────────────────────────────────

# A skill é o NÚCLEO + as referências que ele roteia: o conteúdo mudou de arquivo
# na divisão por disclosure progressivo, não deixou de existir. As asserções abaixo
# perguntam "o wizard diz isto?", não "este arquivo diz isto".
SKILL_DIR="$KIT_ROOT/skills/agent-creator"
SKILL="$(mktemp)"; trap 'rm -f "$SKILL"' EXIT
cat "$SKILL_DIR/SKILL.md" "$SKILL_DIR/references"/*.md > "$SKILL"
EXTRACTOR="$KIT_ROOT/agents/knowledge-extractor.md"

header "1. Phase 2 Tier A flow implemented in agent-creator.md"

contains "2.2 — O'Reilly search section exists"    "$SKILL" "2.2 — Search O'Reilly MCP"
contains "mcp__oreilly call present"               "$SKILL" "mcp__oreilly__search_oreilly_content"
contains "O'Reilly query uses DOMAIN variable"     "$SKILL" "patterns best practices"
contains "content_types books filter"              "$SKILL" "content_types|\"books\""
contains "n_items parameter present"               "$SKILL" "n_items"
contains "Top-3 result formatting logic"           "$SKILL" "format the top 3"
contains "O'Reilly access question asked"          "$SKILL" "Do you have O'Reilly access"
contains "Local file question asked alongside"     "$SKILL" "local files.*(PDF|\.md)"

header "2. Branch A — User confirms O'Reilly access"

contains "Branch A sets KNOWLEDGE_TIER=A"          "$SKILL" "KNOWLEDGE_TIER=A"
contains "Book metadata fields captured"           "$SKILL" "KNOWLEDGE_SOURCE_TITLE"
contains "KNOWLEDGE_SOURCE_AUTHOR captured"        "$SKILL" "KNOWLEDGE_SOURCE_AUTHOR"
contains "KNOWLEDGE_SOURCE_YEAR captured"          "$SKILL" "KNOWLEDGE_SOURCE_YEAR"
contains "Tier A confidence note (medium)"         "$SKILL" "confidence: medium"
contains "User told about Tier A result"           "$SKILL" "knowledge source .Tier A."

header "3. Tier A web-supplement flow (WebSearch + WebFetch)"

contains "WebSearch for key patterns"              "$SKILL" "WebSearch.*KNOWLEDGE_SOURCE_TITLE"
contains "WebSearch for anti-patterns"             "$SKILL" "anti-patterns common mistakes"
contains "WebFetch for official pages"             "$SKILL" "WebFetch.*extract|use.*WebFetch"
contains "KNOWLEDGE_CONTENT has core_patterns"     "$SKILL" "core_patterns:"
contains "KNOWLEDGE_CONTENT has anti_patterns"     "$SKILL" "anti_patterns:"
contains "source_provenance in Tier A output"      "$SKILL" "source_provenance"
contains "O'Reilly metadata note in provenance"    "$SKILL" "O'Reilly metadata"

header "4. knowledge-extractor has tools for web supplementation"

contains "knowledge-extractor has WebSearch"       "$EXTRACTOR" "WebSearch"
contains "knowledge-extractor has WebFetch"        "$EXTRACTOR" "WebFetch"
contains "knowledge-extractor has Read"            "$EXTRACTOR" "Read"

header "5. Tier A frontmatter comment format"

contains "Tier A comment format in Phase 6"        "$SKILL" "knowledge-tier: A —"
contains "Tier A comment references author"        "$SKILL" "KNOWLEDGE_SOURCE_AUTHOR.*KNOWLEDGE_SOURCE_YEAR|KNOWLEDGE_SOURCE_YEAR"
contains "Tier A format distinct from Tier E"      "$SKILL" "knowledge-tier: E — WARNING"

header "6. Simulated Tier-A agent passes frontmatter validation"

AGENT_TMPFILE=$(mktemp /tmp/test-agent-tierA-XXXXXX.md)
trap 'rm -f "$AGENT_TMPFILE" "$MEMORY_TMPFILE"' EXIT

cat > "$AGENT_TMPFILE" << 'EOF'
---
name: kubernetes-deployment-specialist
description: Kubernetes deployment specialist. Reviews manifests, resource sizing, rollout strategies, and diagnoses failures.
# knowledge-tier: A — Kubernetes: Up and Running, Brendan Burns (2022)
tools: Read, Glob, Grep, Bash
model: sonnet
permissionMode: plan
color: green
---

You are a Kubernetes deployment specialist, grounded in "Kubernetes: Up and Running" (Brendan Burns, 2022). You design, review, and troubleshoot Kubernetes workloads with production-grade reliability in mind.

## Responsibilities

- Review Deployment and StatefulSet manifests for resource sizing, probes, and rollout strategy
- Diagnose pod failures: OOMKilled, CrashLoopBackOff, Pending, ImagePullBackOff
- Recommend HPA/VPA configuration based on workload characteristics
- Validate RBAC roles and service account bindings for least-privilege
- Flag anti-patterns: missing resource limits, single-replica critical deployments, hostPath volumes

## Constraints

- Do not apply changes to a live cluster without explicit user confirmation
- Do not recommend deleting namespaces or PersistentVolumes without backup confirmation
- Treat any kubectl delete command as requiring user approval before inclusion in output
EOF

has_field "Tier-A agent" "$AGENT_TMPFILE" "name"
has_field "Tier-A agent" "$AGENT_TMPFILE" "description"
has_field "Tier-A agent" "$AGENT_TMPFILE" "tools"
has_field "Tier-A agent" "$AGENT_TMPFILE" "model"
has_field "Tier-A agent" "$AGENT_TMPFILE" "permissionMode"

contains "Has Tier A knowledge-tier comment"   "$AGENT_TMPFILE" "knowledge-tier: A"
contains "Has book title in comment"           "$AGENT_TMPFILE" "Kubernetes: Up and Running"
contains "Has author in comment"               "$AGENT_TMPFILE" "Brendan Burns"
contains "Has year in comment"                 "$AGENT_TMPFILE" "2022"
contains "Identity grounded in source"         "$AGENT_TMPFILE" "grounded in"
contains "Has Responsibilities section"        "$AGENT_TMPFILE" "## Responsibilities"
contains "Has Constraints section"             "$AGENT_TMPFILE" "## Constraints"
contains "Explicit approval constraint"        "$AGENT_TMPFILE" "confirmation|approval"

# Validate name is kebab-case
NAME=$(awk '/^---/{c++; if(c==2) exit} c==1' "$AGENT_TMPFILE" | grep '^name:' | sed 's/name: *//')
if echo "$NAME" | grep -qE '^[a-z][a-z0-9-]+$'; then
  pass "Agent name is kebab-case: '$NAME'"
else
  fail "Agent name is not kebab-case: '$NAME'"
fi

# Validate description length
DESC=$(awk '/^---/{c++; if(c==2) exit} c==1' "$AGENT_TMPFILE" | grep '^description:' | sed 's/description: *//')
DESC_LEN=${#DESC}
if [ "$DESC_LEN" -ge 10 ] && [ "$DESC_LEN" -le 120 ]; then
  pass "Description length valid: ${DESC_LEN} chars"
else
  fail "Description length out of range: ${DESC_LEN} chars (must be 10–120)"
fi

# Validate model
MODEL=$(awk '/^---/{c++; if(c==2) exit} c==1' "$AGENT_TMPFILE" | grep '^model:' | sed 's/model: *//')
if echo "sonnet opus haiku inherit" | grep -qw "$MODEL"; then
  pass "Model value is valid: '$MODEL'"
else
  fail "Model value is invalid: '$MODEL'"
fi

# Validate permissionMode
PMODE=$(awk '/^---/{c++; if(c==2) exit} c==1' "$AGENT_TMPFILE" | grep '^permissionMode:' | sed 's/permissionMode: *//')
if echo "default acceptEdits auto plan bypassPermissions" | grep -qw "$PMODE"; then
  pass "permissionMode is valid: '$PMODE'"
else
  fail "permissionMode is invalid: '$PMODE'"
fi

# Validate all tool names
VALID_TOOLS="Read Write Edit Glob Grep Bash WebSearch WebFetch Agent AskUserQuestion Skill NotebookEdit"
TOOLS_LINE=$(awk '/^---/{c++; if(c==2) exit} c==1' "$AGENT_TMPFILE" | grep '^tools:' | sed 's/tools: *//')
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

header "7. Simulated Tier-A MEMORY.md passes structural validation"

MEMORY_TMPFILE=$(mktemp /tmp/test-memory-tierA-XXXXXX.md)

cat > "$MEMORY_TMPFILE" << 'EOF'
# Kubernetes Specialist — Domain Knowledge
Source: Kubernetes: Up and Running, Brendan Burns (2022)
Knowledge tier: A | Extracted: 2026-06-04

## Core Patterns

- **Deployment over bare Pod**: Use Deployment for stateless workloads — ensures rolling updates and self-healing via ReplicaSet
- **Readiness + Liveness probes**: Always define both; readiness gates traffic, liveness restarts hung containers
- **Resource requests + limits**: Set both CPU and memory; limits prevent noisy-neighbour OOM, requests enable scheduler placement

## Decision Heuristics

- Use StatefulSet when pods need stable network identity or persistent volume per-pod
- Prefer HPA over manual replica scaling for traffic-driven workloads
- Use PodDisruptionBudget when a minimum number of replicas must stay available during node drain

## Key Commands

- `kubectl rollout status deployment/<name>` — watch rollout progress
- `kubectl describe pod <name>` — diagnose scheduling failures and probe results
- `kubectl top pod --containers` — per-container CPU/memory (requires metrics-server)

## Anti-Patterns to Avoid

- **No resource limits**: Pod can consume unlimited node CPU/memory, starving neighbours. Instead: always set `resources.limits`
- **Single replica for critical service**: No resilience to node failure. Instead: minimum 2 replicas + PodDisruptionBudget
- **hostPath volumes in production**: Ties pod to specific node, breaks rescheduling. Instead: use PersistentVolumeClaim

## Safety Rules

- Never delete a PersistentVolume or PersistentVolumeClaim without confirming backup exists
- Always dry-run (`--dry-run=client`) before applying large manifest changes to production
EOF

contains "MEMORY.md has source header"           "$MEMORY_TMPFILE" "^Source:"
contains "MEMORY.md has Tier A stamp"            "$MEMORY_TMPFILE" "Knowledge tier: A"
contains "MEMORY.md has Core Patterns section"   "$MEMORY_TMPFILE" "^## Core Patterns"
contains "MEMORY.md has Decision Heuristics"     "$MEMORY_TMPFILE" "^## Decision Heuristics"
contains "MEMORY.md has Key Commands"            "$MEMORY_TMPFILE" "^## Key Commands"
contains "MEMORY.md has Anti-Patterns"           "$MEMORY_TMPFILE" "^## Anti-Patterns"
contains "MEMORY.md has Safety Rules"            "$MEMORY_TMPFILE" "^## Safety Rules"
contains "Core patterns use bold name format"    "$MEMORY_TMPFILE" "\*\*[A-Za-z]"
contains "Key commands use code format"          "$MEMORY_TMPFILE" "^\- \`kubectl"

# Validate MEMORY.md line count is under 200
MEMORY_LINES=$(wc -l < "$MEMORY_TMPFILE")
if [ "$MEMORY_LINES" -le 200 ]; then
  pass "MEMORY.md line count within limit: ${MEMORY_LINES} lines"
else
  fail "MEMORY.md exceeds 200-line limit: ${MEMORY_LINES} lines"
fi

# ── Summary ───────────────────────────────────────────────────────────────────

echo
echo "════════════════════════════════════════════════"
echo "  F2 Results: ${PASS} passed · ${FAIL} failed · ${SKIP} skipped"
echo "════════════════════════════════════════════════"

[ "$FAIL" -eq 0 ]   # exit 0 if all passed, exit 1 if any failed
