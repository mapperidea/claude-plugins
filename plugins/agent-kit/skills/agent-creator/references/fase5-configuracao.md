# Fase 5 — Configuração

*Referência da skill `agent-creator` — leia ao ENTRAR nesta fase. O roteiro e a ordem estão no `SKILL.md`.*

## Phase 5 — Configuration

**Goal**: set the remaining frontmatter fields that control runtime behaviour — turns, effort, isolation, background, skills, color, and MCP servers.

**Target**: ask everything in one message, process answers, auto-apply sensible defaults for anything the user skips.

---

### 5.1 — Pre-derive defaults before asking

Compute defaults silently from Phase 1–3 values so the user only needs to override, not configure from scratch.

**maxTurns default**
```
TASK_BOUNDEDNESS=bounded  AND  ACCESS_LEVEL=read-only        → 10
TASK_BOUNDEDNESS=bounded  AND  ACCESS_LEVEL=read-write        → 20
TASK_BOUNDEDNESS=bounded  AND  ACCESS_LEVEL=read-write-execute → 25
TASK_BOUNDEDNESS=open-ended                                   → omit (no cap)
AGENT_TYPE=multi-agent-orchestrator                           → omit (orchestrators run until delegations complete)
```
Set `MAX_TURNS`.

**effort default**
```
MODEL=haiku    → low
MODEL=sonnet   → medium
MODEL=opus     → high
```
Set `EFFORT`.

**isolation default**
```
NEEDS_ISOLATION=true  → worktree
otherwise             → omit
```
Set `ISOLATION`.

**background default**
```
TASK_BOUNDEDNESS=open-ended  → suggest true
otherwise                    → false
```
Set `BACKGROUND`.

---

### 5.2 — Ask all configuration questions in one message

```
Almost done — a few final settings. I've pre-filled sensible defaults; override anything that doesn't fit.

1. **Max turns** (default: [MAX_TURNS or "no cap"]):
   How many steps should the agent be allowed before stopping?
   Type a number, "no cap", or press Enter to keep the default.

2. **Effort level** (default: [EFFORT]):
   Controls reasoning depth and token budget.
   Options: low / medium / high / xhigh / max — or Enter to keep default.

3. **Isolation** (default: [worktree / none]):
   [If NEEDS_ISOLATION=true:]
   ⚠ This agent uses Bash + file writes. Worktree isolation is recommended — it gives
   the agent a safe git branch to work in, auto-cleaned if no changes are committed.
   Keep worktree isolation? (yes / no)
   [If NEEDS_ISOLATION=false:]
   No isolation needed based on the tool set. Skip or type "worktree" to enable anyway.

4. **Background mode** (default: [BACKGROUND]):
   Run as a background task by default? Background agents can't prompt the user mid-run.
   (yes / no / Enter to keep default)

5. **Skills to preload** (default: none):
   Any existing Claude Code skills this agent should have loaded at startup?
   Type skill names separated by commas, or Enter to skip.
   Example: "quarkus, security-checklist"

6. **Color** (default: auto):
   Pick a color for this agent in the UI:
   red · blue · green · yellow · purple · orange · pink · cyan
   Or Enter to auto-assign based on domain:
   [show auto-assigned color and its rationale, e.g. "red for security agents, blue for infra"]

7. **MCP servers** (default: none):
   Does this agent need access to any MCP servers (e.g. databases, external APIs)?
   Type server names separated by commas, or Enter to skip.
```

---

### 5.3 — Process answers and apply defaults

For each question, if the user pressed Enter or gave no answer, use the pre-derived default.

**maxTurns**:
- User typed a number → `MAX_TURNS = N`
- User typed "no cap" or "0" → `MAX_TURNS = null` (omit from frontmatter)
- Enter → use pre-derived default; if default was "omit", keep null

**effort**:
- Validate against allowed values: `low`, `medium`, `high`, `xhigh`, `max`
- If invalid, fall back to default and note it

**isolation**:
- "yes" or "worktree" → `ISOLATION = worktree`
- "no" or Enter (when not pre-selected) → `ISOLATION = null`

**background**:
- "yes" → `BACKGROUND = true`
- "no" or Enter → `BACKGROUND = false`
- If `BACKGROUND=true` and `PERMISSION_MODE` is `plan` or `default`, warn:
  > "⚠ Background agents can't prompt the user, but [plan/default] mode may require approval. Consider switching to `auto` permission mode for background use."
  Ask: "Switch permission mode to `auto`? (yes / no)"

**skills**:
- Parse comma-separated list → `SKILLS_LIST`
- Empty → `SKILLS_LIST = null`

**color**:
- If user picked one → `COLOR = <choice>`
- If Enter → auto-assign using this domain→color mapping:
  ```
  security / audit / compliance  → red
  infra / devops / cloud         → orange
  data / analytics / ml          → yellow
  architecture / design          → purple
  testing / qa                   → green
  documentation / writing        → cyan
  database / sql                 → blue
  code review / refactoring      → blue
  default (anything else)        → blue
  ```
  Set `COLOR`.

**mcpServers**:
- Parse comma-separated list → `MCP_SERVERS_LIST`
- Empty → `MCP_SERVERS_LIST = null`

---

### 5.4 — Show configuration summary

```
Configuration set:

| Setting       | Value                          |
|---------------|--------------------------------|
| maxTurns      | [MAX_TURNS or "no cap"]        |
| effort        | [EFFORT]                       |
| isolation     | [ISOLATION or "none"]          |
| background    | [BACKGROUND]                   |
| skills        | [SKILLS_LIST or "none"]        |
| color         | [COLOR]                        |
| mcpServers    | [MCP_SERVERS_LIST or "none"]   |

Ready to generate the agent file. Continuing to Phase 6...
```

Proceed to Phase 6 immediately — no user confirmation needed here.

---
