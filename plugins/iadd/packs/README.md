# Packs

Um **pack** é o conjunto de geradores de uma stack. Packs são **semente, não dependência**: você copia,
adapta e passa a ser dono — não há canal de atualização, e isso é decisão de produto.

| Pack | O que é | Comece por |
|---|---|---|
| [`_exemplar/`](_exemplar/) | o menor gerador completo que existe, para **aprender** | aqui |
| [`quarkus/`](quarkus/) | pilha Java/Quarkus por entidade + OpenAPI | `zod-schema` do frontend ou o exemplar, antes |
| [`frontend/`](frontend/) | React/TypeScript: schema, cliente de API e telas | `zod-schema.mi` |

**O valor de um pack não é o código que ele emite — é a demonstração de como se escreve um gerador.** Quem
for para outra stack não vai *usar* o pack Quarkus: vai *lê-lo*. Por isso cada pack tem um README de
contrato dizendo **o que o seu mapa precisa ter** e **o que ali é do projeto de origem**.

Para criar um pack novo, leia [o guia de autoria](../references/generator-authoring-guide.md) e copie a
estrutura do `_exemplar`.
