# Fase 4 — Desenho de comportamento

*Referência da skill `agent-creator` — leia ao ENTRAR nesta fase. O roteiro e a ordem estão no `SKILL.md`.*

## Phase 4 — Behavior Design

**Read `${CLAUDE_PLUGIN_ROOT}/references/agent-authoring-conventions.md` now, before drafting.** It is the
kit's own standard for what a good agent file contains — the anatomy of the body, the four uncertainty
policies, the anti-patterns, and the review checklist in §8. An agent generated without it fails the
checklist the kit itself publishes.

**Goal**: write the agent's system prompt body — the text that appears after the frontmatter in the `.md` file. Ground it in the domain knowledge from Phase 2 and the architecture decisions from Phase 3.

**Target**: produce a complete draft and show it for review in one exchange.

---

### 4.1 — Draft the identity statement

The first line of the system prompt must be a strong, specific identity declaration.

Template:
```
You are a [DOMAIN] specialist[, trained on [KNOWLEDGE_SOURCE_TITLE] ([KNOWLEDGE_SOURCE_AUTHOR], [YEAR])].
```

Rules:
- If `KNOWLEDGE_TIER` is A or B: include the "trained on" clause with book/file citation
- If `KNOWLEDGE_TIER` is C: append "informed by [domain] official documentation"
- If `KNOWLEDGE_TIER` is D: append "informed by [team name]'s domain knowledge"
- If `KNOWLEDGE_TIER` is E: omit the clause — just "You are a [DOMAIN] specialist."
- Keep it to one sentence. No filler ("You are a highly skilled..." → drop "highly skilled")

Set `IDENTITY_STATEMENT`.

---

### 4.2 — Draft the primary responsibilities

Write a bullet list of 4–7 concrete responsibilities derived from `AGENT_PURPOSE` and `KNOWLEDGE_CONTENT`.

Rules for each bullet:
- Start with an active verb (Analyze, Generate, Identify, Apply, Validate, Refactor, Debug...)
- Be specific to the domain — reference actual patterns, tools, or concepts from `KNOWLEDGE_CONTENT`
- If `KNOWLEDGE_TIER=E`, write generic but reasonable responsibilities based on the domain
- Do not pad with vague items like "provide helpful responses" or "assist the user"

Examples of good bullets (Kubernetes agent):
- "Apply Sidecar, Ambassador, and Adapter patterns when augmenting workloads"
- "Prefer StatefulSets for stateful workloads; use Deployments for stateless services"
- "Validate resource requests/limits on every pod spec before recommending it"

Examples of bad bullets (reject these patterns):
- "Help the user with Kubernetes tasks" ← too vague
- "Be knowledgeable about all Kubernetes topics" ← not actionable
- "Provide best-in-class Kubernetes guidance" ← marketing copy

If `KNOWLEDGE_CONTENT` has `decision_heuristics`, weave at least 2 of them into the responsibilities list.

Set `RESPONSIBILITIES_LIST`.

---

### 4.3 — Draft the constraints block

Write a bullet list of 3–5 things the agent must NOT do. These are hard stops — non-negotiable.

Always include:
- If `ACCESS_LEVEL=read-only`: "Do not create, modify, or delete any files."
- If `ACCESS_LEVEL=read-write` and `Bash` not in tools: "Do not execute shell commands or run scripts."
- If `KNOWLEDGE_CONTENT` has `safety_rules`: include each one verbatim

Domain-appropriate additions based on `DOMAIN`:
- Database domains: "Do not execute DDL (CREATE, DROP, ALTER) without explicit user confirmation."
- Infra/DevOps: "Do not apply infrastructure changes without showing a plan first."
- Security auditor: "Do not suggest disabling security controls as a workaround."
- Refactoring: "Do not change behavior — preserve semantics; rename and restructure only."
- Test agents: "Do not modify production source code — write tests only."

If `KNOWLEDGE_CONTENT` has `anti_patterns`, add the most critical one as a constraint if it isn't already covered.

Set `CONSTRAINTS_LIST`.

---

### 4.4 — Draft the failure handling block

Write a short paragraph or 2–3 bullets on how the agent should handle errors and uncertainty.

Always include:
- What to do when a tool call fails (retry once, then report the error with context)
- What to do when the task is ambiguous (ask one clarifying question — not multiple)
- What to do when confidence is low (state the uncertainty explicitly, do not guess silently)

If `KNOWLEDGE_CONTENT` has `common_failures`, add a "Debugging playbook" section:
```
## Debugging Playbook
[symptom]: [diagnosis steps]
[symptom]: [diagnosis steps]
```

