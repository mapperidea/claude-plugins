# Fluxo `--knowledge-source`

*Referência da skill `agent-creator` — leia ao ENTRAR nesta fase. O roteiro e a ordem estão no `SKILL.md`.*

## Knowledge Search Flow — `--knowledge-source <domain>`

Entered when `KNOWLEDGE_DOMAIN` is set. Pure discovery mode — searches O'Reilly for authoritative sources on a domain and displays results. Does not create or modify any agent.

---

### K1 — Run broad O'Reilly search

Run two searches in parallel to get good coverage:

Search 1 — books focused on patterns and best practices:
```
mcp__oreilly__search_oreilly_content(
  query="[KNOWLEDGE_DOMAIN] patterns best practices guide",
  content_types=["books"],
  n_items=5
)
```

Search 2 — books focused on production and applied use:
```
mcp__oreilly__search_oreilly_content(
  query="[KNOWLEDGE_DOMAIN] production applied engineering",
  content_types=["books"],
  n_items=5
)
```

Merge results, deduplicate by `ourn`, keep up to 8 unique books sorted by relevance score descending.

---

### K2 — Format and display results

Present results in a structured table:

```
O'Reilly sources for: [KNOWLEDGE_DOMAIN]
─────────────────────────────────────────────────────────────────

 #  Title                                    Author(s)              Year   Pages
────────────────────────────────────────────────────────────────────────────────
 1  [Title]                                  [Authors]              [Year] [N]p
 2  [Title]                                  [Authors]              [Year] [N]p
...

─────────────────────────────────────────────────────────────────
Best for agent creation:
  → Tier A (O'Reilly access confirmed): use #[highest-relevance result]
  → Tier B (local file):               provide a PDF or .md export of any of the above

To create an agent using one of these sources:
  /agent-creator "[KNOWLEDGE_DOMAIN] specialist"

To enrich an existing agent with a local file:
  /agent-creator --enrich <agent-name> /path/to/file
```

For the "Best for agent creation" line, recommend the top result by relevance score as the Tier A candidate. If the top result is a very recent early-release book (publication date in the future), note it:
> "(early release — content may be incomplete)"

---

### K3 — Supplement with web sources

After the O'Reilly results, run a quick web search to surface official docs:

```
WebSearch: "[KNOWLEDGE_DOMAIN] official documentation site"
```

If official docs are found, append:

```
Official documentation:
  → [Domain name] docs: [URL]
  (use as Tier C source if no book access)
```

If no useful official docs found, omit this section silently.

---

### K4 — Exit

This flow is read-only. Do not create any files, prompt for agent details, or continue into the wizard. Exit after displaying results.
