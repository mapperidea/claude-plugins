# Arquétipos do IADD — a tríade

O ativo aqui **não é cada agente: é a divisão de trabalho entre os três.**

| Arquétipo | Papel | Escreve | Roda CLI |
|---|---|---|---|
| `domain-mapper.md` | modela o negócio | mapas de negócio `.mi` | não |
| `generator-author.md` | escreve os geradores | mapas de arquitetura `.mi` | não |
| `cli-runner.md` | opera e valida | nada — só inspeciona | **sim** |

Cada fronteira existe por um modo de falha observado, e está explicado dentro de cada arquétipo:

1. **O modelador não escreve gerador** — senão uma lacuna do modelo vira remendo no template, e o mapa
   deixa de descrever o negócio.
2. **O autor de gerador não edita o mapa de negócio** — senão o modelo passa a ser moldado pela
   conveniência do gerador.
3. **Quem escreve não valida** — o runner não tem ferramenta de escrita; quem escreveu tem viés para
   interpretar erro como "provavelmente é outra coisa".
4. **Ninguém inventa a forma do DOM** — pede-se o `struct`.

As fronteiras não são só prosa: elas estão na lista de `tools`. O `domain-mapper` e o `generator-author`
não têm `Bash`; o `cli-runner` não tem `Write` nem `Edit`. O harness executa isso; a prosa só explica.

## Instanciar

**O caminho curto é `/iadd:init`** — ele faz os três passos abaixo, entrevistando você para
preencher os placeholders a partir da tabela que cada arquétipo traz. À mão:

**Três passos**, e o segundo é o único que dá trabalho:

```sh
# 1. copiar (os três, ou só os que você vai usar)
mkdir -p meu-projeto/.claude/agents
cp <kit>/plugins/iadd/archetypes/{domain-mapper,generator-author,cli-runner}.md meu-projeto/.claude/agents/

# 2. preencher os {{PLACEHOLDERS}} — cada arquétipo traz a tabela do que pôr em cada um

# 3. instalar os hooks que os agentes declaram
<kit>/plugins/agent-kit/scripts/install-into-project.sh meu-projeto
```

**Copie também os guias que os agentes citam** (`generator-authoring-guide.md`, o guia de modelagem) para
dentro do projeto: um agente que aponta para arquivo do kit deixa de funcionar quando o plugin sai — é a
regra de ejeção.

Confira no fim: `grep -c '{{' .claude/agents/*.md` tem de dar zero.

### Detalhe



Antes de instanciar, leia [o pipeline IADD](../docs/pipeline-iadd.md) — os três arquétipos são peças dele,
e sem o método escrito eles viram três agentes que se estorvam.

## Gate

`tests/test-i1-archetype-method.sh` fixa 40 afirmações de método. Editou um arquétipo e ficou vermelho: ou
você removeu método, ou mudou de ideia sobre o que é método — as duas exigem decisão, nenhuma exige
ignorar o teste.
