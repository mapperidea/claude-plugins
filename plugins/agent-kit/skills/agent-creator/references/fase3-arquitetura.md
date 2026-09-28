# Fase 3 — Recomendação de arquitetura

*Referência da skill `agent-creator` — leia ao ENTRAR nesta fase. O roteiro e a ordem estão no `SKILL.md`.*

## Phase 3 — Architecture Recommendation

**Goal**: derive the minimal, correct set of architectural decisions from the Phase 1 answers. Present them with clear reasoning so the user can confirm or override.

**Target**: one exchange — show all recommendations together, wait for a single confirm/adjust response.

---

### 3.1 — Derive agent type

Apply the decision tree from `agent-creator-helpers.md` section 1 using Phase 1 values:

```
NEEDS_AGENTS=true                    → MULTI_AGENT_ORCHESTRATOR
TASK_BOUNDEDNESS=open-ended          → AUTONOMOUS
TASK_BOUNDEDNESS=bounded
  AND ACCESS_LEVEL=read-only         → REACTIVE (if single-pass) or DELIBERATIVE
  AND ACCESS_LEVEL=read-write        → DELIBERATIVE
  AND ACCESS_LEVEL=read-write-execute → DELIBERATIVE
```

Set `AGENT_TYPE` to one of: `reactive`, `deliberative`, `autonomous`, `multi-agent-orchestrator`.

Prepare a one-line rationale:
- reactive: "single-pass read-only task with no state needed between steps"
- deliberative: "bounded task that benefits from planning before acting"
- autonomous: "open-ended task requiring a self-directed ReAct loop"
- multi-agent-orchestrator: "coordinates specialist agents — needs Agent() tool restrictions"

---

### 3.2 — Derive tool list

Start from the base set: `Read, Glob, Grep`

Apply additions from the tool recommendation matrix in `agent-creator-helpers.md` section 2:

```
NEEDS_WEB=true                       → add WebSearch, WebFetch
ACCESS_LEVEL=read-write              → add Edit
ACCESS_LEVEL=read-write-execute      → add Edit, Bash
  (creating new files needed?)       → also add Write  ← ask if unclear
NEEDS_AGENTS=true                    → add Agent([name1]), Agent([name2])  ← ask which agents
```

If `ACCESS_LEVEL=read-write-execute` and it's unclear whether the agent creates files vs only edits existing ones, default to `Edit` only and note that `Write` can be added if needed.

Set `TOOL_LIST` as the final minimal list.

Set `NEEDS_HOOK` = true if `Bash` is in `TOOL_LIST` or `Write`/`Edit` is in `TOOL_LIST`.

Set `NEEDS_ISOLATION` = true if `Bash` AND (`Write` OR `Edit`) are both in `TOOL_LIST`.

---

### 3.3 — Derive model

Apply the model guide from `agent-creator-helpers.md` section 3:

```
AGENT_TYPE=reactive AND ACCESS_LEVEL=read-only   → haiku
AGENT_TYPE=deliberative                           → sonnet
AGENT_TYPE=autonomous                             → sonnet
AGENT_TYPE=multi-agent-orchestrator               → sonnet
"Bash" in TOOL_LIST                               → sonnet minimum (never haiku)
DOMAIN suggests security / infra / compliance     → opus
DOMAIN suggests architecture / system design      → opus
```

Set `MODEL` and prepare a one-line cost/complexity rationale.

---

### 3.4 — Derive permission mode

Apply the permission mode guide from `agent-creator-helpers.md` section 4:

```
"Bash" in TOOL_LIST AND DOMAIN suggests DB/infra/production  → plan
"Bash" in TOOL_LIST AND limited to test runners / safe cmds  → default
"Edit" in TOOL_LIST AND "Bash" NOT in TOOL_LIST              → acceptEdits
ACCESS_LEVEL=read-only                                        → default
AGENT_TYPE=autonomous AND ACCESS_LEVEL=read-write-execute    → plan (safety first)
```

Set `PERMISSION_MODE` and prepare a one-line rationale.

---

### 3.5 — Ask about memory

Ask this as part of the recommendation message (see 3.6), not as a separate exchange.

Include this question inline:
```
Does this agent need to remember things across sessions?
  a) No — stateless is fine
  b) Yes, private to me — user scope (~/.claude/agent-memory/)
  c) Yes, shared with my team — project scope (.claude/agent-memory/)
```

If `KNOWLEDGE_TIER` is A, B, C, or D → pre-select option (c) and explain:
> "(Pre-selected: project scope, because we have domain knowledge to persist in MEMORY.md)"

Set `MEMORY_SCOPE` based on answer: `none`, `user`, or `project`.

---

### 3.6 — Present all recommendations in one message

```
Here's the architecture I recommend for this agent:

**Agent type**: [AGENT_TYPE] — [one-line rationale]

**Tools** ([N] total — minimal privilege):
  [TOOL_LIST, one per line with a ← note on why it's included]
  [if NEEDS_HOOK] ⚠ Safety hooks will be offered in Phase 5 (Bash validator / write-path limiter)
  [if NEEDS_ISOLATION] ⚠ Worktree isolation recommended (agent writes + executes)

**Model**: [MODEL] — [one-line cost/complexity rationale]

**Permission mode**: [PERMISSION_MODE] — [one-line rationale]

**Memory**: [MEMORY_SCOPE description]
  [if KNOWLEDGE_TIER A/B/C/D] MEMORY.md will be pre-seeded with [N] patterns and heuristics from [source]

Does this look right? You can adjust any of these before I continue.
Common overrides:
  - "use opus instead" / "use haiku instead"
  - "add WebSearch" / "remove Bash"
  - "make it plan mode"
  - "no memory needed"
```

Wait for the user to confirm or make adjustments.

---

### 3.7 — Process overrides

If the user requests changes:
- Apply each override to the stored values
- Re-derive any dependent values (e.g. changing to `Bash` → re-check `PERMISSION_MODE`, `MODEL`, `NEEDS_HOOK`)
- Show only the changed lines, not the full summary again:

```
Updated:
- Model: haiku → sonnet (Bash present — haiku not recommended for execution agents)
- Permission mode: default → plan (you requested it)
```

Ask: "Anything else, or shall I continue?"

Once confirmed, proceed to Phase 4 immediately.

---
