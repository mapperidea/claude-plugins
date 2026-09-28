> ## Como usar este template
>
> Este é o **guia do dialeto de Mapa de Tela**, extraído de um projeto real em 17/09/2026. Ele é
> **semente**: copie e edite.
>
> **Status do dialeto**: convenção de partida **documentada**, não feature do DSL. Sem validação no
> parser, sem promessa de compatibilidade. Isso é deliberado — o dialeto amadurece pelo uso antes de
> virar contrato.
>
> | Seção | Natureza | O que fazer |
> |---|---|---|
> | 1–2 (propósito, onde vivem os mapas) | método + fiação | mantenha o propósito, troque os caminhos |
> | 3 (estereótipos de tela) | **referência da ferramenta** | mantenha |
> | 4–7 (anatomia, binding ao domínio, campos, ações e navegação) | **método puro** — o coração | mantenha |
> | 8 (menu) | método + estrutura de origem | mantenha a mecânica, troque a árvore |
> | 9 (como mapeia para a lib de runtime) | **acoplado às libs de front do projeto de origem** | reescreva
>   para o seu design system: é aqui que o pack `frontend` vira outro pack |
> | 10 (DOM normalizado, confirmado via `struct`) | **referência da ferramenta** | mantenha |
> | 11 (exemplo completo) | **exemplo** no domínio de ensino (uma loja) | substitua por uma tela sua |
> | 12 (convenções e checklist) | **método puro** | mantenha |
> | 13–15 (escopo, dono do mapa, multi-marca) | decisões que todo projeto refaz | reavalie para o seu |
>
> **A regra de binding (seção 5)** é o que separa este dialeto de um gerador de formulário qualquer: a
> tela **referencia** o mapa de domínio em vez de redeclarar os campos. Se você mudar uma coisa só,
> não mude essa.
>
> **Duas armadilhas** que valem a leitura antes do primeiro mapa: propriedade fora do vocabulário
> conhecido é descartada do DOM em silêncio (use `opens` para navegação, não uma chave nova); e chave de
> JSX colide com o mustache (emita `{\{ … }\}`).

---

# Guia — Dialeto de Mapa de Tela (Mapper Idea · camada 1)

**Status:** Proposto (v1) · **Data:** 2026-07-09
**Serve a:** `docs/plano-mapa-de-tela.md`, `docs/arquitetura-geracao-frontend.md`, `docs/estudo-samples-mapa-de-tela.md`
**Base:** ícones `Descriptor.window.*` **existentes** no Mapper Idea + precedente `samples/stu-mi` + o domínio real
(`mi/cadastro/Cliente.mi`) + a lib de runtime já construída (`frontend/src/runtime/`).

> Este guia define a **camada 1** (estrutura lógica da tela) do modelo de 3 camadas. Camada 2 (tokens/tema) e
> camada 3 (mapeamento tipo/renderer→componente shadcn) são referenciadas por metadados, mas vivem no
> `frontend/` (ver `arquitetura-geracao-frontend.md`). Um mapa de tela **não** carrega estilo nem lógica
> imperativa — só a estrutura, o bind ao domínio e a interação/navegação.

## Convenção de nomenclatura (importante)

Para não misturar as duas linguagens e manter o mapa legível:

- **Termos de estrutura/layout da tela → INGLÊS** (convenção de layout que o designer já domina):
  `source`, `object`, `title`, `route`, `role`, `icon`, `description`, `columns`, `field`, `search`, `filters`,
  `filter`, `actions`, `action`, `form`, `rows`/`cols`/`row`/`col`, `emptyState`, `message`, `menu`, `group`,
  `item`, `screen`; metadados: `display`, `mask`, `sortable`, `component`, `readOnly`, `required`, `width`,
  `type`, `opens`, `navigate`, `condition`, `label`.
- **Termos de negócio → PT** (vêm da regra de negócio, permanecem como estão): nomes de tela
  (`GestaoClientes`), **bindings de atributo** (`.nome`, `.numeroDocumento`, `.status`), conteúdo de
  `title`/`label`/`message` (texto em pt/en), papéis (`administrador`) e valores de enum (`RASCUNHO`).

Assim, uma linha como `[e] field [v] .nome` deixa claro: `field` (estrutura, inglês) + `.nome` (negócio, PT).

---

## 1. Propósito e escopo

Um **mapa de tela** declara *o que* uma tela mostra e *como as telas se relacionam*, sempre **amarrado ao mapa
de domínio**. É consumido pelo gerador `screen` (a escrever), que emite artefatos finos de frontend
(`features/<contexto>/<Tela>.tsx` + colunas) compondo a lib de runtime (`<DataTable>`, `<AutoForm>`…).

- **É** camada 1: telas, regiões, campos ligados ao domínio, filtros, ações, navegação, estados.
- **Não é**: estilo/cores (camada 2), escolha final de componente (camada 3 — só *hint*), lógica de negócio
  (fica em métodos do domínio) nem lógica imperativa embutida (lição do `estudo-samples` §7).

**v1 cobre:** `window.list`, `window.dialog`/`window.editor`, e navegação (elemento `[e] menu`). **Futuro:** `window.iframe` (master-detail),
`window.operation` + `window.step` (wizard), `window.report`, `window.custom`, join com entidade relacionada.

---

## 2. Onde vivem os mapas de tela

