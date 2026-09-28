# Fase 1 — Descoberta

*Referência da skill `agent-creator` — leia ao ENTRAR nesta fase. O roteiro e a ordem estão no `SKILL.md`.*

## Phase 1 — Discovery

**Goal**: understand what the agent needs to do well enough to classify it, select its tools, and find relevant knowledge sources.

**Target**: complete this phase in a single exchange — ask all questions at once, get answers, then proceed.

---

### 1.1 — Opening message

If `INLINE_DESCRIPTION` is set, open with:

> "Got it — you want an agent that **[INLINE_DESCRIPTION]**. Let me ask a few more questions to design it well."

Otherwise open with:

> "Let's design your agent. I'll ask a few questions, then handle everything else automatically."

---

### 1.2 — Ask all discovery questions in one message

Present these as a numbered list. Tell the user they can answer briefly — one line per question is enough.

```
1. What should this agent do? (one sentence)
2. What domain or technology does it specialize in?
   (e.g. "Kubernetes", "PostgreSQL", "React", "internal billing system")
3. What level of access does it need?
   a) Read-only — just reads and analyzes
   b) Read + modify files — reads and edits code/docs
   c) Read + modify + execute — can also run shell commands, scripts, or queries
4. Does it need internet access? (yes / no)
5. Does it need to delegate tasks to other agents? (yes / no)
6. Is the task bounded (clear start and end) or open-ended / continuous?
   a) Bounded — "do X and stop"
   b) Open-ended — "keep doing X until I say stop"
```

If `INLINE_DESCRIPTION` was provided, skip Q1 and use it as the answer.

---

### 1.3 — Process the answers

After receiving answers, do the following internally before responding:

**A. Set `AGENT_PURPOSE`**
Use the answer to Q1 (or `INLINE_DESCRIPTION`) as a one-sentence purpose statement. Clean it up if needed but preserve the user's intent.

**B. Set `DOMAIN`**
Use the answer to Q2. Normalize to a clean keyword or short phrase (e.g. "kubernetes", "postgresql", "react typescript", "internal billing system"). This will be used as the O'Reilly search query in Phase 2.

**C. Set `ACCESS_LEVEL`**
- Q3a → `read-only`
- Q3b → `read-write`
- Q3c → `read-write-execute`

**D. Set `NEEDS_WEB`**
- Q4 yes → `true`, else `false`

**E. Set `NEEDS_AGENTS`**
- Q5 yes → `true`, else `false`

**F. Set `TASK_BOUNDEDNESS`**
- Q6a → `bounded`
- Q6b → `open-ended`

---

### 1.4 — Confirm understanding

Reply with a brief summary so the user can catch misunderstandings before you proceed:

```
Here's what I have so far:

- **Purpose**: [AGENT_PURPOSE]
- **Domain**: [DOMAIN]
- **Access**: [ACCESS_LEVEL]
- **Internet access**: [yes/no]
- **Delegates to other agents**: [yes/no]
- **Task style**: [bounded/open-ended]

Does this look right? If so, I'll move to Phase 2 — finding domain knowledge to make this agent genuinely expert rather than just labeled.
```

Wait for confirmation (or corrections) before proceeding to Phase 2.

If the user makes corrections, update the relevant stored values and re-confirm.

---
