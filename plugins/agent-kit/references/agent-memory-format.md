# Formato de memória de agente

Um agente com `memory:` no frontmatter tem um diretório próprio — `.claude/agent-memory/<nome>/` para
memória de projeto (versionada, compartilhada com o time) ou `~/.claude/agent-memory/<nome>/` para memória
pessoal. Este documento diz o que escrever lá dentro.

---

## 1. Os dois usos do `MEMORY.md` — não os confunda

Existem **dois padrões**, e a escolha depende de onde o conhecimento do agente veio.

### Padrão A — `MEMORY.md` como **corpo de conhecimento**

Quando o agente foi ancorado numa **fonte externa** (um livro, uma especificação, um manual), o `MEMORY.md`
é a **destilação dessa fonte**: o método, em forma acionável. Ele é escrito uma vez, na criação do agente,
e muda pouco.

```markdown
# Test Engineer — Domain Knowledge
Source: Pragmatic Software Testing, Rex Black (2007) — knowledge tier B
Extraído: 2026-07-08

Base metodológica para escolher a técnica de teste certa por unidade e priorizar por risco.
Filosofia central: testar para ENCONTRAR defeitos, não para confirmar que funciona.

## Priorização por risco (a espinha dorsal)
- Esforço ∝ Risco Técnico × Risco de Negócio. Nunca priorizar só por risco técnico.
- Todo teste rastreia a um risco/requisito. Sem oracle definido antes, não é teste.

## Core Patterns — o que é / quando usar
- **Equivalence Partitioning**: entradas agrupáveis em classes tratadas igual; 1 representante por
  classe (válidas E inválidas).
- **Boundary Value Analysis**: quando as classes são ordenadas. Bugs se agrupam nas bordas.
…

## Decision Heuristics — como escolher a técnica
- Faixa ordenada → partição + valor-limite.
- Saída depende de combinação de condições → tabela de decisão.
```

Regras deste padrão:

- **Cabeçalho com proveniência**: fonte, *tier* de conhecimento e data da extração. Sem isso, ninguém sabe
  se envelheceu.
- **Fatos acionáveis, não resumo.** "Use X quando Y" transfere; "o capítulo 4 fala sobre integração" não.
- **Seções estáveis**: padrões, heurísticas de decisão, comandos, falhas comuns, regras de segurança.
- O `MEMORY.md` **não substitui a leitura dos documentos vivos** do projeto — quando o agente depende de
  docs que evoluem, o prompt deve dizer isso explicitamente.

### Padrão B — `MEMORY.md` como **índice**

Quando o conhecimento do agente é **acumulado no trabalho** (o que se aprendeu fazendo), o `MEMORY.md` é um
índice, e cada fato é um arquivo. É o padrão que cresce com o uso.

```markdown
# Memory Index

- [JSX brace collision in .mi patterns](feedback_jsx_brace_collision.md) — escape `{\{`/`}\}` em vez de
  quebrar a linha em vários nós
- [Frontend screen generator family](project_frontend_screen_generators.md) — zodSchema/apiClient/screen*
  existem; navegação e wiring ainda por fazer
- [Shallow [m] not [r]](feedback_shallow_manyToOne_not_weakref.md) — back-ref manyToOne é sempre seguro de
  achatar; oneToOne é ambíguo, pergunte antes
```

Uma linha por memória: `- [Título](arquivo.md) — gancho`. O gancho é o que permite decidir, lendo só o
índice, se vale abrir o arquivo. **Nunca ponha conteúdo de memória no índice** — ele é carregado inteiro a
cada sessão, e cresce para sempre.

Os dois padrões convivem: um agente ancorado em livro pode ter o corpo no `MEMORY.md` e ainda acumular
arquivos de aprendizado ao lado.

---

## 2. O arquivo de memória

Um arquivo, **um fato**.

```markdown
---
name: feedback-jsx-brace-collision
description: Como emitir chave dupla de JSX a partir de um pattern sem o motor de template se perder
metadata:
  type: feedback
---

<o fato, em prosa densa>

**Why:** <por que isso é verdade / como foi descoberto>

**How to apply:** <quando e onde aplicar da próxima vez>
```

| Campo | Regra |
|---|---|
| `name` | slug kebab-case; é o alvo dos links `[[name]]` |
| `description` | **uma linha** — é por ela que a relevância é decidida na recuperação |
| `metadata.type` | um dos quatro tipos abaixo |

### Os quatro tipos

| Tipo | O que guarda | Exemplo |
|---|---|---|
| `user` | quem é a pessoa: papel, expertise, preferências de trabalho | "revisa o plano antes de qualquer código" |
| `feedback` | orientação sobre **como trabalhar** — correções e abordagens confirmadas | "sempre rode a suíte inteira antes do PR, porque o CI é gate" |
| `project` | trabalho em curso, metas e restrições **não deriváveis do código** | "esta issue vem antes daquela porque a identidade entre serviços muda" |
| `reference` | ponteiros para recursos externos: URLs, dashboards, tickets, chaves de ambiente | "a chave de sandbox está em tal arquivo, com tal prefixo" |

`feedback` e `project` **exigem** as linhas **Why** e **How to apply**. Sem o *why*, o fato vira regra de
carga cultural — seguida sem entendimento e abandonada na primeira exceção. Sem o *how to apply*, ninguém
sabe reconhecer a próxima ocasião.

### Links

`[[outro-name]]` liga memórias. Ligue com generosidade: um link para uma memória que **ainda não existe**
não é erro — é marcador de algo que vale escrever depois.

---

## 3. O que NÃO virar memória

- **O que o repositório já registra**: estrutura de código, histórico de git, correções passadas, o que
  está no `CLAUDE.md`. Memória que duplica o repo envelhece mal e mente com confiança.
- **O que só importa nesta conversa.** Se o fato morre no fim da tarefa, ele não é memória.
- **Contexto sensível.** Situação financeira, política interna, dado de pessoa. Se um agente publica em
  tracker ou PR, isso vaza junto.
- **Datas relativas.** "Semana passada" não sobrevive. Converta para data absoluta ao salvar.

Se alguém pedir para lembrar de algo da primeira categoria, a pergunta certa é *"o que foi não-óbvio
nisso?"* — e é essa resposta que vira memória.

---

## 4. Manutenção

- **Antes de criar, procure o arquivo existente** que já cobre o assunto e atualize-o. Duas memórias sobre
  o mesmo fato divergem em semanas, e nada diz qual é a boa.
- **Apague o que se provou errado.** Memória obsoleta é pior que ausente.
- **Memória recuperada descreve o que era verdade quando foi escrita.** Se ela cita um arquivo, uma função
  ou uma flag, confirme que ainda existe antes de agir.
- **Quando um `feedback` se confirma repetidamente**, considere promovê-lo: ele provavelmente pertence ao
  *Debugging Playbook* do prompt do agente, onde é lido sempre em vez de recuperado às vezes.

---

## 5. O que você provavelmente vai querer mudar aqui

- **Os quatro tipos** cobrem bem trabalho de software. Outro domínio pode precisar de um quinto — mas
  resista a criar um tipo por assunto: o tipo classifica **a natureza do fato**, não o tema.
- **As linhas Why / How to apply** são a parte que eu mudaria por último. São elas que fazem a diferença
  entre uma memória que ensina e uma que apenas afirma.
