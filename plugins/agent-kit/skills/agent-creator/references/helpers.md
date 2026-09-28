---
name: agent-creator-helpers
description: INTERNAL reference — shared decision trees, matrices, and guides used by the agent-creator skill. Not for direct invocation.
---

# Agent Creator — Shared Reference

This file is loaded by the `agent-creator` skill. It contains all decision trees, matrices, and classification guides referenced during wizard phases. Do not invoke directly.

---

## 1. Agent Type Decision Tree

Use the user's answers from Phase 1 (Discovery) to classify the agent type.

```
Q1: Does the agent need to maintain state across multiple steps toward a goal?
  NO  → REACTIVE
        Use when: simple lookup, single-pass analysis, rule-based filter
        Examples: "find all TODO comments", "check if a file exists"

  YES → Q2: Does the agent need to coordinate or delegate to other agents?
          YES → MULTI-AGENT ORCHESTRATOR
                Use when: task requires multiple specializations working together
                Examples: "review, test, and document this PR", "analyse, refactor, then verify"
                Key config: tools must include Agent(<name>) for each worker

          NO  → Q3: Is the task bounded (clear start, clear end)?
                  YES → DELIBERATIVE
                        Use when: well-scoped task requiring planning before acting
                        Pattern: Plan-and-Execute (decompose → step through → verify)
                        Examples: "refactor this module", "write tests for this class"
                        Key config: permissionMode=plan or acceptEdits; maxTurns cap recommended

                  NO  → AUTONOMOUS
                        Use when: open-ended, long-horizon, self-directed task
                        Pattern: ReAct loop (reason → act → observe → repeat)
                        Examples: "investigate and fix this bug", "continuously monitor logs"
                        Key config: maxTurns=0 or high cap; memory recommended; consider background=true
```

**Conversational** (not in the tree above): use when the agent's primary mode is multi-turn dialog with the user — no autonomous action loops. This is uncommon for Claude Code agents; most tasks are better served by deliberative agents with `AskUserQuestion` for clarification.

---

## 2. Tool Recommendation Matrix

Apply rules top-to-bottom. Start with the minimal read-only set and add tools only when a rule fires.

**Base set (always start here)**
```
Read, Glob, Grep
```

**Add tools based on capabilities needed**

| If the agent needs to...                          | Add these tools           | Also consider                        |
|---------------------------------------------------|---------------------------|--------------------------------------|
| Browse the web / read external documentation      | WebSearch, WebFetch       | —                                    |
| Create new files                                  | Write                     | isolation: worktree                  |
| Modify existing files                             | Edit                      | isolation: worktree                  |
| Run shell commands, scripts, or CLI tools         | Bash                      | PreToolUse hook (validate-bash.sh)   |
| Execute database queries                          | Bash                      | permissionMode: plan; hook to block DDL |
| Spawn sub-agents for delegated tasks              | Agent(name1), Agent(name2)| List only the agents it may invoke   |
| Pause and ask the user a clarifying question      | AskUserQuestion           | —                                    |
| Invoke a Claude Code skill                        | Skill                     | —                                    |
| Access an external system via MCP                 | (add mcpServers field)    | List only the servers needed         |

**Deny-list shortcuts** (use `disallowedTools` instead of omitting from `tools`):
- Read-only agent that should never write: `disallowedTools: Write, Edit, Bash`
- Agent that can edit but must not execute: `disallowedTools: Bash`

**Isolation rule**
```
IF tools include Bash AND (Write OR Edit) AND the agent touches production paths
  → set isolation: worktree
```

---

## 3. Model Selection Guide

| Model    | Cost  | Speed  | Best for                                                              |
|----------|-------|--------|-----------------------------------------------------------------------|
| `haiku`  | Low   | Fast   | Simple lookup, read-only search, documentation, short-burst tasks     |
| `sonnet` | Med   | Med    | Most tasks: code review, refactoring, testing, generation, DevOps     |
| `opus`   | High  | Slower | Complex reasoning: security audits, architecture, multi-step planning |
| `inherit`| —     | —      | Delegate model choice to the parent session (default if omitted)      |

**Heuristics**
- Default to `sonnet` when unsure
- Use `haiku` only for agents that are purely read-only and produce short outputs
- Use `opus` when the agent's mistakes are expensive (security, infra, data migrations)
- Never use `haiku` for agents with `Bash` or `Write` — the cost of a wrong command outweighs token savings

---

## 4. Permission Mode Guide

| Mode               | What it does                                                        | Use when                                          |
|--------------------|---------------------------------------------------------------------|---------------------------------------------------|
| `plan`             | Shows full plan before ANY tool call; user approves each step       | High-stakes agents: DB, infra, security fixes     |
| `default`          | Prompts for file writes and shell commands; auto-approves reads     | Standard agents that modify files or run commands |
| `acceptEdits`      | Auto-approves Write/Edit; prompts for Bash only                     | Agents that modify code but don't run commands    |
| `auto`             | Auto-approves most actions; prompts only for destructive operations | Trusted automation in well-understood codebases   |
| `bypassPermissions`| Full autonomy, no prompts                                           | CI/CD pipelines only; never for interactive use   |

