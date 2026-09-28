# Fase 2 — Descoberta de conhecimento (tiers A–E)

*Referência da skill `agent-creator` — leia ao ENTRAR nesta fase. O roteiro e a ordem estão no `SKILL.md`.*

## Phase 2 — Knowledge Discovery

**Goal**: find authoritative domain knowledge to inject into the agent's system prompt and MEMORY.md, so the agent is genuinely expert rather than just labeled.

**Knowledge tier definitions** are in `agent-creator-helpers.md` section 6. Assign the highest tier (lowest letter A–E) achievable.

---

### 2.1 — Skip condition

If `DOMAIN` is a well-known general-purpose technology with rich training data (e.g. "Python", "Git", "HTML", "bash scripting") AND the user did not provide an inline description suggesting specialized/internal knowledge, you may offer to skip:

> "The domain '[DOMAIN]' is well-covered in training data. Do you want to add a specific book or doc to make the agent more precise, or should I proceed with training data (Tier E)?"

If user says skip → set `KNOWLEDGE_TIER=E`, `KNOWLEDGE_CONTENT=null`, jump to Phase 3.

---

### 2.2 — Search O'Reilly MCP

For all other domains, search O'Reilly first. Use the `mcp__oreilly__search_oreilly_content` tool:

```
query: "[DOMAIN] patterns best practices"
content_types: ["books"]
n_items: 5
```

If the search returns results, format the top 3 as:

```
I searched O'Reilly for authoritative sources on [DOMAIN] and found:

1. [Title] — [Author(s)] ([Year], [N] pages)
2. [Title] — [Author(s)] ([Year], [N] pages)
3. [Title] — [Author(s)] ([Year], [N] pages)

Do you have O'Reilly access to any of these?
Also — do you have any local files (PDF, .md, exported docs, runbooks) on this domain?

(You can answer both: e.g. "yes to #2, and I also have /path/to/runbook.md")
```

If the search returns no results, skip to 2.4.

---

### 2.3 — Branch on user answer

#### Branch A — User confirms O'Reilly access

Set `KNOWLEDGE_TIER=A`.

Note the confirmed book: `KNOWLEDGE_SOURCE_TITLE`, `KNOWLEDGE_SOURCE_AUTHOR`, `KNOWLEDGE_SOURCE_YEAR`.

Since the O'Reilly MCP returns metadata only (not chapter text), supplement with targeted web searches:

1. Use `WebSearch` with: `"[KNOWLEDGE_SOURCE_TITLE]" [DOMAIN] key patterns best practices`
2. Use `WebSearch` with: `"[KNOWLEDGE_SOURCE_TITLE]" [DOMAIN] anti-patterns common mistakes`
3. If results include the publisher's official page or a trusted summary, use `WebFetch` to extract specific content.

Synthesize the search findings into `KNOWLEDGE_CONTENT` using this structure:
```
core_patterns: [list from search results]
anti_patterns: [list from search results]
key_commands: [any specific commands/snippets found]
decision_heuristics: [any "use X when Y" rules found]
common_failures: [any troubleshooting info found]
source_provenance: {title, author, year, source_type: "book", note: "O'Reilly metadata + web search"}
```

Note: mark `confidence: medium` since full chapter text was not available — only metadata + web synthesis.

Tell the user:
> "Using [KNOWLEDGE_SOURCE_TITLE] as the knowledge source (Tier A). I searched for its key concepts online since the O'Reilly MCP provides metadata only — full chapter access would give a richer result. Continuing with what I found."

#### Branch B — User provides a local file

One or more file paths were provided (PDF, .md, .txt, .adoc, .rst, or any readable format).

For each file path provided:

Invoke the `knowledge-extractor` agent:
```
@"knowledge-extractor (agent)" Extract domain knowledge from [FILE_PATH] for a [DOMAIN] specialist agent.
```

Wait for the agent to return its structured YAML.

If multiple files were provided, invoke the extractor for each and merge the results (deduplicate entries across lists).

Set `KNOWLEDGE_TIER=B`.
Set `KNOWLEDGE_CONTENT` = the merged extracted YAML.
Set `KNOWLEDGE_SOURCE_TITLE` = filename(s).

Tell the user:
> "Extracted domain knowledge from [filename(s)] (Tier B). Found [N] patterns, [N] heuristics, [N] commands. This will be injected into the agent's system prompt and MEMORY.md."

If the user also confirmed O'Reilly access (answered both), set `KNOWLEDGE_TIER=A` (higher tier wins) and combine both knowledge sets.

#### Branch C — User has neither

Proceed to 2.4.

---

### 2.4 — Tier C: WebSearch + WebFetch fallback

If no O'Reilly book was confirmed and no local file was provided:

Run targeted searches for official documentation:

1. `WebSearch`: `[DOMAIN] official documentation site:docs.[domain].io OR site:documentation.[domain].com`
2. `WebSearch`: `[DOMAIN] best practices guide patterns [current year]`
3. If promising official docs URL found: `WebFetch` with prompt: "Extract patterns, anti-patterns, commands, and best practices for [DOMAIN]"

If useful content found:
- Set `KNOWLEDGE_TIER=C`
- Build `KNOWLEDGE_CONTENT` from what was found
- Set `KNOWLEDGE_SOURCE_TITLE` = URL(s) used

Tell the user:
> "Found official documentation for [DOMAIN] (Tier C). Using this as the knowledge source — less authoritative than a book, but better than nothing."

If web search yields nothing useful (vague results, no official docs), fall through to 2.5.

---

### 2.5 — Tier D: Interactive Q&A

If all automated sources failed or the domain is internal/proprietary (training data wouldn't know it):

Tell the user:
> "I couldn't find an authoritative source for '[DOMAIN]' — this may be internal tooling or a niche area. Let me ask you a few questions to capture your team's knowledge directly."

Ask these 5 questions in one message:

```
1. What are the 2–4 most important patterns or principles in this domain?
   (e.g. "always use X for Y", "prefer A over B because C")
2. What are the most common mistakes practitioners make?
3. What specific commands, tools, or APIs does this domain rely on?
   (include real examples if you can)
4. Are there any hard rules — things this agent must NEVER do?
5. What does a correct result look like for a typical task?
```

After receiving answers:
- Set `KNOWLEDGE_TIER=D`
- Structure answers into `KNOWLEDGE_CONTENT` using the extraction template
- Set `KNOWLEDGE_SOURCE_TITLE` = "team domain knowledge ([date])"

Tell the user:
> "Captured your team's domain knowledge (Tier D). This will be attributed in the agent file and MEMORY.md."

---

### 2.6 — Tier E: Training data fallback

If the user explicitly skipped knowledge discovery (from 2.1) or declined all options:

- Set `KNOWLEDGE_TIER=E`
- Set `KNOWLEDGE_CONTENT=null`

Tell the user:
> "Proceeding with training data only (Tier E). The agent will be functional but not grounded in a specific authoritative source. You can enrich it later with `/agent-creator --enrich [name] /path/to/file`."

---

### 2.7 — Phase 2 summary

Before moving to Phase 3, confirm what was found:

```
Knowledge discovery complete:

- **Tier**: [A/B/C/D/E] — [source description]
- **Patterns found**: [N] (or "none — training data only")
- **Heuristics found**: [N]
- **Commands found**: [N]
- **MEMORY.md**: will be pre-seeded  (or "not applicable for Tier E")

Ready to design the agent architecture. Continuing to Phase 3...
```

Proceed to Phase 3 immediately — no user confirmation needed here.

---
