#!/usr/bin/env bash
# test-f3-local-file-path.sh — F3 smoke test
#
# Verifies the structural correctness of the local file knowledge path (Tier B).
#
# What this tests:
#   1. Tier B flow is fully implemented in agent-creator.md
#   2. knowledge-extractor agent has the correct YAML output schema
#   3. A sample .md knowledge file is structurally valid (parseable)
#   4. Simulated knowledge-extractor YAML output validates against the schema
#   5. A simulated Tier-B agent passes frontmatter validation
#   6. MEMORY.md write path formula matches spec (project/user scope)
#   7. The Tier B knowledge-tier comment format is correct

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

has_field() {
  local label="$1" path="$2" field="$3"
  awk '/^---/{c++; if(c==2) exit} c==1' "$path" 2>/dev/null \
    | grep -q "^${field}:" \
    && pass "$label has '$field'" \
    || fail "$label missing frontmatter field '$field': $path"
}

yaml_field() {
  local label="$1" path="$2" field="$3"
  grep -q "^  ${field}:" "$path" 2>/dev/null \
    && pass "$label has YAML field '${field}'" \
    || fail "$label missing YAML field '${field}': $path"
}

# ── Temp file setup ───────────────────────────────────────────────────────────

KNOWLEDGE_MD=$(mktemp /tmp/test-knowledge-XXXXXX.md)
EXTRACTED_YAML=$(mktemp /tmp/test-extracted-XXXXXX.yaml)
AGENT_TMPFILE=$(mktemp /tmp/test-agent-tierB-XXXXXX.md)
MEMORY_TMPFILE=$(mktemp /tmp/test-memory-tierB-XXXXXX.md)
trap 'rm -f "$KNOWLEDGE_MD" "$EXTRACTED_YAML" "$AGENT_TMPFILE" "$MEMORY_TMPFILE"' EXIT

