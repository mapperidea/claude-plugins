#!/usr/bin/env bash
# test-f6-acceptance-criteria.sh — F6 acceptance criteria checklist
#
# Final acceptance gate. Verifies every item in the F6 checklist is met
# by inspecting skill files, templates, agents, and scripts structurally.
#
# Acceptance criteria:
#   AC1  Wizard completes in ≤8 user-facing turns
#   AC2  All 11 templates load without frontmatter errors
#   AC3  Multi-agent orchestrator path is fully implemented
#   AC4  Safety hooks offered when Bash/Write/Edit tools included
#   AC5  --scope user and --scope project write to correct paths
#   AC6  Generated agents are invocable via @"<name> (agent)"
#   AC7  O'Reilly MCP queried on every domain-specific creation
#   AC8  knowledge-extractor handles .pdf, .md, .txt, .adoc, .rst
#   AC9  Every template has a knowledge-tier comment (A–E)
#  AC10  MEMORY.md pre-seeded for Tier A/B/C agents

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

# A skill é o NÚCLEO + as referências que ele roteia: o conteúdo mudou de arquivo
# na divisão por disclosure progressivo, não deixou de existir. As asserções abaixo
# perguntam "o wizard diz isto?", não "este arquivo diz isto".
SKILL_DIR="$KIT_ROOT/skills/agent-creator"
SKILL="$(mktemp)"; trap 'rm -f "$SKILL"' EXIT
cat "$SKILL_DIR/SKILL.md" "$SKILL_DIR/references"/*.md > "$SKILL"
HELPERS="$KIT_ROOT/skills/agent-creator/references/helpers.md"
EXTRACTOR="$KIT_ROOT/agents/knowledge-extractor.md"
TEMPLATES_DIR="$KIT_ROOT/templates"

# ── AC1 — Wizard completes in ≤8 user-facing turns ────────────────────────────

header "AC1 — Wizard completes in ≤8 user-facing turns"

# Count the number of explicit "Wait for" user response gates in the wizard
# (excludes knowledge-extractor waits which are agent-to-agent, not user-facing)
WIZARD_GATES=$(grep -c "^Wait for the user\|^Wait for confirmation\|^Wait for the user's response" "$SKILL" 2>/dev/null || true)

if [ "$WIZARD_GATES" -le 8 ]; then
  pass "User-facing wait gates ≤8: found ${WIZARD_GATES}"
else
  fail "Too many user-facing wait gates: found ${WIZARD_GATES} (limit 8)"
fi

# Phase 1 is explicitly "single exchange" — all 6 questions asked at once
contains "Phase 1 is single exchange"      "$SKILL" "single exchange — ask all questions at once"

# Phase 3 is "one exchange"
contains "Phase 3 is one exchange"         "$SKILL" "one exchange — show all recommendations"

# Phase 4 is "one exchange" for the draft review
contains "Phase 4 draft is one exchange"   "$SKILL" "produce a complete draft.*one exchange|Target.*one exchange"

# Skip logic cuts phases for Tier E
contains "Tier E skip reduces turns"       "$SKILL" "jump to Phase 3|KNOWLEDGE_TIER=E.*jump"

# ── AC2 — All 11 templates load without frontmatter errors ────────────────────

header "AC2 — All 11 templates load without frontmatter errors"

TEMPLATES=(
  "code-reviewer" "researcher" "refactorer" "tester" "documenter"
  "db-analyst" "devops" "security-auditor" "architect" "data-scientist"
  "dev-orchestrator"
)

REQUIRED_FIELDS=("name" "description" "model" "permissionMode")

for t in "${TEMPLATES[@]}"; do
  TFILE="$TEMPLATES_DIR/$t.md"
  if [ ! -f "$TFILE" ]; then
    fail "Template missing: $t"
    continue
  fi

  # Check frontmatter is well-formed (opens and closes with ---)
  DELIMITERS=$(grep -c "^---$" "$TFILE" 2>/dev/null || true)
  if [ "$DELIMITERS" -ge 2 ]; then
    pass "Template $t: frontmatter delimiters present"
  else
    fail "Template $t: malformed frontmatter (found $DELIMITERS '---' lines, need ≥2)"
  fi

  # Check required fields
  for field in "${REQUIRED_FIELDS[@]}"; do
    awk '/^---/{c++; if(c==2) exit} c==1' "$TFILE" 2>/dev/null \
      | grep -q "^${field}:" \
      && pass "Template $t: has '$field'" \
      || fail "Template $t: missing '$field'"
  done

  # Check model value is valid
  MODEL=$(awk '/^---/{c++; if(c==2) exit} c==1' "$TFILE" | grep '^model:' | sed 's/model: *//')
  if echo "sonnet opus haiku inherit" | grep -qw "$MODEL"; then
    pass "Template $t: model='$MODEL' is valid"
  else
    fail "Template $t: model='$MODEL' is invalid"
  fi

  # Check permissionMode value is valid
  PMODE=$(awk '/^---/{c++; if(c==2) exit} c==1' "$TFILE" | grep '^permissionMode:' | sed 's/permissionMode: *//')
  if echo "default acceptEdits auto plan bypassPermissions" | grep -qw "$PMODE"; then
    pass "Template $t: permissionMode='$PMODE' is valid"
  else
    fail "Template $t: permissionMode='$PMODE' is invalid"
  fi