Espelham a árvore de domínio, num namespace `window` (paralelo a `domain`), com **dois níveis de pacote**:
**contexto** (bounded context) e **classe de domínio** (o `object` que as telas operam) — agrupando as telas
daquela entidade. O caminho de pacotes do mapa vira 1:1 a pasta gerada em `features/` (ver §9).

- Arquivo: `mi/window/<contexto>/<classeDominio>/<Tela>.mi`
  (ex.: `mi/window/cadastro/cliente/GestaoClientes.mi`).
- Registro no `mi/main.mi` sob `[p] window` (irmão de `[p] domain`), com `[p] <contexto>` → `[p] <classeDominio>`:

```
[p] window
    [p] cadastro
        [p] cliente
            [Descriptor.window.list] GestaoClientes
                #
                    window/cadastro/cliente/GestaoClientes.mi
            [Descriptor.window.dialog] CriarCliente
                #
                    window/cadastro/cliente/CriarCliente.mi
```

Nomes de tela em **PascalCase** e em linguagem de negócio; o pacote `<classeDominio>` em minúscula
(`cliente`). O gerador roda por tela com o pacote completo:
`mi generate loja frontend <sub> modelName=<Tela> package=ai.loja.window.<contexto>.<classeDominio>`.
O runner `gen-frontend.sh <Tela>` deriva pacote e pasta automaticamente do caminho após `mi/window/`.

---

## 3. Estereótipos de tela (ícones existentes `Descriptor.window.*`)

**Use o vocabulário de ícones que já existe** — o texto após `Descriptor.` vira o `@mode` da classe no DOM
(mesmo mecanismo do `stu-mi`: `[Descriptor.window.editor]` → `mode="window.editor"`). Ícones disponíveis hoje:
`window.custom`, `window.editor`, `window.list`, `window.report`, `window.dialog`, `window.iframe`,
`window.operation`, `window.step`. **Só criar ícone novo se necessário — seguindo o padrão `Descriptor.window.<x>`.**

| Ícone existente | `@mode` | Papel na v1 | Runtime alvo |
|---|---|---|---|
| `[Descriptor.window.list]` | `window.list` | listagem (columns/filters/search/actions) | `<DataTable>` |
| `[Descriptor.window.dialog]` | `window.dialog` | criar/editar em **modal** | `<Dialog>` + `<AutoForm>` |
| `[Descriptor.window.editor]` | `window.editor` | criar/editar/detalhe em **página** | `<AutoForm>` / `<DetailPanel>` |
| `[Descriptor.window.iframe]` *(futuro)* | `window.iframe` | master-detail embutido | `<MasterDetail>` |
| `[Descriptor.window.operation]` + `.step` *(§7.2; **implementado**)* | `window.operation` | caso de uso / wizard (ex.: onboarding) | `<OperationFlow>` |
| `[Descriptor.window.report]` *(futuro)* | `window.report` | relatório | — |
| `[Descriptor.window.custom]` *(escape)* | `window.custom` | tela sob medida (fora do padrão gerável) | ejeção manual |

> **Navegação não é um estereótipo `window.*`.** Menu é um *componente*, não um tipo de janela — declara-se
> como **elemento `[e] menu`** (§8) ou, se precisar de artefato standalone, como classe `[Descriptor.menu]`.

> **struct-first (obrigatório):** antes de escrever o gerador `screen`, o `mapperidea-runner` roda `struct` numa
> tela real e confirma o `@mode` produzido por cada `Descriptor.window.*` e a forma das regiões-filhas.

---

## 4. Anatomia de um mapa de tela

```
[Descriptor.window.list] GestaoClientes
    @
        [e] title
            [e] pt
                [v] Gestão dos Clientes
        [e] route
            [v] /clientes
        [e] role
            [v] administrador          # papel Keycloak (RBAC; só UX — a fronteira real é no backend)
        [e] icon
            [v] building                    # ícone lucide
    [g] source
        [r] object: Cliente()           # BIND: a tela opera sobre este [b] de domínio
    [e] columns
        ...                                 # (só em window.list) projeção de grade
    [e] search
        ...
    [e] filters
        ...
    [e] actions
        ...
    [e] emptyState
        ...
```

- **`@` metadados da tela:** `title` (pt/en), `route` (path TanStack Router), `role` (papel Keycloak), `icon`
  (nome lucide), `description` (opcional), `usedIn` (lista de marcas-produto; ausente = todas — ver §15),
  `presentation` (só `window.list`: `table` [default] → `<DataTable>` via screenColumns+screenPage; `cards` →
  `<CardList>` via screenCards; 1ª coluna = título do card, demais = campos).
- **`[g] source / [r] object: <Bean>()`** — o **bind raiz**: a entidade de domínio que a tela opera. Tudo em
  `columns`/`form`/`filters` referencia atributos desse bean por caminho pontuado (§5).
- **Containers por estereótipo:** `window.list` usa `columns`+`search`+`filters`+`actions`+`emptyState`;
  `window.dialog`/`window.editor` usam `form`+`actions`. Equivalência com o legado `stu-mi`: `columns` ≙
  `viewList`, `form` ≙ `layout`, `field` ≙ `field`. A escolha de ter **uma** região (tela separada) ou **duas**
  (`columns`+`form` na mesma classe) define o *modelo de composição* — ver §7.1.

---

## 5. Binding ao domínio (regra dos caminhos)