# A skill é o NÚCLEO + as referências que ele roteia: o conteúdo mudou de arquivo
# na divisão por disclosure progressivo, não deixou de existir. As asserções abaixo
# perguntam "o wizard diz isto?", não "este arquivo diz isto".
SKILL_DIR="$KIT_ROOT/skills/agent-creator"
SKILL="$(mktemp)"; trap 'rm -f "$SKILL"' EXIT
cat "$SKILL_DIR/SKILL.md" "$SKILL_DIR/references"/*.md > "$SKILL"
EXTRACTOR="$KIT_ROOT/agents/knowledge-extractor.md"

# ── Test Suite ────────────────────────────────────────────────────────────────

header "1. Tier B (local file) flow in agent-creator.md"

contains "Branch B section exists"               "$SKILL" "Branch B — User provides a local file"
contains "knowledge-extractor invocation syntax" "$SKILL" '@"knowledge-extractor \(agent\)"'
contains "FILE_PATH variable used in invocation" "$SKILL" "FILE_PATH.*for a.*specialist"
contains "KNOWLEDGE_TIER=B is set"               "$SKILL" "KNOWLEDGE_TIER=B"
contains "KNOWLEDGE_SOURCE_TITLE set to filename" "$SKILL" "KNOWLEDGE_SOURCE_TITLE.*filename"
contains "Multiple file merge logic present"     "$SKILL" "multiple files.*invoke|invoke.*each"
contains "User feedback message (Tier B)"        "$SKILL" "Extracted domain knowledge.*Tier B"
contains "Tier A wins when both sources given"   "$SKILL" "KNOWLEDGE_TIER=A.*higher tier wins|higher tier wins"

header "2. knowledge-extractor agent — output schema"

contains "schema has source_provenance"          "$EXTRACTOR" "source_provenance"
contains "schema has core_patterns"              "$EXTRACTOR" "core_patterns"
contains "schema has anti_patterns"              "$EXTRACTOR" "anti_patterns"
contains "schema has key_commands"               "$EXTRACTOR" "key_commands"
contains "schema has decision_heuristics"        "$EXTRACTOR" "decision_heuristics"
contains "schema has common_failures"            "$EXTRACTOR" "common_failures"
contains "schema has safety_rules"               "$EXTRACTOR" "safety_rules"
contains "schema has confidence field"           "$EXTRACTOR" "confidence"
contains "confidence levels documented"          "$EXTRACTOR" "high.*medium.*low|medium.*low"
contains "no-preamble rule present"              "$EXTRACTOR" "No prose before or after|no.*preamble|preamble"
contains "no-hallucination rule present"         "$EXTRACTOR" "not.*in the source|not present in the source"

header "3. Sample .md knowledge file is structurally valid"

cat > "$KNOWLEDGE_MD" << 'EOF'
# Platform Engineering Runbook
Author: SRE Team | Version: 2.1 | Updated: 2026-05

## Golden Path

The golden path is the opinionated, pre-approved deployment workflow for new services.
All new services must follow the golden path unless an explicit exception is approved.

### When to use the golden path

- All net-new microservices targeting production
- Services that need observability, secrets management, and auto-scaling out of the box

### Golden path components

- Terraform module: `modules/service` — provisions ECS task + ALB target group + IAM role
- Service template: `cookiecutter-service` — FastAPI skeleton with health endpoint and structured logging
- Required tags: `team`, `env`, `service-name`, `cost-center`

## Incident Response

### Severity levels

| Level | Response time | Definition |
|-------|--------------|------------|
| SEV1  | 5 min        | Full production outage or data loss |
| SEV2  | 15 min       | Degraded performance affecting >10% of users |
| SEV3  | 60 min       | Non-critical feature broken |

### Runbook steps for high error rate

1. Check dashboards: Datadog → Services → `<service>` → Error Rate
2. `kubectl logs -l app=<service> --since=10m | grep ERROR | tail -50`
3. Check recent deploys: `argocd app history <service>`
4. Roll back if last deploy < 30 min ago: `argocd app rollback <service>`
5. Page on-call if not resolved in 15 min

## Anti-Patterns

### Manual IAM role creation

**Problem**: Hand-crafted IAM roles are not tracked in Terraform, drift from policy, and cannot be audited.
**Instead**: Always use the `modules/iam-role` Terraform module; submit a PR for review.

### Skipping health checks

**Problem**: Services without health checks cause ALB to route traffic to unhealthy instances.
**Instead**: All services must expose `GET /health` returning `{"status": "ok"}` within 200ms.

## Safety Rules

- Never delete a production RDS instance without a verified snapshot less than 24h old
- Never push secrets to Git — use AWS Secrets Manager via `aws secretsmanager get-secret-value`
- Always test Terraform plans with `terraform plan -out=tfplan` before `terraform apply`
EOF

# Verify the file is non-empty and has expected sections
contains "Knowledge file has title"          "$KNOWLEDGE_MD" "^# Platform Engineering"
contains "Knowledge file has ## sections"    "$KNOWLEDGE_MD" "^## "
contains "Knowledge file has commands"       "$KNOWLEDGE_MD" "kubectl|terraform|argocd"
contains "Knowledge file has anti-patterns"  "$KNOWLEDGE_MD" "Anti-Pattern"
contains "Knowledge file has safety rules"   "$KNOWLEDGE_MD" "Safety Rules|safety rules"

# Validate line count is within knowledge-extractor's ≤300 line threshold
KM_LINES=$(wc -l < "$KNOWLEDGE_MD")
if [ "$KM_LINES" -le 300 ]; then
  pass "Knowledge file within 300-line full-read threshold: ${KM_LINES} lines"
else
  skip "Knowledge file exceeds 300 lines (${KM_LINES}) — extractor will navigate by headings" "expected for large docs"
fi

header "4. Simulated knowledge-extractor YAML output validates"

cat > "$EXTRACTED_YAML" << 'EOF'
knowledge:
  source_provenance:
    title: "Platform Engineering Runbook"
    author: "SRE Team"
    year: "2026"
    source_type: "runbook"
    file_or_url: "/path/to/platform-runbook.md"

  core_patterns:
    - name: "Golden Path Deployment"
      when_to_use: "All net-new microservices targeting production"
      example: "Use modules/service Terraform module + cookiecutter-service template"

  anti_patterns:
    - name: "Manual IAM role creation"
      problem: "Hand-crafted IAM roles drift from policy and cannot be audited"
      instead: "Use modules/iam-role Terraform module; submit a PR for review"
    - name: "Skipping health checks"
      problem: "Services without health checks cause ALB to route to unhealthy instances"
      instead: "All services must expose GET /health returning {status: ok} within 200ms"

  key_commands:
    - "kubectl logs -l app=<service> --since=10m | grep ERROR | tail -50"
    - "argocd app history <service>"
    - "argocd app rollback <service>"
    - "terraform plan -out=tfplan"
    - "aws secretsmanager get-secret-value --secret-id <name>"

  decision_heuristics:
    - "Roll back if last deploy was less than 30 minutes ago and error rate is elevated"
    - "Page on-call if incident is not resolved within 15 minutes of detection"
    - "Use SEV1 when there is full production outage or data loss"

  common_failures:
    - symptom: "High error rate on a service"
      diagnosis: "Check Datadog error rate dashboard; inspect recent deploys in ArgoCD"
      fix: "Run argocd app rollback <service> if last deploy is recent"

  safety_rules:
    - "Never delete a production RDS instance without a verified snapshot less than 24h old"
    - "Never push secrets to Git — use AWS Secrets Manager"
    - "Always run terraform plan before terraform apply"

  confidence: "medium"
EOF

yaml_field "Extracted YAML" "$EXTRACTED_YAML" "source_provenance"
yaml_field "Extracted YAML" "$EXTRACTED_YAML" "core_patterns"
yaml_field "Extracted YAML" "$EXTRACTED_YAML" "anti_patterns"
yaml_field "Extracted YAML" "$EXTRACTED_YAML" "key_commands"
yaml_field "Extracted YAML" "$EXTRACTED_YAML" "decision_heuristics"
yaml_field "Extracted YAML" "$EXTRACTED_YAML" "common_failures"
yaml_field "Extracted YAML" "$EXTRACTED_YAML" "safety_rules"

contains "Extracted YAML has confidence"     "$EXTRACTED_YAML" "confidence:"
contains "Confidence is high/medium/low"     "$EXTRACTED_YAML" "confidence: \"(high|medium|low)\""
contains "source_type is runbook"            "$EXTRACTED_YAML" "source_type:.*runbook"
contains "file_or_url is populated"         "$EXTRACTED_YAML" "file_or_url:"
contains "At least one core pattern"        "$EXTRACTED_YAML" "- name:"
contains "At least one key command"         "$EXTRACTED_YAML" "- \"(kubectl|terraform|argocd|aws)"
contains "At least one safety rule"        "$EXTRACTED_YAML" "- \"Never"

header "5. Simulated Tier-B agent passes frontmatter validation"

cat > "$AGENT_TMPFILE" << 'EOF'
---
name: platform-engineer
description: Platform engineering specialist. Guides golden path adoption, incident response, and IaC workflows from team runbooks.
# knowledge-tier: B — user-provided: platform-runbook.md
tools: Read, Bash, Glob, Grep
model: sonnet
permissionMode: plan
memory: project
color: cyan
---

You are a platform engineering specialist, trained on the team's internal runbook (platform-runbook.md). You guide engineers through golden path adoption, incident response, and Terraform/ArgoCD workflows following team conventions.

## Responsibilities

- Guide engineers through the golden path for new service creation
- Run incident triage: check Datadog dashboards, recent deploys, and recommend rollback
- Review Terraform changes for IAM, ECS, and ALB resource patterns
- Enforce platform conventions: required tags, health check endpoints, secrets management

## Constraints

- Do not push secrets to Git — always use AWS Secrets Manager
- Do not apply Terraform without a confirmed plan (`terraform plan -out=tfplan`)
- Do not delete production RDS instances without first verifying a recent snapshot
- Always require explicit user approval before any rollback or destructive operation
EOF

has_field "Tier-B agent" "$AGENT_TMPFILE" "name"
has_field "Tier-B agent" "$AGENT_TMPFILE" "description"
has_field "Tier-B agent" "$AGENT_TMPFILE" "tools"
has_field "Tier-B agent" "$AGENT_TMPFILE" "model"
has_field "Tier-B agent" "$AGENT_TMPFILE" "permissionMode"
has_field "Tier-B agent" "$AGENT_TMPFILE" "memory"

contains "Has Tier B knowledge-tier comment"    "$AGENT_TMPFILE" "knowledge-tier: B"
contains "Comment references user-provided"     "$AGENT_TMPFILE" "user-provided:"
contains "Comment includes source filename"     "$AGENT_TMPFILE" "\.md"
contains "Identity references source file"      "$AGENT_TMPFILE" "trained on.*runbook|runbook.*trained on"
contains "Has Responsibilities section"         "$AGENT_TMPFILE" "## Responsibilities"
contains "Has Constraints section"              "$AGENT_TMPFILE" "## Constraints"
contains "No-secrets constraint from runbook"   "$AGENT_TMPFILE" "secrets.*Git|Git.*secrets"

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

# Validate memory field value
MEM=$(awk '/^---/{c++; if(c==2) exit} c==1' "$AGENT_TMPFILE" | grep '^memory:' | sed 's/memory: *//')
if echo "project user local" | grep -qw "$MEM"; then
  pass "memory field is valid: '$MEM'"
