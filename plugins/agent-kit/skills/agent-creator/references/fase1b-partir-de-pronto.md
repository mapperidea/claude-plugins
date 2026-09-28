# Fase 1b — Partir de algo pronto, em vez do zero

*Referência da skill `agent-creator` — leia ao ENTRAR nesta fase. O roteiro e a ordem estão no `SKILL.md`.*

Você acabou de descobrir **o propósito e o domínio** do agente (Fase 1). Antes de gastar uma entrevista
inteira construindo do zero, veja se o kit já tem algo que cobre o caso. Quase sempre tem — e o que ele
tem carrega **método destilado de agentes que estavam em uso**, que é melhor do que método improvisado
na hora.

## O catálogo é o README, não uma lista neste arquivo

Leia os dois, que são curtos, e case contra o propósito da Fase 1:

- `${CLAUDE_PLUGIN_ROOT}/archetypes/README.md` — **4 arquétipos**, cada um com a tese transferível
- `${CLAUDE_PLUGIN_ROOT}/templates/README.md` — **11 templates**, um por papel comum

**Nunca mantenha uma cópia da lista aqui.** Arquétipo ou template novo entra sem tocar nesta skill; uma
lista duplicada envelhece em silêncio e passa a esconder o que existe.

## Arquétipo, template ou do zero

| | **Arquétipo** | **Template** | **Do zero** |
|---|---|---|---|
| O que é | um agente real com domínio e fiação subtraídos, com `{{PLACEHOLDERS}}` | um agente genérico pronto, sem placeholders | entrevista completa |
| Traz | **método provado** + a tabela do que preencher | um ponto de partida razoável | nada além do que você construir |
| Quando | há um que cobre o papel | há um template do papel e nenhum arquétipo | nenhum dos dois cobre |

**Ordem de preferência: arquétipo → template → do zero.** O arquétipo ganha porque foi destilado de um
agente que funcionava; o template é bom começo, mas genérico por construção.

**Trabalhando com Mapper Idea?** A tríade (`domain-mapper`, `generator-author`, `cli-runner`) vive no
plugin `iadd` e tem instalação própria, que faz mais do que copiar — converte mapas `.mm`, descobre o
projeto no CLI. Aponte para `/iadd:init` em vez de tentar instanciá-la daqui.

## Pergunte — uma vez, com a recomendação já feita

Não apresente um catálogo para o usuário escolher. **Case você mesmo** e apresente o resultado:

> Para "revisor de SQL", o kit tem duas coisas que encostam:
> · **arquétipo `architecture-reviewer`** — método de revisão: reler os documentos-autoridade a cada
>   review, divergência entre doc e código **é** um achado, três níveis de veredito
> · **template `db-analyst`** — otimização de query, revisão de schema, plano de execução
>
> Recomendo o **template `db-analyst`**: o seu caso é análise de SQL, não conformidade de arquitetura.
> Parto dele, do arquétipo, ou construo do zero?

Se **nada** casar, diga isso em uma linha e siga para a Fase 2 normalmente. Não force um encaixe — um
agente partido do arquétipo errado carrega método que não se aplica, e isso é pior que partir do zero.

## Se o usuário escolher partir de um pronto

O que muda no resto do fluxo:

| Fase | Do zero | Partindo de pronto |
|---|---|---|
| 2 — Conhecimento | como sempre | **como sempre** — o arquétipo traz método, não o **seu** domínio. Continua sendo preciso extrair |
| 3 — Arquitetura | você recomenda tudo | o arquétipo/template **já decidiu** ferramentas, modelo, permissão e memória. Apresente como padrão e só mude com motivo declarado |
| 4 — Comportamento | você redige o corpo | **você preenche** — cada `{{PLACEHOLDER}}` do arquétipo, guiado pela tabela que ele traz no fim |
| 5 — Configuração | monta o frontmatter | confirma o que veio, ajustando nome e tier |
| 6 — Geração | valida e escreve | **idem, mais as verificações abaixo** |

### O preenchimento (Fase 4, partindo de arquétipo)

1. **A tabela de placeholders está no fim do próprio arquétipo**, na seção *"O que você provavelmente vai
   querer mudar aqui"*. Ela é o seu roteiro de perguntas — não invente outro.
2. **`{{TIER}}` é só a letra** (A–E). A descrição da fonte já está escrita no template, ao lado.
3. **Não deixe placeholder cru.** Sem resposta para um, escreva a frase honesta ("este projeto não tem
   glossário separado"), nunca o `{{...}}`.
4. **Domínio inventado é o pior defeito possível** neste caminho. O arquétipo dá autoridade ao que você
   escrever; preencher com plausível produz um agente confiante sobre regras que não existem. Prefira
   extrair na Fase 2 — é para isso que ela serve.

### Se o arquétipo cita guias

Alguns citam documentos do kit. **Copie-os para dentro do projeto** e aponte o placeholder para a cópia:
um agente que aponta para arquivo do plugin para de funcionar quando o plugin sai.

### Verificações extras na Fase 6

```sh
grep -c '{{' .claude/agents/<nome>.md                       # tem de dar 0
grep -n 'CLAUDE_PLUGIN_ROOT\|/plugins/' .claude/agents/<nome>.md   # tem de ser vazio
```

E, se o agente declarar hook, instale os scripts antes do primeiro uso:
`${CLAUDE_PLUGIN_ROOT}/scripts/install-into-project.sh <projeto>`
