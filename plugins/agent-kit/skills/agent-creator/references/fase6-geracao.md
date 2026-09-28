# Fase 6 — Geração, validação e escrita

*Referência da skill `agent-creator` — leia ao ENTRAR nesta fase. O roteiro e a ordem estão no `SKILL.md`.*

## Phase 6 — Generation, Validation, and Write

**Goal**: assemble the complete agent file, validate every field, write the file(s), and hand the user a working invocation command.

**Target**: no more user questions — this phase runs to completion automatically.

---

### 6.1 — Derive the agent name

Generate a `name` from `AGENT_PURPOSE` and `DOMAIN`:

Rules:
- kebab-case only: lowercase letters, numbers, hyphens — no spaces, underscores, or special characters
- 2–4 words maximum: `[domain]-[role]` or `[domain]-[role]-[qualifier]`
- Examples: `kubernetes-specialist`, `postgres-analyst`, `react-code-reviewer`, `billing-system-auditor`
- Do not include "agent" in the name — it's redundant
- If the name would collide with a built-in agent type (`general-purpose`, `Explore`, `Plan`), add a domain prefix

Set `AGENT_NAME`.

---

### 6.2 — Derive the description line

The `description` field is the one-line text Claude uses for **automatic agent selection**. It must be:
- A complete sentence describing when to invoke this agent
- Specific enough to distinguish it from other agents
- 10–120 characters

Template: `"[Domain] specialist for [primary use case]. Use for [trigger condition].")`

Examples:
- `"Kubernetes deployment specialist. Use for workload design, troubleshooting, and resource configuration."`
- `"PostgreSQL analyst. Use for query optimization, schema review, and performance diagnosis."`

Set `AGENT_DESCRIPTION`.

---

### 6.3 — Assemble the frontmatter

Build the complete YAML frontmatter block. Include only fields with non-null values — omit optional fields that were not set.

```yaml
---
name: [AGENT_NAME]
description: [AGENT_DESCRIPTION]
# knowledge-tier: [KNOWLEDGE_TIER] — [KNOWLEDGE_SOURCE_TITLE][, [KNOWLEDGE_SOURCE_AUTHOR], [KNOWLEDGE_SOURCE_YEAR]]
tools: [TOOL_LIST as comma-separated string]
model: [MODEL]
permissionMode: [PERMISSION_MODE]
[if MAX_TURNS is not null:]
maxTurns: [MAX_TURNS]
[if MEMORY_SCOPE is not none:]
memory: [MEMORY_SCOPE]
[if EFFORT != medium:]
effort: [EFFORT]
[if ISOLATION = worktree:]
isolation: worktree
[if BACKGROUND = true:]
background: true
[if SKILLS_LIST is not null:]
skills:
  - [skill1]
  - [skill2]
[if MCP_SERVERS_LIST is not null:]
mcpServers:
  - [server1]
[if HOOK_CONFIG is not null:]
[HOOK_CONFIG YAML — indented correctly]
color: [COLOR]
---
```

For the knowledge-tier comment:
- Tier E: `# knowledge-tier: E — WARNING: no authoritative source used. Enrich with /agent-creator --enrich [AGENT_NAME] <file>`
- Tier A: `# knowledge-tier: A — [KNOWLEDGE_SOURCE_TITLE], [KNOWLEDGE_SOURCE_AUTHOR] ([KNOWLEDGE_SOURCE_YEAR])`
- Tier B: `# knowledge-tier: B — user-provided: [KNOWLEDGE_SOURCE_TITLE]`
- Tier C: `# knowledge-tier: C — official docs: [DOMAIN] (fetched [today's date])`
- Tier D: `# knowledge-tier: D — domain knowledge provided by team ([today's date])`

---

### 6.4 — Validate the frontmatter

Before writing, check every field. If any check fails, fix it automatically and note the correction — do not ask the user.

| Field | Check | Auto-fix if failing |
|-------|-------|---------------------|
| `name` | kebab-case, no spaces/special chars, 2–4 words | strip invalid chars, lowercase, truncate |
| `description` | present, ≥10 chars, ≤120 chars | truncate at word boundary if >120 |
| `tools` | each tool name is in the valid list below | remove unknown tool names, log removed names |
| `model` | one of: `sonnet`, `opus`, `haiku`, `inherit`, or a full `claude-*` model ID | default to `sonnet` |
| `permissionMode` | one of: `default`, `acceptEdits`, `auto`, `plan`, `bypassPermissions` | default to `default` |
| `maxTurns` | positive integer if set | clamp to 1 minimum |
| `effort` | one of: `low`, `medium`, `high`, `xhigh`, `max` | default to `medium` |
| `isolation` | `worktree` if set | remove if invalid value |
| `color` | one of the 8 valid colors | default to `blue` |

