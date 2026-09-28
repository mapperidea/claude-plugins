# iadd

IA Driven Development com Mapper Idea: histórias viram Mapa de Negócio, o Mapa de Arquitetura gera o
código, e o CLI valida de verdade.

```
docs/pipeline-iadd.md        o método escrito — comece por aqui
references/
  generator-authoring-guide.md   como se escreve um gerador, do zero
  domain-modeling-guide.tpl.md   DDD + Mapper Idea, com o mapa do que trocar
  screen-map-guide.tpl.md        o dialeto de Mapa de Tela, idem
archetypes/                  a tríade: domain-mapper, generator-author, cli-runner
skills/init/                 /iadd:init — prepara um projeto: converte .mm existentes, instala a tríade
skills/mapperidea/           a referência de sintaxe .mi (alias: /mi)
packs/                       _exemplar (aprender) · quarkus · frontend, cada um com README de contrato
tools/mm-to-mi/              conversor FreeMind → .mi, em lote, com relatório
tests/                       gate de método dos arquétipos
```

## Por onde começar

1. **Leia [o pipeline](docs/pipeline-iadd.md)** — o que é IADD, as duas portas de entrada, quem é dono de
   cada etapa, e onde a validação real acontece.
2. **Rode `/iadd:init` no seu projeto.** Ele procura o que você já tem — inclusive mapas `.mm` — e
   conduz a partir daí: converte, identifica o mapa principal, instala a tríade e os hooks. Se preferir
   converter à mão, o conversor é [`tools/mm-to-mi`](tools/mm-to-mi/README.md).
3. **Para escrever seu primeiro gerador**, leia [o guia](references/generator-authoring-guide.md) com o
   [pack exemplar](packs/_exemplar/README.md) aberto ao lado.
4. **Para trabalhar com agentes**, rode `/iadd:init` no seu projeto — ele instala [a tríade](archetypes/README.md), entrevista para preencher, traz os guias junto e instala os hooks. À mão também dá: os três passos estão no README dos arquétipos.

## Dependência

Os arquétipos daqui são autorados com as convenções do plugin `agent-kit`, e usam os hooks dele. O
caminho inverso não vale: `agent-kit` não sabe nada sobre Mapper Idea.