`field` referencia atributos do bean `object` por **caminho com ponto inicial** (o caminho é PT, do negócio):

- `.nome` → `object.nome` (atributo direto).
- `.contrato.status` → navega a relação (`object.contrato.status`) *(futuro — join com entidade relacionada)*.

Resolução é **por nome/caminho contra o mapa de domínio** — não é XPath, não é include. O gerador resolve
`.campo` contra os `attributes/attribute[@name=...]` do bean `object` para descobrir tipo, `values` (enum),
`required`, `title/pt` e `typeParameter`. **Enums e rótulos vêm do schema gerado** (`<attr>Values`/`<attr>Labels`
do gerador `zod-schema`) — o mapa de tela não redeclara valores.

---

## 6. Elementos e metadados de campo

### 6.1 `[e] columns` (grade — `window.list`)
Lista ordenada de `[e] field [v] .caminho`, cada um com `@` opcional:

```
[e] columns
    [e] field
        [v] .nome
    [e] field
        [v] .numeroDocumento
        @
            [e] mask
                [v] cnpj
            [e] sortable
                [v] false
    [e] field
        [v] .status
        @
            [e] display
                [v] badge                    # renderiza <Badge> com <attr>Labels + tom por valor
    [e] field
        [v] .dataCriacao
        @
            [e] display
                [v] date
```

Metadados de `field` (todos opcionais; default derivado do domínio):
- `display`: `text` | `badge` | `currency` | `date` | `dateTime` — como a célula/valor é exibido.
- `mask`: `cnpj` | `cpf` | `phone` | `postalCode` — máscara de apresentação (dado trafega cru).
- `label` (pt/en): sobrescreve o `title` do domínio.
- `sortable`: `true`|`false` (default `true`, exceto mascarados/derivados).
- `component` *(camada 3)*: força o controle shadcn (`Input`|`Textarea`|`Select`|`Switch`|`Combobox`|`DatePicker`);
  default resolvido pelo mapa `toShadcn` a partir do tipo/enum.

### 6.2 `[e] search`
```
[e] search
    @
        [e] placeholder
            [e] pt
                [v] Buscar por razão social…
    [e] field
        [v] .nome
    [e] field
        [v] .numeroDocumento
```

### 6.3 `[e] filters`
```
[e] filters
    [e] filter
        [v] .status
        @
            [e] type
                [v] faceted                  # select facetado; enum → opções de <attr>Values/Labels
```
> `segmento` no domínio é texto livre (sem `values`) — como filtro exigiria uma fonte de opções (tabela de
> referência) ou facet derivado dos dados; v1 filtra só enums. Documentar quando adicionar.

### 6.4 `[e] form` — campos e layout (`window.dialog` / `window.editor`)
O `form` lista os campos editáveis (`[e] field [v] .caminho`, com os metadados de 6.1 + `readOnly`, `required`) e
organiza o **layout** com `[e] rows` / `[e] cols` (modelo do `smpl`):

- **`[e] rows`** — empilha linhas. Um `[e] field` **direto** em `rows` ocupa **uma linha inteira**. Para pôr
  **2+ campos na mesma linha**, envolva-os num `[e] row`. *(Omita o `row` quando for 1 campo por linha — reduz
  a poluição visual no mapa.)*
- **`[e] cols`** — análogo para colunas: `[e] field` direto = uma coluna; `[e] col` agrupa campos numa mesma
  coluna. `rows`/`cols` podem aninhar (ex.: um `row` contendo dois `col`).
- **`@ width`** *(opcional)* em `field`/`row`/`col` — peso de proporção (estilo `flex` do `smpl`: `50`, `80`…)
  quando a divisão não for igualitária. Default: itens da linha dividem o espaço igualmente.

```
[e] form
    [e] rows
        [e] field
            [v] .nome                    # field direto em rows → linha inteira
        [e] row                          # dois campos na MESMA linha
            [e] field
                [v] .numeroDocumento
                @
                    [e] mask
                        [v] cnpj
            [e] field
                [v] .tipoDocumento
        [e] field
            [v] .segmento                # linha inteira
```

O subconjunto editável é **decidido na tela** (não no domínio) — escolha de UX. Enquanto o domínio não marcar
campos de sistema com `@ readOnly`, a tela lista explicitamente os campos.

### 6.5 `[e] emptyState`
```
[e] emptyState
    @
        [e] message
            [e] pt
                [v] Nenhum cliente cadastrado ainda.
        [e] action
            [v] criarCliente            # referencia uma [e] action declarada
```

---

## 7. Ações e navegação

```
[e] actions
    [e] action
        [v] criarCliente
        @
            [e] type
                [v] primary                  # primary | secondary | row
            [e] label
                [e] pt
                    [v] Criar Cliente
            [e] icon
                [v] plus
            [e] opens
                [v] CriarCliente         # ação primary → abre editora SEM id (modo criação)
    [e] action
        [v] editarCliente
        @
            [e] type
                [v] row
            [e] label
                [e] pt
                    [v] Editar
            [e] opens
                [v] EditarCliente        # ação row → abre editora COM o {id} da linha (modo edição)
    [e] action
        [v] verContrato
        @
            [e] type
                [v] row                      # ação por linha (menu de ações da linha)
            [e] label
                [e] pt
                    [v] Ver contrato
            [e] condition
                [v] status != 'INATIVO'      # habilita/mostra conforme atributo do object (regra de negócio da story)
            [e] navigate
                [v] /contratos/{id}          # navega para rota (push); {id} = id da linha
```

