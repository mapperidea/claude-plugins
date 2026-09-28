# Fluxo `--enrich`

*Referência da skill `agent-creator` — leia ao ENTRAR nesta fase. O roteiro e a ordem estão no `SKILL.md`.*

## Enrich Flow — `--enrich <agent-name> [file]`

Entered when `ENRICH_TARGET` is set. Refreshes domain knowledge in an existing agent without re-running the full wizard.

---

### E1 — Locate the existing agent file

Determine the agent file path by checking in order:
1. `.claude/agents/[ENRICH_TARGET].md`
2. `~/.claude/agents/[ENRICH_TARGET].md`

If neither exists:
> "No agent named '[ENRICH_TARGET]' found in .claude/agents/ or ~/.claude/agents/. Check the name and try again."
Exit.

Set `AGENT_FILE_PATH` to whichever was found.

---

### E2 — Read existing agent state

Read `AGENT_FILE_PATH`. Extract:
- `EXISTING_TIER` — from the `# knowledge-tier:` comment in frontmatter
- `EXISTING_SOURCE` — the source description from the same comment
- `EXISTING_MEMORY_SCOPE` — from the `memory:` frontmatter field (`user`, `project`, `local`, or absent)
- `EXISTING_SYSTEM_PROMPT` — the body text after the closing `---` of the frontmatter
- `EXISTING_DOMAIN` — infer from the agent name and identity statement in the system prompt

Determine the MEMORY.md path:
```
memory: project → .claude/agent-memory/[ENRICH_TARGET]/MEMORY.md
memory: user    → ~/.claude/agent-memory/[ENRICH_TARGET]/MEMORY.md
memory: local   → .claude/agent-memory-local/[ENRICH_TARGET]/MEMORY.md
(absent)        → null
```

If MEMORY.md exists, read it as `EXISTING_MEMORY`. Otherwise set `EXISTING_MEMORY=null`.

---

### E3 — Determine new knowledge source

**If `ENRICH_FILE` was provided** (user ran `--enrich agent-name /path/to/file`):

Verify the file exists using `Read`. If not found:
> "File not found: [ENRICH_FILE]. Check the path and try again."
Exit.

Invoke the knowledge extractor:
```
@"knowledge-extractor (agent)" Extract domain knowledge from [ENRICH_FILE] for a [EXISTING_DOMAIN] specialist agent.
```

Wait for the structured YAML result. Set `NEW_KNOWLEDGE` = extracted YAML.
Set `NEW_SOURCE` = `ENRICH_FILE` filename.
Set `NEW_TIER` = `B`.

**If no file was provided** (user ran `--enrich agent-name` only):

Search O'Reilly for newer editions of the original source:
```
mcp__oreilly__search_oreilly_content(
  query="[EXISTING_SOURCE] [EXISTING_DOMAIN] patterns best practices",
  content_types=["books"],
  n_items=5
)
```

Present results:
```
Current knowledge source: [EXISTING_SOURCE] (Tier [EXISTING_TIER])

Newer or related sources found on O'Reilly:
1. [Title] — [Author] ([Year], [N]p)
2. ...

Options:
  a) Use one of these O'Reilly sources (confirm access, supplement with web search)
  b) Provide a local file → /agent-creator --enrich [ENRICH_TARGET] /path/to/file
  c) Re-run web search for latest [EXISTING_DOMAIN] official docs (Tier C refresh)
  d) Cancel
```

Process the user's choice:
- Option a → Tier A path from Phase 2 (web search supplement); set `NEW_TIER=A`
- Option b → tell user to re-run with a file path; exit
- Option c → targeted `WebSearch` + `WebFetch` for official docs; set `NEW_TIER=C`
- Option d → exit without changes

---

### E4 — Diff old vs new knowledge

Compare `NEW_KNOWLEDGE` against `EXISTING_MEMORY` (or the system prompt body if no MEMORY.md).

**Enrichment adds; it does not replace the agent's other sources.** An agent's knowledge can come from
several sources — typically a book or doc (Tier A/B/C) plus the team's own rules (Tier D), which exist
*nowhere else* but in MEMORY.md. So an entry counts as **Removed** only when it came from the **same
source being refreshed** (e.g. a newer edition of the same book dropped it). An entry from any other
source — above all a Tier D team rule — is **Unchanged**, never Removed, even if the new source does not
mention it. If the new source *contradicts* such an entry, list it under Updated and ask; don't overwrite
a team rule silently.

Build a change summary by matching entries on `name` or text:

```
Knowledge diff for [ENRICH_TARGET]:

✚ Added ([N]):
  Patterns:    [names]
  Heuristics:  [first few, "... and N more" if long]
  Commands:    [count]

✎ Updated ([N]):
  [name]: "[old snippet]…" → "[new snippet]…"

✖ Removed ([N]):
  [names — from the SAME source being refreshed, absent in its new version]

─ Unchanged: [N] entries

Knowledge tier: [EXISTING_TIER] → [NEW_TIER]
New source: [NEW_SOURCE]
```

If there are no changes:
> "No new knowledge found — the agent is already up to date with this source."
Exit without writing.

---

### E5 — Confirm before writing

```
Apply these changes to [ENRICH_TARGET]?

Will update:
  [x] [MEMORY_FILE_PATH]  (MEMORY.md)
  [x] [AGENT_FILE_PATH]   (responsibilities + identity statement in system prompt)
  [x] knowledge-tier comment in frontmatter

(yes / no / memory-only)
```

- `yes` → update MEMORY.md, system prompt body, and frontmatter comment
- `no` → exit without changes
- `memory-only` → update MEMORY.md and frontmatter comment only; leave system prompt body untouched

---

### E6 — Apply updates

**Update MEMORY.md**: merge `NEW_KNOWLEDGE` into `EXISTING_MEMORY` using the Phase 4 step 4.6 template —
add the new entries, apply the confirmed Updated/Removed ones, and **keep every entry from other
sources**. Label each section with its source (`*Fonte: docs/guia.md*`, `*Fonte: time (YYYY-MM-DD)*`) so
the next enrichment can tell which source owns what. Write to the existing path (or create if needed).

**Update system prompt** (if `yes`):
- Update the identity statement's "trained on" clause to cite the new source
- Merge new bullets into the Responsibilities section; keep the bullets that come from other sources
- Keep Constraints, Failure Handling, and any `## Custom` section unchanged

**Update frontmatter comment**: replace `# knowledge-tier:` line with new tier + source. When the old
sources remain in use, list them all (`B — user-provided: guia.md + domain knowledge provided by team
(date)`). Append `(updated [today's date])`.

---

### E7 — Completion message

```
[ENRICH_TARGET] enriched successfully.

Updated:
  [AGENT_FILE_PATH]
  [MEMORY_FILE_PATH]

Knowledge tier: [OLD_TIER] → [NEW_TIER]
Source: [NEW_SOURCE]
Changes: +[N added] ~[N updated] -[N removed]

Invoke to verify:
  @"[ENRICH_TARGET] (agent)" [sample task]
```

---