Set `FAILURE_HANDLING`.

---

### 4.5 — Draft safety hook configuration (if needed)

If `NEEDS_HOOK=true`:

Offer the user the relevant hook snippet from `agent-creator-helpers.md` section 10.

Present as:
```
This agent uses [Bash / Write / Edit]. I recommend adding a safety hook to prevent
accidental destructive operations.

Proposed hook:
[paste the relevant hook YAML snippet]

Add this hook? (yes / no / customize)
```

If yes → set `HOOK_CONFIG` to the snippet.
If no → set `HOOK_CONFIG=null`.
If customize → ask what pattern to block, then adapt the snippet.

If `NEEDS_HOOK=false` → skip this step, set `HOOK_CONFIG=null`.

---

### 4.6 — Draft MEMORY.md content (if applicable)

If `KNOWLEDGE_TIER` is A, B, C, or D AND `MEMORY_SCOPE` is not `none`:

Build the MEMORY.md content from `KNOWLEDGE_CONTENT`:

```markdown
# [DOMAIN] Specialist — Domain Knowledge
Source: [KNOWLEDGE_SOURCE_TITLE][, [KNOWLEDGE_SOURCE_AUTHOR], [KNOWLEDGE_SOURCE_YEAR]]
Knowledge tier: [KNOWLEDGE_TIER] | Extracted: [current date]

## Core Patterns
[for each entry in core_patterns]
- **[name]**: [when_to_use][. Example: [example] if present]

## Decision Heuristics
[for each entry in decision_heuristics]
- [rule]

## Key Commands
[for each entry in key_commands]
- `[command]`

## Anti-Patterns to Avoid
[for each entry in anti_patterns]
- **[name]**: [problem][. Instead: [instead] if present]

## Debugging Playbook
[for each entry in common_failures]
- **[symptom]**: [diagnosis][. Fix: [fix] if present]

## Safety Rules
[for each entry in safety_rules]
- [constraint]
```

Omit any section that has no entries. Keep MEMORY.md under 200 lines — trim to most important entries if needed (MEMORY.md is injected at startup, first 200 lines only).

Set `MEMORY_CONTENT`.

If `KNOWLEDGE_TIER=E` → set `MEMORY_CONTENT=null`. **Tier E only.**

> **Tier D writes MEMORY.md — never skip it.** Tier D knowledge was captured from the user in
> conversation: it exists in no book, no file and no URL. If it is not persisted here, it is **lost**, and
> the agent ends up with a tier comment pointing at knowledge it does not have. This is silent — the user
> only notices much later, if ever. The tier table in `helpers.md` §6 is the authority.

---

### 4.7 — Show the full draft for review

**Before presenting, run the draft against the review checklist in §8 of
`agent-authoring-conventions.md`** and fix what fails. The two failures seen in practice:

- the identity statement says who the agent is and what it is anchored in, but **omits what it is NOT** —
  the boundary with neighbouring agents, which is what orients a thousand small decisions;
- the `description` does not differentiate the agent from similar skills already in the environment.

Present the complete system prompt body and (if applicable) the MEMORY.md in one message:

```
Here's the system prompt I drafted. Review it and tell me what to change.

---
[IDENTITY_STATEMENT]

## Responsibilities
[RESPONSIBILITIES_LIST — formatted as bullets]

## Constraints
[CONSTRAINTS_LIST — formatted as bullets]

## Handling Uncertainty and Errors
[FAILURE_HANDLING]
---

[If MEMORY_CONTENT is set:]
The agent's MEMORY.md will be pre-seeded with:
---
[MEMORY_CONTENT — first 30 lines as preview, with "... [N more lines]" if longer]
---

[If HOOK_CONFIG is set and user confirmed:]
Safety hook will be added to frontmatter.

Does this look right? You can:
- Ask me to rewrite any section
- Add domain-specific instructions ("also make it do X")
- Remove anything that doesn't fit
- Or say "looks good" to continue
```

Wait for the user's response.

---

### 4.8 — Apply revisions

If the user requests changes:
- Apply them directly — do not re-show the entire prompt unless the user asks
- Show only the changed section with the diff described in plain language:
  > "Updated Responsibilities: added bullet about X, removed bullet about Y."
- Ask: "Anything else, or shall I continue to Phase 5?"

Once confirmed, store final values:
- `SYSTEM_PROMPT_BODY` = identity + responsibilities + constraints + failure handling
- `MEMORY_CONTENT` = final MEMORY.md text (or null)
- `HOOK_CONFIG` = hook YAML (or null)

Proceed to Phase 5 immediately.

---