Semântica: `opens` → monta a tela editora referenciada (`window.dialog` modal / `window.editor` página) — em ação
`row` passa o `{id}` da linha (modo edição), em ação `primary` abre sem id (modo criação); `navigate` →
`router.navigate` para a rota (com `{id}` interpolado da linha); `condition` → expressão booleana sobre atributos
do `object` que controla `disabled`/visibilidade (a UX; a autorização real é do BFF). `type` decide onde a ação
aparece (botão primário no cabeçalho, secundário, ou no menu de ações da linha).

### 7.1 Editores e diálogos — reuso via ação + ID (dois modelos de composição)

Herdado do modelo do `smpl`: a lista declara **estrutura** (columns/filters/actions) e a **ação de edição abre uma
tela editora separada, passando o ID da entidade**. Isso desacopla lista de editor e habilita **reuso** — o editor
abre de qualquer origem e como página OU popup; uma lista pode ter vários diálogos conforme o sistema evolui.

- **Ação de edição (`type: row`):** `@ opens <TelaEditora>` — o editor recebe o **`{id}` da linha** e carrega
  `object` por esse id (modo edição).
- **Ação de criação (`type: primary`):** `@ opens <TelaEditora>` **sem id** → o editor abre vazio (modo criação).
- **Vários editores por lista:** declare várias ações de edição, cada uma abrindo um editor diferente
  (ex.: `EditarDadosCadastrais`, `ConfigurarCanais`) — cada editor recebe o id e opera seu recorte.
- **Convenção padrão (opcional):** ação de edição sem alvo explícito abre `<Entidade>Editor` (ou
  `<Entidade>Dialog`) por sufixo — reduz boilerplate; sempre sobreponível com `@ opens`.

**Dois modelos de composição — ambos suportados:**

| Modelo | Como declarar | Quando usar |
|---|---|---|
| **A — telas separadas (reuso)** *(padrão)* | `window.list` (só `columns`/`filters`/`actions`…) + `window.editor`/`window.dialog` **separada** (`form`), ligadas por ação + `{id}` | editor reutilizável; popups; várias ações de edição; alinhado ao React/shadcn + nossa runtime |
| **B — combinada (mesma visão)** | **uma** `window.editor` com **`columns` E `form`** no mesmo mapa (≙ `viewList`+`layout` do `stu-mi`) | CRUD simples em que lista e formulário vivem juntos numa só visão |

No Modelo A o editor recebe o `id` pela ação e é independente (reuso); no Modelo B lista e formulário
compartilham o mesmo `object` na mesma tela. A piloto (§11) usa o **Modelo A**.

---

## 7.2 Fluxos multi-etapa — `window.operation` + `step` (wizard)

Uma `operation` não é uma tela de um objeto; é a **orquestração de um fluxo com estado que se acumula** até um
"pronto". `list`/`editor`/`dialog`/`cards` editam UM objeto; `operation` compõe VÁRIAS etapas. Caso de uso âncora:
um **onboarding** em várias etapas — plano, canal, integração, dados da empresa, primeira carga, notificações,
templates, revisar/ativar.

### 7.2.1 Objeto mestre (agregado do fluxo)

A `operation` declara um **objeto mestre** — o agregado que o fluxo constrói. Cada `step` grava uma **fatia**
pendurada no id do mestre.

- Na variante **Express**, Cliente e Fornecedor colapsam em **1:1** ("cliente é o próprio fornecedor") → o mestre é
  `Cliente` (que também é o `Fornecedor`). O id do mestre é o `idFornecedor` que as entidades de step referenciam
  (`Assinatura`, `ConhecimentoEmpresa`, `RegraNegociacao`, `TemplateMensagem`). Isso **fecha** a decisão de
  ownership da `RegraNegociacao` (por Fornecedor) — quem fornece o `idFornecedor` é o mestre do onboarding.
- O **progresso/rascunho** persiste em `CicloCliente` (+ `Cliente.status`) — não no mestre em si.
- ⚠️ **Divergência de marca real** (não é só tema/`usedIn`): na **Plena/Loja** o Cliente é **1:N Fornecedores**,
  então o onboarding tem um passo a mais (escolher/criar fornecedor) e o mestre difere. Provavelmente duas `operation`
  distintas por `usedIn`.

### 7.2.2 Anatomia do mapa

```
[Descriptor.window.operation] OnboardingExpress
    @
        [e] title
            [e] pt
                [v] Onboarding
        [e] route
            [v] /onboarding
        [e] usedIn
            [v] express
    [g] master
        [r] object: Cliente()          # agregado do fluxo (= Fornecedor na variante Express)
    [e] progress
        [v] CicloCliente               # onde o progresso/rascunho persiste (opcional)
    [e] steps
        [e] step
            [v] plano
            @
                [e] title
                    [e] pt
                        [v] Plano
                [e] opens
                    [v] EscolherPlano      # REUSA tela existente (domínio billing) — por referência
        [e] step
            [v] empresa
            @
                [e] opens
                    [v] DadosEmpresa       # REUSA (domínio conhecimento)
        [e] step
            [v] notificaçãos
            @
                [e] opens
                    [v] ConfigNotificações     # REUSA (domínio notificação)
                [e] optional
                    [v] true               # passo pulável
        [e] step
            [v] whatsapp
            @
                [e] title
                    [e] pt
                        [v] Conectar WhatsApp
                [e] custom
                    [v] ConectarWhatsapp   # SÓ-DO-FLUXO → vive no pacote onboarding/
        [e] step
            [v] revisar
            @
                [e] custom
                    [v] RevisarAtivar
```