else
  fail "memory field is invalid: '$MEM'"
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

header "6. MEMORY.md write path formula matches spec"

# The skill specifies:
#   MEMORY_SCOPE=project → .claude/agent-memory/<name>/MEMORY.md
#   MEMORY_SCOPE=user    → ~/.claude/agent-memory/<name>/MEMORY.md
contains "Project scope path in skill"      "$SKILL" "\.claude/agent-memory/\[AGENT_NAME\]/MEMORY\.md|agent-memory.*AGENT_NAME.*MEMORY"
contains "User scope path in skill"         "$SKILL" "~/.claude/agent-memory|user.*agent-memory"
contains "MEMORY_FILE_PATH variable set"    "$SKILL" "MEMORY_FILE_PATH"
contains "Write MEMORY_CONTENT to path"     "$SKILL" "write.*MEMORY_CONTENT|MEMORY_CONTENT.*write"
contains "Create parent dir if needed"      "$SKILL" "Create parent directory|parent directory"

header "7. Tier B frontmatter comment format"

contains "Tier B comment format in Phase 6"   "$SKILL" "knowledge-tier: B —"
contains "Tier B uses user-provided label"    "$SKILL" "user-provided:.*KNOWLEDGE_SOURCE_TITLE"
contains "Tier B format distinct from Tier A" "$SKILL" "knowledge-tier: A —"
contains "Tier B format distinct from Tier E" "$SKILL" "knowledge-tier: E — WARNING"

# ── Summary ───────────────────────────────────────────────────────────────────

echo
echo "════════════════════════════════════════════════"
echo "  F3 Results: ${PASS} passed · ${FAIL} failed · ${SKIP} skipped"
echo "════════════════════════════════════════════════"

[ "$FAIL" -eq 0 ]