**Decision rule**
```
Agent uses Bash?
  YES + touches production/DB/infra → plan
  YES + limited to test runners      → default
  NO  + modifies files               → acceptEdits
  NO  + read-only                    → default (reads never prompt anyway)
Fully automated CI context?          → bypassPermissions
```

---

## 5. Memory Scope Guide

| Scope     | Storage location                          | Git-tracked | Shared with team | Use when                                          |
|-----------|-------------------------------------------|-------------|------------------|---------------------------------------------------|
| (none)    | —                                         | —           | —                | Stateless agent; no cross-session persistence needed |
| `local`   | `.claude/agent-memory-local/<name>/`      | No          | No               | Developer-private notes; not for commit           |
| `project` | `.claude/agent-memory/<name>/`            | Yes         | Yes              | Team-shared domain knowledge; pre-seeded MEMORY.md |
| `user`    | `~/.claude/agent-memory/<name>/`          | No          | No               | Personal agent preferences; machine-local         |

**Decision rule**
```
Agent needs to remember facts across sessions?
  NO  → omit memory field
  YES → will multiple team members use this agent?
          YES → project
          NO  → user
        Should memory be committed to git?
          YES → project
          NO  → local
```

**MEMORY.md**: When `memory` is set and a pre-seeded `MEMORY.md` exists, it is injected into the agent's context at startup (first 200 lines). This is how domain knowledge from books/files persists across sessions.

---

## 6. Knowledge Tier Definitions

Every agent generated by `agent-creator` must have a knowledge tier comment in its frontmatter. This communicates the reliability of the agent's domain knowledge at a glance.

| Tier | Source                                        | Frontmatter comment format                                              | MEMORY.md |
|------|-----------------------------------------------|-------------------------------------------------------------------------|-----------|
| A    | O'Reilly book (user confirmed access)         | `# knowledge-tier: A — [Title] by [Author], [Year]`                    | Write      |
| B    | User-provided file (PDF, .md, .txt, etc.)     | `# knowledge-tier: B — user-provided: [filename]`                      | Write      |
| C    | Official documentation (WebFetch/WebSearch)   | `# knowledge-tier: C — official docs: [domain] (fetched [date])`       | Write      |
| D    | Interactive Q&A with user                     | `# knowledge-tier: D — domain knowledge provided by team ([date])`     | Write      |
| E    | Training data only (no external source)       | `# knowledge-tier: E — WARNING: no authoritative source used`          | Skip       |

**Rules**
- Never omit the tier comment — Tier E must be explicit, not silent
- If multiple sources were used (e.g., O'Reilly search + user .md file), cite both and assign the higher tier (lower letter = higher quality)
- Update the tier comment when `--enrich` is run

---

## 7. Effort Level Guide

| Level    | Use when                                                              |
|----------|-----------------------------------------------------------------------|
| `low`    | Fast lookups, simple reads, haiku-class tasks                         |
| `medium` | Standard tasks (default for most agents)                              |
| `high`   | Complex analysis, multi-file refactors, security audits               |
| `xhigh`  | Extended reasoning tasks; expensive — use sparingly                   |
| `max`    | Reserved for the most demanding tasks; pairs with `opus` model        |

---

## 8. Background Mode Guide

| background | Use when                                                                          |
|------------|-----------------------------------------------------------------------------------|
| `false`    | Agent needs user interaction (AskUserQuestion) or produces output to review now   |
| `true`     | Long-running agent where user continues working while it runs (monitoring, indexing) |

**Note**: Background agents auto-deny tool calls that would normally prompt the user. Ensure the agent's permission mode and tool set are compatible with unattended execution before setting `background: true`.

---

## 9. maxTurns Guide

| Value         | Use when                                                           |
|---------------|--------------------------------------------------------------------|
| omit          | No cap — agent runs until task complete or context limit           |
| 5–10          | Simple, bounded tasks (single-file review, targeted lookup)        |
| 15–25         | Standard multi-step tasks (refactor, test suite generation)        |
| 50+           | Long-horizon autonomous tasks                                      |
| 0             | Unlimited (explicit) — use only for open-ended autonomous agents   |

**Rule of thumb**: If the task has a clear completion condition, set a cap. If the agent runs away from its task, a cap prevents wasted tokens.

---

## 10. Safety Hook Selection Guide

Offer these hook snippets when the agent's tool set includes the trigger tool.

| Trigger tool  | Hook to offer                          | Script                          |
|---------------|----------------------------------------|---------------------------------|
| `Bash`        | Destructive command blocker            | `scripts/validate-bash.sh`      |
| `Write`/`Edit`| Write path scope limiter               | `scripts/check-write-path.sh`   |

**Hook frontmatter snippet** (embed in agent file when accepted by user):
```yaml
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "scripts/validate-bash.sh"
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "scripts/check-write-path.sh"
```