Metadados de `step`:

| Chave | Significado |
|---|---|
| `opens <Tela>` | **reusa** uma tela existente por referência — o runtime embute o `<TelaForm>` dela. Não duplica. |
| `custom <Tela>` | passo **só-do-fluxo** (não reusável) — a tela custom vive no pacote `onboarding/`. |
| `title` | rótulo do passo (senão herda o `title` da tela referenciada). |
| `optional true` | passo pulável (o fluxo conclui sem ele). |
| `condition` | expressão booleana sobre o **mestre** p/ mostrar/pular o passo (ex.: só mostra "conectar ERP" se o plano exige). Mesma semântica de `condition` em ações (§7). |

### 7.2.3 A regra de empacotamento (o reuso — compor, não realocar)

> **Empacote pelo maior escopo de reuso. Reuso é por REFERÊNCIA (`opens`), não por realocação.**

| Tipo de tela | Onde vive | Como o fluxo usa |
|---|---|---|
| Entidade **reutilizável** (Plano, DadosEmpresa, Notificações, Templates) — tem vida fora do fluxo (config, upgrade, gestão contínua) | pacote do **domínio** (`window/<ctx>/<classe>/`) | `step @ opens <Tela>` |
| **Só-do-fluxo** (WhatsApp connect, ERP OAuth, 1ª carga, conciliação, revisar/ativar) — não existe standalone | pacote **`window/onboarding/`** | `step @ custom <Tela>` (vive ali) |
| A `operation` + a sequência + o mestre | pacote **`window/onboarding/`** | é o dono da orquestração |

O mapa da `operation` **lista todos os steps** (inclusive os `opens`) → um arquivo mostra o fluxo inteiro e suas
dependências (self-documenting), **sem** prender no pacote onboarding as telas que se reusam noutros lugares. Mover
tudo pra dentro do onboarding quebraria o reuso (Dados da Empresa, Notificações, Plano e Templates seguem vivos
após o onboarding).

### 7.2.4 Por que o reuso já está de pé

Três peças que já existem se encaixam — só falta o casco do wizard:

1. **A separação Form × Screen** (já geramos as duas): todo editor emite um `<XForm>` (só o `AutoForm`; recebe
   `onSubmit`/`values`/`isSubmitting`) e um `<XScreen>` fino (a página standalone). **O `<XForm>` é a unidade
   reusável de um step** — o step embute o *Form*, não a *Screen*. Foi por isso que valeu separar os dois.
2. **A referência `opens`** (provada em row action → editor, §7.1): `step @ opens DadosEmpresa` reusa o mesmo
   mecanismo (tela A referencia tela B; rota resolvida do alvo).
3. **A lib de runtime** (`DataTable`/`AutoForm`/`CardList`): falta só **um** componente novo, escrito à mão uma
   vez — `<OperationFlow>` (o casco: progresso, avançar/voltar, contexto do mestre).

### 7.2.5 Design do runtime `<OperationFlow>` (contrato)

Componente da lib (`src/runtime/operation-flow.tsx`) — escrito à mão uma vez; o gerador só produz a config.
Esboço do contrato (design, não código final):

```ts
interface OperationStep<M> {
  key: string
  title: string
  optional?: boolean
  isVisible?: (master: M) => boolean            // ← @ condition
  // renderiza o corpo do passo; embute o <XForm> reusado (opens) ou a tela custom.
  // patch acumula a fatia no mestre; next avança.
  render: (ctx: { master: M; patch: (slice: Partial<M>) => void; next: () => void }) => ReactNode
}
interface OperationFlowProps<M> {
  steps: OperationStep<M>[]
  initial: M                                     // mestre carregado (ex.: Cliente em rascunho)
  onSaveDraft?: (master: M) => Promise<void>     // persiste rascunho a cada passo → CicloCliente
  onComplete: (master: M) => Promise<void>       // conclui (status → ativo)
}
```

Responsabilidades do runtime (não do gerador):
- **Estado:** passo atual, mestre acumulado, validade por passo (vem do zod do `<XForm>` embutido), navegação
  `next`/`back`/`goto`.
- **Progresso + retomar:** barra/stepper; ao montar, pula para o 1º passo incompleto (rascunho de `CicloCliente`).
- **Composição por passo `opens`:** renderiza o `<XForm>` da tela referenciada com `values` = fatia do mestre e
  `onSubmit={(v) => { patch(v); onSaveDraft?.(master); next() }}`. **Reuso puro — zero reescrita da tela.**
- **Guards:** `isVisible`/`optional` decidem exibir/pular; conclusão só com os obrigatórios válidos.

O que o **gerador** `screenOperation` (**implementado**) emite: uma `<{Nome}Screen>` que monta
`steps: OperationStep[]` (um por `step` do mapa; `opens` → importa e embute o `<XForm>` correspondente — path
resolvido do `@package` da tela-alvo; `custom` → importa a tela do pacote `onboarding/`), com `handleComplete` e o
`<OperationFlow>`. Rodar: `gen-frontend.sh OnboardingExpress`. (v1: `master` é `Record<string, unknown>` — cada
step grava sua fatia; a orquestração real de persistência por `idFornecedor` é backend.)

