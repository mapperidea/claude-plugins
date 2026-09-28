# Fases 3O e 4O — especialização de orquestrador

*Referência da skill `agent-creator` — leia ao ENTRAR nesta fase. O roteiro e a ordem estão no `SKILL.md`.*

## Phase 3O — Orchestrator Specialization

**Entered only when `AGENT_TYPE=multi-agent-orchestrator`.**

This phase runs immediately after Phase 3 confirmation and before Phase 4. It collects the list of specialist agents to delegate to and generates an orchestrator-specific tool restriction and system prompt.

---

### 3O.1 — Discover existing agents

Use `Glob` to list currently available agents:

```
.claude/agents/*.md
~/.claude/agents/*.md   (if accessible)
```

Extract the `name` field from each file's frontmatter. Present the list:

```
I found these existing agents that could be workers for your orchestrator:
  [name] — [description, truncated to 60 chars]
  [name] — [description]
  ...

Which agents should this orchestrator delegate to?
Type their names (comma-separated), or describe ones that don't exist yet.

Note: Agent() tool restrictions only work for agents that exist at runtime.
If a worker doesn't exist yet, create it first with /agent-creator, then
come back to create the orchestrator.
```

If no agents are found:
```
No existing agents found in .claude/agents/.

An orchestrator needs worker agents to delegate to. You have two options:
  a) Create the worker agents first with /agent-creator, then create this orchestrator
  b) Name the workers now (I'll scaffold them as stubs) and fill them in later

Which would you prefer? (a / b)
```

If option a → exit cleanly with instructions to create workers first.
If option b → proceed, but note each worker as a stub requiring completion.

---

### 3O.2 — Collect worker agent list

After the user names their workers, store them:
- `WORKER_AGENTS` = list of agent names (e.g. `["code-reviewer", "tester", "documenter"]`)

For each named worker, verify it exists in `.claude/agents/`:
- Exists → mark as `confirmed`
- Does not exist → mark as `missing`, warn the user:

```
⚠ These workers don't exist yet and must be created before the orchestrator
  can delegate to them:
  [name], [name]

I'll include them in the orchestrator's tool list anyway. Create them with:
  /agent-creator "[worker purpose]"
```

---

### 3O.3 — Set orchestrator tool list

Override `TOOL_LIST` from Phase 3 with orchestrator-appropriate tools:

```
Agent([worker1]), Agent([worker2]), ...   ← one entry per WORKER_AGENTS item
Read, Glob                                ← for reading task context
AskUserQuestion                           ← for clarifying ambiguous tasks
```

The `Agent()` restriction means this orchestrator can **only** spawn the named workers — it cannot spawn arbitrary agents. This is intentional and should be explained to the user.

Do not add `Bash`, `Write`, `Edit`, or `WebSearch` unless the user explicitly asks — an orchestrator's job is to delegate, not to do work directly.

Set `TOOL_LIST` to the assembled list.
Set `NEEDS_HOOK=false` (no Bash or Write, so no hooks needed).
Set `NEEDS_ISOLATION=false`.

---

### 3O.4 — Set orchestrator model and permission mode

```
MODEL = sonnet          (orchestrators need reasoning, not raw power — opus is overkill)
PERMISSION_MODE = default
MAX_TURNS = null        (orchestrators run until all delegations complete)
```

Override Phase 3 values with these unless the user already specified otherwise.

---

### 3O.5 — Show orchestrator configuration

```
Orchestrator configuration:

Workers: [WORKER_AGENTS, comma-separated]
  [confirmed workers listed with ✓]
  [missing workers listed with ⚠ — must be created]

Tools: Agent([w1]), Agent([w2]), ..., Read, Glob, AskUserQuestion
Model: sonnet
Permission mode: default

The orchestrator can ONLY delegate to the named workers above.
It cannot spawn other agents or do work directly.

Ready to design the delegation logic. Continuing to Phase 4...
```

Proceed to Phase 4O (orchestrator behavior design) automatically.

---

## Phase 4O — Orchestrator Behavior Design

**Entered only when `AGENT_TYPE=multi-agent-orchestrator`.** Replaces Phase 4 for orchestrators.

---

### 4O.1 — Draft identity statement

```
You are a [DOMAIN] orchestrator. You decompose tasks and delegate each part
to the appropriate specialist agent. You do not do the work yourself.
```

If domain knowledge exists (Tier A/B/C/D), add:
```
, informed by [KNOWLEDGE_SOURCE_TITLE]
```

---

### 4O.2 — Draft delegation logic

Write the core system prompt with a routing table and process:

```
## Workers

[for each worker in WORKER_AGENTS:]
- **[name]**: [one-line description of what this worker does, read from the worker's agent file if it exists]

## Delegation process

1. Read the task and break it into sub-tasks, one per concern
2. For each sub-task, identify the most appropriate worker from the list above
3. Delegate using: @"[worker-name] (agent)" [sub-task description]
4. Wait for the worker's result before proceeding to the next delegation
5. Synthesize all results into a final response

## When to ask for clarification

Use AskUserQuestion before delegating if:
- The task is ambiguous about scope (which files, which environment, which criteria)
- Two workers could plausibly handle the same sub-task
- The task requires a decision that affects the approach (e.g. "fix or just report?")

Ask at most one clarifying question. If still unclear after the answer, proceed with
the most conservative interpretation.

## What NOT to do

- Do not do the work yourself — always delegate to a worker
- Do not delegate the same sub-task to multiple workers in parallel unless they are
  truly independent (e.g. review file A and review file B simultaneously is fine;
  review and fix the same file simultaneously is not)
- Do not spawn agents not in your worker list
```

---

### 4O.3 — Skip MEMORY.md for orchestrators

Orchestrators don't need domain knowledge pre-seeded — their workers hold the domain knowledge. Set `MEMORY_CONTENT=null` regardless of knowledge tier.

---

### 4O.4 — Show draft for review

Present the full system prompt draft to the user for review, same format as Phase 4 step 4.7.

After confirmation, set `SYSTEM_PROMPT_BODY` and proceed to Phase 5.

---