done

# ── AC3 — Multi-agent orchestrator path fully implemented ─────────────────────

header "AC3 — Multi-agent orchestrator path (Phase 3O / 4O) is implemented"

contains "Phase 3O section exists"             "$SKILL" "Phase 3O — Orchestrator"
contains "Phase 4O section exists"             "$SKILL" "Phase 4O — Orchestrator Behavior"
contains "Glob existing agents in 3O"          "$SKILL" "Glob.*list.*agents|Use.*Glob.*agents"
contains "Worker list collected"               "$SKILL" "worker.*list|collect.*workers|WORKER_LIST"
contains "Tools restricted to Agent(name)"     "$SKILL" "Agent\(.*worker|restrict.*Agent\(|tools.*Agent\("
contains "Missing worker warning"              "$SKILL" "missing.*worker|worker.*not found|warn.*worker"
contains "Delegation template in 4O"           "$SKILL" "delegate.*worker|worker.*delegate"
contains "Sequencing rules in 4O"              "$SKILL" "sequenc|Do not delegate.*parallel"
contains "Worker routing table in 4O"          "$SKILL" "routing table|worker.*routing|When to use each worker"
# dev-orchestrator is a template file, not referenced by name in the skill
[ -f "$TEMPLATES_DIR/dev-orchestrator.md" ] \
  && pass "dev-orchestrator template file exists" \
  || fail "dev-orchestrator template file not found"

# Validate dev-orchestrator template structure
ORCH="$TEMPLATES_DIR/dev-orchestrator.md"
if [ -f "$ORCH" ]; then
  contains "Orchestrator has Agent() tools"    "$ORCH"  "Agent\("
  contains "Orchestrator has sequencing rules" "$ORCH"  "Sequencing rules|sequencing"
  contains "Orchestrator delegates only"       "$ORCH"  "Do not write.*edit.*execute|do not.*write.*code"
  pass "dev-orchestrator template: file exists"
else
  fail "dev-orchestrator template: file not found at $ORCH"
fi

# ── AC4 — Safety hooks offered for Bash/Write/Edit tools ─────────────────────

header "AC4 — Safety hooks offered when Bash/Write/Edit tools included"

contains "NEEDS_HOOK logic present"            "$SKILL" "NEEDS_HOOK"
contains "Hook offer in Phase 4.5"             "$SKILL" "4.5 — Draft safety hook"
contains "Hook offered for Bash tool"          "$SKILL" "uses.*Bash.*safety hook|Bash.*Write.*Edit.*hook"
contains "yes/no/customize hook options"       "$SKILL" "yes.*no.*customize|customize.*hook"
contains "HOOK_CONFIG variable set"            "$SKILL" "HOOK_CONFIG"
contains "validate-bash.sh in helpers"         "$HELPERS" "validate-bash"
contains "check-write-path.sh in helpers"      "$HELPERS" "check-write-path"
contains "validate-bash.sh script exists"      "$KIT_ROOT/scripts/validate-bash.sh" "PreToolUse|block\|BLOCK"
contains "check-write-path.sh script exists"   "$KIT_ROOT/scripts/check-write-path.sh" "PreToolUse|PROJECT_ROOT"
# Scripts must be executable
[ -x "$KIT_ROOT/scripts/validate-bash.sh" ] \
  && pass "validate-bash.sh is executable" \
  || fail "validate-bash.sh is not executable"
[ -x "$KIT_ROOT/scripts/check-write-path.sh" ] \
  && pass "check-write-path.sh is executable" \
  || fail "check-write-path.sh is not executable"

# Comportamento, não só presença. O Claude Code só bloqueia um PreToolUse com
# exit 2 — qualquer outro código não-zero é erro NÃO-bloqueante e a ferramenta
# roda. Até 2026-09-25 os dois scripts saíam com 1: pareciam funcionar em teste
# manual e nunca bloquearam nada de verdade (provado com um Write real).
exit_of() { printf '%s' "$2" | "$KIT_ROOT/scripts/$1" 2>/dev/null; echo $?; }
[ "$(exit_of check-write-path.sh '{"tool_name":"Write","tool_input":{"file_path":"/etc/passwd"}}')" = 2 ] \
  && pass "check-write-path.sh blocks with exit 2" \
  || fail "check-write-path.sh must exit 2 to block (exit 1 does NOT block in Claude Code)"