### 7.2.6 Navegação

A `operation` é **UMA entrada de menu** (ex.: "Onboarding"); os `step` **não** são itens de topo (são internos ao
fluxo). O manifesto/nav já filtra por `route`/estereótipo — a regra de item de menu (§8, tem rota fixa e não é
dialog) naturalmente inclui a `operation` e exclui os steps.

---

## 8. Navegação (menu)

Menu é um **componente**, não um tipo de janela — não recebe ícone `window.*`. Duas formas equivalentes (mesma
estrutura interna `group`/`item`; ambas normalizam para a mesma geração de nav+rotas):

**(a) Preferida — elemento `[e] menu`** declarado na tela de **shell/layout** da aplicação (a que envolve a área
autenticada; mapeia para o `_authenticated` do runtime). Como componente, vive dentro de uma tela:

```
[Descriptor.window.custom] AppShell        # tela de layout/shell (host do menu)
    @
        [e] title
            [e] pt
                [v] Loja
    [e] menu
        [e] group
            [v] Cadastro
            @
                [e] icon
                    [v] briefcase
            [e] item
                @
                    [e] screen
                        [v] GestaoClientes   # referencia a tela (usa sua route/title/icon)
                    [e] role
                        [v] administrador
```

**(b) Alternativa standalone — classe `[Descriptor.menu]`** (quando ainda não há tela de shell, ou se preferir o
menu como artefato declarativo independente). Estrutura interna idêntica:

```
[Descriptor.menu] MenuPrincipal
    [e] group
        [v] Cadastro
        @
            [e] icon
                [v] briefcase
        [e] item
            @
                [e] screen
                    [v] GestaoClientes
                [e] role
                    [v] administrador
```

Fonte única: o gerador deriva **nav + rotas** do menu + das telas referenciadas (nav e rota nunca divergem —
corrige o vício do `stu-frontend`, que mantinha o nav à mão). Cada `item` referencia uma tela por nome e herda
sua `route`/`title`/`icon`.

---

## 9. Como mapeia para a lib de runtime (o que o gerador `screen` emite)

| Mapa de tela | Saída gerada | Runtime |
|---|---|---|
| `window.list` + `columns` | `features/<ctx>/<Tela>.columns.tsx` (`ColumnDef[]`) | `<DataTable>` |
| `field @display=badge` | célula `<Badge>` + `statusTone` + `<attr>Labels` | `Badge` |
| `field @mask=cnpj` | `maskCNPJ(...)` | `runtime/format` |
| `search` | prop `searchPlaceholder` | `<DataTable>` |
| `filter @type=faceted` | item de `facets=[...]` (via `<attr>Values/Labels`) | `<DataTable>` |
| `action @type=row/@condition` | item do dropdown de linha (com `disabled`) | `DropdownMenu` |
| `action @type=primary/@opens` | botão primário que abre `<Dialog>` com `<AutoForm>` | `Dialog`+`AutoForm` |
| `emptyState` | prop `empty={{message, action}}` | `<EmptyState>` |
| `window.dialog`/`editor` + `form` | `<AutoForm schema fields>` (schema = `pick` do gerado) | `<AutoForm>` |
| `form` `rows`/`row`/`cols` | layout em grid (`row` = N campos na mesma linha; `@ width` → proporção) | `<AutoForm>` |
| `[e] menu` / `[Descriptor.menu]` | `gen/nav.ts` + rotas TanStack | Router + nav |
| `window.operation` + `steps` *(§7.2; implementado)* | `<XScreen>` que monta `OperationStep[]` (`opens` → embute `<XForm>`; `custom` → tela do pkg onboarding) | `<OperationFlow>` |

Dados: sempre via os hooks do gerador `api-client` (`use<Model>s`, `useCriar<Model>`…). Schemas/enums via o
gerador `zod-schema`. O gerador `screen` **não** reimplementa nada disso — só compõe.

> **Nota de runtime:** o `<AutoForm>` hoje renderiza os campos em **coluna única**. Honrar `row` (2+ campos na
> mesma linha) e `@ width` exige uma pequena evolução de grid no `<AutoForm>` — a fazer junto com o gerador
> `screen` (o mapa já declara o layout; o runtime passa a respeitá-lo).

---

## 10. DOM normalizado — CONFIRMADO via `struct` (2026-07-09)

`mi push` + `mi generate loja struct xml className=GestaoClientes packageName=ai.loja.window.cadastro.cliente`
confirmou a forma abaixo (idêntico para `CriarCliente` com `mode="window.dialog"` e `<form>`):

```
<class name="GestaoClientes" package="ai.loja.window.cadastro.cliente" mode="window.list">
  <properties>
    <title><pt><value>Gestão dos Clientes</value></pt></title>
    <route><value>/clientes</value></route>
    <role><value>administrador</value></role>
    <icon><value>building</value></icon>
  </properties>
  <attributes><attribute mode="oneToOne" name="object" type="Cliente"/></attributes>
  <constructors/> <methods/> <events/> <internalClasses/>        <!-- esqueleto fixo, sempre presente -->
  <columns>
    <field><value>.nome</value></field>
    <field><properties><mask><value>cnpj</value></mask><sortable><value>false</value></sortable></properties><value>.numeroDocumento</value></field>
    <field><properties><display><value>badge</value></display></properties><value>.status</value></field>
    …
  </columns>
  <search><properties><placeholder>…</placeholder></properties><field><value>.nome</value></field></search>
  <filters><filter><properties><type><value>faceted</value></type></properties><value>.status</value></filter></filters>
  <actions><action><properties><type><value>primary</value></type><opens><value>CriarCliente</value></opens>…</properties><value>criarCliente</value></action> … </actions>
  <emptyState><properties><message>…</message><action><value>criarCliente</value></action></properties></emptyState>
</class>
```

