# agent-kit

Como se autora um agente Claude Code bom. Independente de stack, de negócio e de Mapper Idea.

```
skills/agent-creator/     o wizard: descoberta → conhecimento → arquitetura → comportamento → arquivo
  references/helpers.md   as matrizes de decisão (tipo, ferramentas, modelo, permissão, memória, hook)
agents/                   knowledge-extractor — extrai domínio de PDF/doc/URL em YAML estruturado
archetypes/               4 arquétipos: método destilado de agentes reais, com {{placeholders}}
templates/                11 agentes prontos para copiar
references/               as convenções tácitas, escritas
scripts/                  os hooks de segurança + o instalador deles no projeto-alvo
tests/                    suíte estrutural de aceite (572 asserções, sem custo de token)
```

## Uso

```sh
/agent-creator                          # wizard completo
/agent-creator "revisor de SQL"         # já com a descrição
/agent-creator --enrich <agente>        # acrescenta conhecimento a um agente existente
```

Antes do primeiro agente **com hook**, instale os scripts no projeto:

```sh
plugins/agent-kit/scripts/install-into-project.sh /caminho/do/meu-projeto
```

## Quando não há fonte externa de conhecimento

O wizard procura uma fonte autoritativa para o domínio (livro, arquivo seu, documentação oficial). Não
achando — sem MCP de livros configurado, ou com o site oficial bloqueando a busca — ele **entrevista você**
e classifica o resultado como **Tier D**.

Isso é um resultado legítimo, não uma falha: Tier D é conhecimento do seu time, e **vai para o `MEMORY.md`
do agente**, porque não existe em nenhum outro lugar. O único tier que não persiste nada é o **E**, quando
não houve fonte alguma — e ele é declarado explicitamente no frontmatter do agente, nunca silencioso.

## Ejeção

O que o wizard escreve no seu projeto **não aponta para dentro do kit**: o agente vai para
`.claude/agents/`, a memória para `.claude/agent-memory/`, e o hook referencia `scripts/…` do
**seu** projeto. Desinstalar o plugin não quebra nada do que já foi gerado.

`${CLAUDE_PLUGIN_ROOT}` é legítimo **dentro** do kit (a skill usa para achar os próprios recursos) e
proibido em tudo que é copiado — arquétipos e templates. `tests/test-f8-ejection.sh` verifica as duas
metades da regra.

## Testes

```sh
tests/run-all.sh
```

Estruturais: verificam que wizard, helpers, templates, extrator e scripts existem, estão executáveis e
contêm as seções que o método exige. Não invocam o modelo.
