# Templates de agente

Onze agentes prontos, cobrindo os papéis mais comuns. São **pontos de partida para copiar**, não
skills: copie o `.md` para o `.claude/agents/` do seu projeto e edite.

**O `/agent-creator` conhece este catálogo**: na Fase 1b ele casa o que você pediu contra esta lista e
propõe partir de um template quando há um que cobre o papel — em vez de construir do zero. Por isso a
tabela abaixo precisa listar todo arquivo que existir aqui; o gate `tests/test-f10-disclosure.sh`
verifica isso.

| Template | Papel |
|---|---|
| `architect.md` | avaliação de arquitetura, tradeoffs, ADRs |
| `code-reviewer.md` | revisão de PR, legibilidade, erros de lógica |
| `data-scientist.md` | análise exploratória, avaliação de modelo |
| `db-analyst.md` | otimização de query, revisão de schema, plano de execução |
| `dev-orchestrator.md` | delega entre especialistas quando a tarefa cruza domínios |
| `devops.md` | CI/CD, Docker, infraestrutura |
| `documenter.md` | docstrings, README, docs de API |
| `refactorer.md` | extração, deduplicação, renomeação |
| `researcher.md` | exploração de código, rastreio de uso |
| `security-auditor.md` | OWASP, autenticação, segredos, ameaças |
| `tester.md` | testes unitários e de integração, lacunas de cobertura |

**No projeto de origem eles viravam skills por acidente** — estavam sob `.claude/commands/`, e o
Claude Code expõe o que está ali. Aqui ficam em `templates/`, que é o que sempre foram.

Um template é **método puro**: não conhece o seu domínio nem a sua fiação. Ao copiar, você preenche as
duas camadas que faltam — ver [as convenções de autoria](../references/agent-authoring-conventions.md),
seção "As três camadas". Para gerar um agente já com domínio extraído de um documento seu, use o wizard
`/agent-creator` em vez de copiar o template à mão.
