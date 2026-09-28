# Pack `frontend` — contrato

Dez geradores que emitem, a partir do Mapa de Negócio e do dialeto de **Mapa de Tela**, o front-end
React/TypeScript: schema de validação, cliente de API e as telas.

| Sub-gerador | Emite |
|---|---|
| `zodSchema` | schema de validação + tipo inferido |
| `apiClient` | o cliente de API da entidade |
| `screenPage`, `screenForm`, `screenColumns`, `screenCards` | a tela de lista, o formulário, as colunas, os cartões |
| `screenEditorPage`, `screenEditorById` | as telas de edição |
| `screenOperation` | a tela de operação |
| `screenManifest` | o manifesto que registra as telas |

`zod-schema.mi` é o mais simples da família e o melhor ponto de entrada depois do
[`_exemplar`](../_exemplar/): um gerador por entidade, com dispatch por tipo, enum e relação.

## O que o seu mapa precisa ter

**No `main.mi`**: `mapNativeTypes` (mesmas famílias do pack `quarkus`) e o registro dos sub-geradores sob
`config/mapperidea/generators/frontend/<sub>`.

**Nas telas** — este pack consome o **dialeto de Mapa de Tela**, que é uma convenção de partida
documentada, não uma feature do DSL. As propriedades que ele lê:

| Propriedade | Para quê |
|---|---|
| `type`, `component` | o tipo de campo/controle |
| `label`, `placeholder`, `title`, `description` | textos |
| `display`, `hidden`, `order`, `group` | o que aparece, onde e em que ordem |
| `opens` | **a navegação**: o nome da tela-alvo |
| `condition` | exibição condicional |
| `mask`, `sortable`, `pageSize` | formatação e comportamento de tabela |
| `values` | enum → seleção |
| `route`, `usedIn`, `icon`, `custom`, `message` | rota, reuso, ícone, customização, estado vazio |

Duas armadilhas que valem a leitura antes do primeiro uso:

- **Propriedade inventada some em silêncio.** Para "esta linha abre a tela X", use `opens` — não crie uma
  chave nova; ela não chega ao DOM.
- **Chave de JSX colide com o mustache.** Emita `{\{ … }\}` para produzir `{{ … }}` no `.tsx`.

## O que aqui é do projeto de origem

| Onde | O quê | O que fazer |
|---|---|---|
| `screen-manifest.mi:21` | `export type ScreenBrand = "marcaA" \| "marcaB"` — **placeholder** | troque pelas **suas** marcas, ou remova o conceito de marca |
| `screen-manifest.mi:46` | `class[starts-with(@package, 'com.exemplo.window.')]` — **placeholder** | o prefixo de pacote onde moram as telas — **troque pelo seu** |
| `screen-operation.mi:15` | `substring-after(…, 'com.exemplo.window.')` — **placeholder** | mesmo prefixo, na resolução da rota de destino |
| todos | as libs de front concretas do projeto de origem (componentes de tabela, formulário, etc.) embutidas nos `patterns` | é aqui que mora o maior trabalho de adaptação: os `patterns` emitem os componentes **daquele** design system |

**O prefixo de pacote das telas aparece em dois lugares** — se você trocar um e esquecer o outro, o
manifesto lista telas que a navegação não resolve. Procure por `com.exemplo.window.` antes de dar o pack por adaptado.

## Estado

Versão da cópia: **2026-09-17**. Semente, sem canal de atualização. Sem exemplo executável não-domínio
ainda (fase B2). O dialeto de Mapa de Tela é **convenção de partida documentada**: sem validação no parser
e sem promessa de compatibilidade — adapte à vontade.