**Valid tool names**:
`Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch, Agent, AskUserQuestion, Skill, NotebookEdit`
Plus any `Agent(name)` restricted form, and any MCP tool names from `mcpServers`.

If any corrections were made, note them briefly after writing:
> "Auto-corrected: removed unknown tool 'Fetch' (did you mean 'WebFetch'?)"

---

### 6.5 — Determine output paths

```
SCOPE=project  → AGENT_FILE_PATH = .claude/agents/[AGENT_NAME].md
SCOPE=user     → AGENT_FILE_PATH = ~/.claude/agents/[AGENT_NAME].md

MEMORY_SCOPE=project → MEMORY_FILE_PATH = .claude/agent-memory/[AGENT_NAME]/MEMORY.md
MEMORY_SCOPE=user    → MEMORY_FILE_PATH = ~/.claude/agent-memory/[AGENT_NAME]/MEMORY.md
MEMORY_SCOPE=local   → MEMORY_FILE_PATH = .claude/agent-memory-local/[AGENT_NAME]/MEMORY.md
MEMORY_SCOPE=none    → MEMORY_FILE_PATH = null
```

Check whether `AGENT_FILE_PATH` already exists. If it does, warn the user before overwriting:
> "⚠ An agent named '[AGENT_NAME]' already exists at [AGENT_FILE_PATH]. Overwrite? (yes / no / rename)"
If "rename", ask for a new name, update `AGENT_NAME` and re-derive `AGENT_FILE_PATH`.

---

### 6.6 — Write the agent file

Assemble the complete file content:

```
[frontmatter block from 6.3]

[SYSTEM_PROMPT_BODY from Phase 4]
```

Write to `AGENT_FILE_PATH`. Create parent directories if they don't exist.

---

### 6.7 — Write MEMORY.md (if applicable)

If `MEMORY_FILE_PATH` is not null and `MEMORY_CONTENT` is not null:

Create parent directory if needed, then write `MEMORY_CONTENT` to `MEMORY_FILE_PATH`.

---

### 6.8 — Offer settings.json registration

Ask once:
```
Add Agent([AGENT_NAME]) to .claude/settings.json permissions allow-list
so it can be invoked without a manual approval prompt? (yes / no)
```

If yes: read `.claude/settings.json`, add `"Agent([AGENT_NAME])"` to `permissions.allow`, write it back.
If the file doesn't exist, create it with the minimal structure:
```json
{
  "permissions": {
    "allow": ["Agent([AGENT_NAME])"]
  }
}
```
If no: skip silently.

---

### 6.9 — Final output

Print the completion message:

```
Agent created successfully.

📄 File:    [AGENT_FILE_PATH]
[if MEMORY_FILE_PATH:]
🧠 Memory:  [MEMORY_FILE_PATH] ([N lines] of domain knowledge pre-seeded)
[if settings.json updated:]
⚙  Settings: Agent([AGENT_NAME]) added to permissions allow-list

─────────────────────────────────────────────
Invoke it:
  @"[AGENT_NAME] (agent)" [sample task based on AGENT_PURPOSE]

Or ask Claude to use it:
  "Use the [AGENT_NAME] agent to [AGENT_PURPOSE]"
─────────────────────────────────────────────

Knowledge tier: [KNOWLEDGE_TIER]
[Tier A]: Grounded in [KNOWLEDGE_SOURCE_TITLE] ([KNOWLEDGE_SOURCE_AUTHOR], [YEAR])
[Tier B]: Grounded in [KNOWLEDGE_SOURCE_TITLE] (user-provided file)
[Tier C]: Informed by [DOMAIN] official documentation
[Tier D]: Informed by team domain knowledge
[Tier E]: ⚠ No authoritative source — enrich later:
           /agent-creator --enrich [AGENT_NAME] /path/to/your/book-or-doc

Want to run a quick smoke test? I can invoke the agent now with a simple task to verify it responds correctly. (yes / no)
```

If yes to smoke test: invoke `@"[AGENT_NAME] (agent)"` with a short, read-only sample task appropriate to the domain, and report whether it responds as expected.

---