[ "$(exit_of check-write-path.sh "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$KIT_ROOT/x.md\"}}")" = 0 ] \
  && pass "check-write-path.sh allows a path inside the project" \
  || fail "check-write-path.sh must exit 0 for a path inside the project"
[ "$(exit_of validate-bash.sh '{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}')" = 2 ] \
  && pass "validate-bash.sh blocks with exit 2" \
  || fail "validate-bash.sh must exit 2 to block (exit 1 does NOT block in Claude Code)"
[ "$(exit_of validate-bash.sh '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}')" = 0 ] \
  && pass "validate-bash.sh allows a safe command" \
  || fail "validate-bash.sh must exit 0 for a safe command"

# O hook recebe o JSON da ferramenta no stdin. $CLAUDE_TOOL_INPUT não existe:
# `echo '$CLAUDE_TOOL_INPUT' | script` troca o JSON real por texto vazio, e o
# script, sem nada para ler, libera. Nenhum artefato do kit pode ensinar isso.
# Só a FIAÇÃO (uma linha `command:`) é proibida; o guia cita a variável como anti-exemplo.
leaky_wiring=$(grep -rlE 'command:.*CLAUDE_TOOL_INPUT' "$KIT_ROOT" "$KIT_ROOT/../iadd" --include='*.md' --include='*.sh' 2>/dev/null \
  | grep -v '/tests/')
[ -z "$leaky_wiring" ] \
  && pass "no hook wiring uses the nonexistent \$CLAUDE_TOOL_INPUT" \
  || fail "hook wiring uses \$CLAUDE_TOOL_INPUT (stdin is the real input): $leaky_wiring"

# ── AC5 — --scope user/project write to correct paths ────────────────────────

header "AC5 — --scope user and --scope project write to correct paths"

contains "--scope user sets ~/.claude/agents/"   "$SKILL" "--scope user.*~/.claude/agents|scope.*user.*~/.claude/agents"
contains "--scope project sets .claude/agents/"  "$SKILL" "--scope project.*\.claude/agents|scope.*project.*\.claude/agents"
contains "Default is project scope"              "$SKILL" "default.*project scope|project.*default"
contains "SCOPE variable derived in Phase 0"     "$SKILL" "SCOPE=project|SCOPE=user"
contains "AGENT_FILE_PATH uses scope"            "$SKILL" "AGENT_FILE_PATH.*AGENT_NAME"
contains "Project path: .claude/agents/"         "$SKILL" "SCOPE=project.*\.claude/agents/\[AGENT_NAME\]"
contains "User path: ~/.claude/agents/"          "$SKILL" "SCOPE=user.*~/.claude/agents/\[AGENT_NAME\]"
contains "Overwrite warning if file exists"      "$SKILL" "already exists.*Overwrite|Overwrite\?"

# ── AC6 — Agents invocable via @"<name> (agent)" ─────────────────────────────

header "AC6 — Generated agents are invocable via @\"<name> (agent)\""

contains "settings.json registration offered"   "$SKILL" "settings\.json.*registration|6\.8 — Offer settings"
contains "Agent() added to permissions.allow"   "$SKILL" "permissions\.allow|permissions.*allow"
contains "Invocation example in completion msg" "$SKILL" '@".*\(agent\)"'
contains "Enrich flow shows invocation example" "$SKILL" 'Invoke to verify'
contains '@"<name> (agent)" invocation syntax'  "$SKILL" '@".*\(agent\)"'

# ── AC7 — O'Reilly MCP queried on every domain-specific creation ──────────────

header "AC7 — O'Reilly MCP queried on every domain-specific creation"

contains "Phase 2 always queries O'Reilly first"  "$SKILL" "search O.Reilly first"
contains "mcp__oreilly call in Phase 2"            "$SKILL" "mcp__oreilly__search_oreilly_content"
contains "Only well-known domains may skip"        "$SKILL" "well-covered in training data"
contains "Skip is opt-in (user must say skip)"     "$SKILL" "If user says skip"
contains "O'Reilly also in Enrich flow"            "$SKILL" "EXISTING_SOURCE.*patterns best practices|mcp__oreilly.*EXISTING"
contains "O'Reilly also in Knowledge Search flow"  "$SKILL" "K1 — Run broad O.Reilly search"

