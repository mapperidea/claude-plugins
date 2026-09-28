# Arquétipos

Um **arquétipo** é um agente real com o domínio e a fiação subtraídos, restando o método — e os buracos
marcados com `{{PLACEHOLDER}}`. Ele não é um template genérico escrito do zero: é destilação de um agente
que estava em uso, o que é a diferença entre método provado e método plausível.

| Arquétipo | Tese transferível |
|---|---|
| `product-manager.md` | INVEST, Given/When/Then, MoSCoW/WSJF, padrões de split; conflito de conformidade sinalizado **antes** de escrever o artefato |
| `architecture-reviewer.md` | releia os documentos-autoridade a cada review; **divergência doc↔doc ou doc↔código É um achado**; verifique contra o tipo real na branch base |
| `board-sync.md` | a fonte de verdade do status é o código e os PRs, não o campo do tracker; funil gateado, sem atalho para concluído; fato se aplica, pessoa se propõe |
| `test-engineer.md` | risco antes de escrita; técnica escolhida e justificada por unidade; oracle definido antes; rodar e reportar o real |

## Como instanciar

**O caminho curto é `/agent-creator`**: na Fase 1b ele casa o propósito que você descreveu contra este
catálogo e propõe o arquétipo certo — depois entrevista para preencher os placeholders, copia os guias
citados e instala os hooks. À mão, é isto:

1. **Copie** o arquétipo para `.claude/agents/<nome>.md` do seu projeto.
2. **Preencha os `{{PLACEHOLDERS}}`** — cada arquétipo traz, no fim, a tabela do que pôr em cada um.
3. **Extraia o domínio em vez de inventá-lo**: aponte o agente `knowledge-extractor` para os seus
   documentos e use o YAML que ele devolve. `safety_rules` vira restrição; `decision_heuristics` alimenta
   as responsabilidades; `anti_patterns` e `common_failures` alimentam o playbook.
4. **Instale os hooks** se o agente declarar algum: `scripts/install-into-project.sh <seu-projeto>`.
5. **Apague o que não se aplica.** Um arquétipo que você não soube preencher em algum ponto é um ponto que
   o seu projeto ainda não decidiu — apagar é melhor que preencher com plausibilidade.

Ou use `/agent-creator`, que percorre o mesmo caminho em forma de entrevista.

## A regra que vale para os quatro

**Domínio inventado é o pior defeito possível.** Um agente vazio você ignora; um agente confiante sobre
regras que não existem no seu projeto você segue — e ele contamina story, review e teste com autoridade
que não tem lastro. Prefira deixar um `{{PLACEHOLDER}}` visível a preencher com algo verossímil.

## O gate

`tests/test-f7-archetype-method.sh` fixa, por arquétipo, as afirmações de **método** que precisam continuar
presentes. Ele não julga redação — verifica que a subtração de domínio não levou método junto. Se você
editar um arquétipo e o F7 ficar vermelho, ou você removeu método (corrija o arquétipo) ou mudou de ideia
sobre o que é método (corrija o teste, deliberadamente).