**Fatos confirmados para o gerador `screen`:**
- `@mode` = `window.list` / `window.dialog` (o `Descriptor.window.*` vira o mode); `package` = `ai.loja.window.<ctx>`.
- Regiões são **filhas diretas** de `<class>`: `<columns>`, `<search>`, `<filters>`, `<actions>`, `<emptyState>`, `<form>`.
- **Campo:** `<field><value>.caminho</value></field>` + `<properties>` opcional (`mask`/`sortable`/`display`/`label`/`width`).
- **Ação:** `<action><value>id</value></action>` + `<properties>` (`type`/`label`/`icon`/`opens`/`navigate`/`condition`).
- **Layout do form preservado (não achatado):** `<form><rows>` com `<field>` (linha inteira) e `<row>` (agrupa campos) — o gerador percorre `form/rows/row` diretamente. (Diferente de steps/abas do `stu-mi`, que achatavam.)
- O bind: `attributes/attribute[@name='object']/@type` = a entidade; o gerador resolve cada `.campo` contra
  `/classes/class[@name=<type> and @mode='bean']/attributes` para puxar tipo/enum/required/title.

---

## 11. Exemplo completo — `GestaoClientes` (a piloto)

Reproduz a tela que hoje existe à mão (`features/clientes/GestaoClientesScreen.tsx` + `columns.tsx`):

```
[Descriptor.window.list] GestaoClientes
    @
        [e] title
            [e] pt
                [v] Gestão dos Clientes
        [e] route
            [v] /clientes
        [e] role
            [v] administrador
        [e] icon
            [v] building
    [g] source
        [r] object: Cliente()
    [e] columns
        [e] field
            [v] .nome
        [e] field
            [v] .numeroDocumento
            @
                [e] mask
                    [v] cnpj
                [e] sortable
                    [v] false
        [e] field
            [v] .segmento
        [e] field
            [v] .status
            @
                [e] display
                    [v] badge
        [e] field
            [v] .dataCriacao
            @
                [e] display
                    [v] date
    [e] search
        @
            [e] placeholder
                [e] pt
                    [v] Buscar por razão social…
        [e] field
            [v] .nome
    [e] filters
        [e] filter
            [v] .status
            @
                [e] type
                    [v] faceted
    [e] actions
        [e] action
            [v] criarCliente
            @
                [e] type
                    [v] primary
                [e] label
                    [e] pt
                        [v] Criar Cliente
                [e] icon
                    [v] plus
                [e] opens
                    [v] CriarCliente
        [e] action
            [v] verDetalhes
            @
                [e] type
                    [v] row
                [e] label
                    [e] pt
                        [v] Ver detalhes
        [e] action
            [v] verContrato
            @
                [e] type
                    [v] row
                [e] label
                    [e] pt
                        [v] Ver contrato
                [e] condition
                    [v] status != 'INATIVO'
    [e] emptyState
        @
            [e] message
                [e] pt
                    [v] Nenhum cliente cadastrado ainda.
            [e] action
                [v] criarCliente
```

E o formulário de criação (modal):

```
[Descriptor.window.dialog] CriarCliente
    @
        [e] title
            [e] pt
                [v] Criar Cliente
        [e] role
            [v] administrador
    [g] source
        [r] object: Cliente()
    [e] form
        [e] rows
            [e] field
                [v] .nome                    # linha inteira
            [e] row                          # documento + tipo na mesma linha
                [e] field
                    [v] .numeroDocumento
                    @
                        [e] mask
                            [v] cnpj
                [e] field
                    [v] .tipoDocumento       # enum → Select (via toShadcn); opções de tipoDocumentoValues/Labels
            [e] field
                [v] .segmento                # linha inteira
    [e] actions
        [e] action
            [v] criar
            @
                [e] type
                    [v] primary
                [e] label
                    [e] pt
                        [v] Criar
```

---

## 12. Convenções e checklist de qualidade

```
[ ] Estereótipo Descriptor.window.* existente, coerente com o papel da tela (novo ícone só se necessário)
[ ] Termos de estrutura em inglês; termos de negócio (nome de tela, .binding, conteúdo, role, enum) em PT
[ ] @ title (pt/en), route (window.list), role, icon (lucide)
[ ] [g] source / [r] object: <Bean>() aponta para um [b] existente no domínio
[ ] Todo field referencia .caminho válido no bean object (validar contra o mapa de domínio)
[ ] Enums/rótulos NÃO redeclarados — vêm do schema gerado (<attr>Values/Labels)
[ ] Ações declaram type (primary|secondary|row); row/condicionais têm condition quando aplicável
[ ] emptyState presente em window.list, referenciando uma action existente
[ ] Sem estilo/cor no mapa (camada 2) e sem lógica imperativa (só condition declarativa)
[ ] Tela registrada em main.mi sob [p] window/<contexto> com # relativo
[ ] Nó não coberto pelo gerador deve virar // @TODO na saída (nunca quebrar)
```