# ── AC8 — Extraction works for .pdf, .md, .txt, .adoc, .rst ──────────────────

header "AC8 — knowledge-extractor handles .pdf, .md, .txt, .adoc, .rst"

contains "PDF format handled"         "$EXTRACTOR" "\.pdf|PDF"
contains "Markdown format handled"    "$EXTRACTOR" "\.md|Markdown"
contains "Plain text format handled"  "$EXTRACTOR" "\.txt|plain text"
contains "AsciiDoc format handled"    "$EXTRACTOR" "\.adoc|AsciiDoc"
contains "RST format handled"         "$EXTRACTOR" "\.rst|RST"
contains "Web URL handled"            "$EXTRACTOR" "Web URL|https?://"
contains "Multiple files via Glob"    "$EXTRACTOR" "Glob.*list all files|multiple files"
contains "Format-specific navigation" "$EXTRACTOR" "format-specific|Format-specific"
contains "PDF uses pages parameter"   "$EXTRACTOR" "pages.*parameter|pages=|page range"
contains "Markdown reads by heading"  "$EXTRACTOR" "heading|##.*heading"

# Also verify skill-level support matches
contains "Skill lists .pdf support"   "$SKILL" "PDF"
contains "Skill lists .md support"    "$SKILL" "\.md"
contains "Skill lists .txt support"   "$SKILL" "\.txt"
contains "Skill lists .adoc support"  "$SKILL" "\.adoc"
contains "Skill lists .rst support"   "$SKILL" "\.rst"

# ── AC9 — Every template has a knowledge-tier comment ────────────────────────

header "AC9 — Every template has a knowledge-tier comment (A–E)"

for t in "${TEMPLATES[@]}"; do
  TFILE="$TEMPLATES_DIR/$t.md"
  [ -f "$TFILE" ] || continue
  if grep -q "knowledge-tier:" "$TFILE"; then
    TIER_LINE=$(grep "knowledge-tier:" "$TFILE" | head -1)
    # Tier value must be one of A B C D E
    if echo "$TIER_LINE" | grep -qE "knowledge-tier: [ABCDE]"; then
      pass "Template $t: has valid tier comment"
    else
      fail "Template $t: tier comment has unknown tier value: $TIER_LINE"
    fi
  else
    fail "Template $t: missing knowledge-tier comment"
  fi
done

# Verify skill generates the comment for all tiers A–E
contains "Skill generates Tier A comment"  "$SKILL" "knowledge-tier: A —"
contains "Skill generates Tier B comment"  "$SKILL" "knowledge-tier: B —"
contains "Skill generates Tier C comment"  "$SKILL" "knowledge-tier: C —"
contains "Skill generates Tier D comment"  "$SKILL" "knowledge-tier: D —"
contains "Skill generates Tier E comment"  "$SKILL" "knowledge-tier: E — WARNING"

# ── AC10 — MEMORY.md pre-seeded for Tier A/B/C agents ────────────────────────

header "AC10 — MEMORY.md pre-seeded for Tier A/B/C agents"

contains "Pre-seeding for Tier A/B/C declared" "$SKILL" "KNOWLEDGE_TIER.*A.*B.*C.*MEMORY|pre-seeded.*Tier A/B/C"
contains "Phase 4.6 builds MEMORY content"     "$SKILL" "4\.6 — Draft MEMORY"
contains "MEMORY_CONTENT built from knowledge" "$SKILL" "Build the MEMORY.md content from"
contains "MEMORY_CONTENT null for Tier D/E"    "$SKILL" "KNOWLEDGE_TIER=D.*E.*MEMORY_CONTENT=null|MEMORY_CONTENT=null"
contains "MEMORY.md written in Phase 6"        "$SKILL" "MEMORY_FILE_PATH.*not null.*MEMORY_CONTENT|write.*MEMORY_CONTENT"
contains "MEMORY.md line limit ≤200"           "$SKILL" "200 line|under 200 lines"
contains "MEMORY.md has Core Patterns section" "$SKILL" "## Core Patterns"
contains "MEMORY.md has Decision Heuristics"   "$SKILL" "## Decision Heuristics"
contains "Tier A confirmed in MEMORY summary"  "$SKILL" "Tier A.*Grounded in|Grounded in.*KNOWLEDGE_SOURCE"
contains "Orchestrators exempt from MEMORY"    "$SKILL" "Orchestrators don.t need domain knowledge"

# ── Summary ───────────────────────────────────────────────────────────────────

echo
echo "════════════════════════════════════════════════"
echo "  F6 Results: ${PASS} passed · ${FAIL} failed · ${SKIP} skipped"
echo "════════════════════════════════════════════════"

[ "$FAIL" -eq 0 ]