---

## 13. Escopo v1 vs. futuro

- **v1:** `window.list`, `window.dialog`/`window.editor`, navegação (`[e] menu` / `Descriptor.menu`); campos
  escalares/enum; **layout de formulário com `rows`/`cols`/`row`/`col` + `@ width`**; ações com
  `opens`/`navigate`/`condition`; search e filter facetado por enum.
- **Implementado (v1):** `window.operation` + `window.step` (wizard — **§7.2**): runtime `<OperationFlow>`, gerador
  `screenOperation` (step `opens` → embute `<XForm>` reusado; `custom` → tela do pkg `onboarding/`), e a piloto
  `OnboardingExpress` (rota `/onboarding`). *Limite v1:* `opens` só de `editor`/`dialog` (que geram `<XForm>`);
  reuso de `list`/`cards` como passo e resume-de-rascunho ficam pra depois.
- **Futuro:** `window.iframe` (master-detail via `@ inputType` → outra tela, como o iframe do `stu-mi`);
  `window.report` (relatórios); `window.custom` (escape
  para telas fora do padrão gerável); join com entidade relacionada (ex.: coluna "Status do Contrato" via
  `.contrato.status`); filter de campo texto-livre com fonte de opções; i18n plena (usar `title/en`); marcação
  `@ readOnly`/editável no domínio para derivar o subconjunto de formulário.

---

## 14. De quem é o mapa de tela? (decisão de agente)

O mapa de tela é uma **visão de negócio/UX amarrada ao domínio**. Recomendação:

- **v1 (dialeto enxuto, preso ao domínio):** o `business-mapper` ganha a competência de autorar mapas de tela
  (já lê US e conhece o binding). Custo de coordenação baixo.
- **Se crescer UX-pesado** (layouts, iframe/master-detail, wizard, interação rica): destacar um **`screen-mapper`**
  — par de negócio que alimenta o `architect-mapper` (gerador `screen`), replicando a tríade
  (`screen-mapper` escreve o mapa → `architect-mapper` escreve o gerador → `mapperidea-runner` valida).

Em ambos os casos, o gerador `screen` é sempre do `architect-mapper`.

---

## 15. Multi-marca — `usedIn` (build) vs white-label (runtime)

Dois eixos distintos de "marca", que **não se misturam**:

### 15.1 Marca-produto (build-time) — `usedIn`
Produtos/domínios distintos que compartilham API e núcleo, mas têm **conjuntos de telas diferentes** e um
**tema base** próprio. Iniciais: `loja` (completa) e `express` (enxuta); extensível.

- A tela declara `@ usedIn` com uma lista de marcas; **ausente = compartilhada (todas as marcas)**:
```
[Descriptor.window.dialog] OnboardingErp
    @
        [e] usedIn
            [v] express
            [v] cobrafacil       # aplicável a 2 marcas SEM duplicar o mapa
        ...
```
- **Uma árvore de telas só** (`features/<ctx>/<classe>/`) — marca NÃO entra no caminho. Os `.tsx` gerados são
  agnósticos de marca.
- O que entra em cada app é decidido no **build** (`VITE_APP_BRAND=<marca>`): um **manifesto de rotas/nav gerado
  por marca** inclui só as telas cujo `usedIn` contém a marca (ou é ausente), e o build **tree-shakeia** o resto.
  O tema base da marca (camada 2) é selecionado pelo perfil de build.
- **Nova marca** = registrá-la (chave + tema base + domínio) e marcar as telas específicas com `usedIn` — sem
  mexer em estrutura de pastas.
- No DOM, `usedIn` normaliza para `properties/usedIn` (múltiplos `value`); os geradores de tela
  (`screenColumns`/`screenPage`/`screenForm`) o **ignoram** — quem consome é o gerador de **manifesto**
  `screenManifest` (**implementado**): varre todas as janelas e emite `frontend/src/gen/screens.ts`
  (`{name, route, title, stereo, icon?, brands}`). Rodar: `gen-frontend.sh manifest`.
- **Hoje (mock):** a nav (`AppNav`) lê esse manifesto e filtra por marca em **runtime** (seletor de marca do
  preview — `src/config/brand.ts`, `data-brand`), e o tema base troca por `:root[data-brand=…]` (index.css).
- **Futuro (dois builds):** o mesmo manifesto alimenta o filtro de **build** (`VITE_APP_BRAND`) + tree-shake — a
  peça que falta pra separar de fato os apps por marca.

### 15.2 White-label (runtime, por cliente) — camada 2
Um cliente que quer identidade visual própria **não é uma marca em `usedIn`**: usa o **mesmo conjunto de
telas** do produto, com **tokens sobrescritos em runtime** (camada 2 — CSS vars por tenant, vindas da config do
cliente via BFF; `[data-tenant]`). Sem build novo. É o "como o produto se veste para cada cliente", não
"quais telas o produto tem".

| Eixo | O quê | Quando resolve | Mecanismo |
|---|---|---|---|
| `usedIn` (marca-produto) | quais telas existem no produto | build | manifesto de rotas por marca + tema base |
| white-label (cliente) | como o produto se veste | runtime | camada 2 (CSS vars por tenant) |
