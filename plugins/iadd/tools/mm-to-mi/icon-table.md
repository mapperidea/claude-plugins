# Tabela de ícones — FreeMind (`.mm`) → Mapper Idea (`.mi`)

O ícone é o **tipo do nó**. Num `.mm` ele é um `<icon BUILTIN="…"/>`; num `.mi` é o prefixo `[x]` da linha.
A tradução entre os dois vive no `xsl:choose` de [`exportMI.xsl`](exportMI.xsl) — e é ela que você vai
querer estender quando um mapa seu usar um ícone que a folha não conhece.

`convert.sh` lê esta correspondência **da própria folha de estilo**, para que código e documentação não
divirjam. Mudou o `xsl:choose`, mudou o comportamento do relatório.

## Conhecidos

| `BUILTIN` do FreeMind | Atalho `.mi` | Significado |
|---|---|---|
| `element` | `[e]` | elemento estrutural |
| `tag_green` | `[v]` | valor / linha de saída |
| `tag_yellow` | `[y]` | concatenação sem quebra de linha |
| `Descriptor.grouping` | `[g]` | agrupador visual |
| `bricks` | `[g]` | agrupador visual (ícone alternativo) |
| `Package` | `[p]` | pacote |
| `Descriptor.class` | `[c]` | classe / tipo auxiliar |
| `Descriptor.bean` | `[b]` | entidade persistível |
| `Mapping.directToField` | `[d]` | atributo escalar |
| `Mapping.oneToOne` | `[r]` | referência |
| `Mapping.oneToMany` | `[o]` | coleção (lado mestre) |
| `Mapping.manyToOne` | `[m]` | referência ao mestre (lado detalhe) |
| `Mapping.directMap` | `[h]` | mapeamento direto |
| `Method.public` | `[x]` | método |
| `elementOutput` | `[x]` | saída de elemento |
| `textNode` | `[t]` | nó de texto |
| `bullet_key` | `[k]` | chave |

## A família que passa crua de propósito

Os **estereótipos de tela** não têm atalho de uma letra: no `.mi`, o nome completo do ícone **é** o
atalho, e a normalização o transforma em `@mode`.

```
[Descriptor.window.editor] ProdutoForm      →   class[@mode="window.editor"]
```

| `BUILTIN` | No `.mi` | Vira |
|---|---|---|
| `Descriptor.window.editor` | `[Descriptor.window.editor]` | `mode="window.editor"` |
| `Descriptor.window.list`, `.dialog`, `.iframe`, `.operation`, `.step`, `.report`, `.custom` | idem | `mode="window.<x>"` |

Por isso o `convert.sh` **não** os reporta como não mapeados — ele os lista à parte, como informação.
Tratá-los como erro era um falso alarme que mandava o usuário "consertar" o que já estava certo.

*(Descoberto em 25/09/2026 convertendo um projeto Angular real de demonstração de telas: os únicos dois
ícones "desconhecidos" eram `window.editor` e `window.iframe`, e o precedente de `.mi` escrito à mão
confirma que a forma crua é a correta.)*

## O que acontece com um ícone desconhecido

**Nada — e esse é o problema.** O `xsl:otherwise` copia o nome cru para dentro dos colchetes:

```
[Field.public] currentUser: ThreadLocal()
```

Isso não é erro de conversão visível: é um `.mi` que *parece* bom e que o `push` vai recusar ou, pior,
normalizar de um jeito que você não previu. Por isso `convert.sh` **compara os ícones usados em cada `.mm`
contra a lista conhecida e reporta a diferença**. Leia o relatório; ele é metade do valor da ferramenta.

## Encontrados na prática, ainda sem atalho

Levantados sobre 7 mapas reais (1,31 MB) em 17/09/2026. Estão listados aqui como **trabalho pendente de
decisão**, não como omissão da folha de estilo — cada um precisa de uma resposta que só quem conhece a
intenção do DSL pode dar:

| `BUILTIN` | Onde apareceu |
|---|---|
| `Field.public` | customizer, helper, service, validation |
| `Descriptor.interface` | helper, validation |
| `Descriptor.hierarchy` | mapa principal |
| `Descriptor.menu` | window |
| `Descriptor.window.editor` | window |
| `Descriptor.window.list` | window |
| `Descriptor.window.report` | window |
| `Policy.events` | mapa principal, window |
| `Policy.multiTableInfo` | mapa principal |
| `File.folder`, `File.text`, `File.xml` | mapa principal |
| `yes` | window |

**Cada ícone desconhecido tem quatro destinos possíveis, e escolher entre eles é decisão de produto:**

0. **O nome cru já é o atalho** — como os estereótipos de tela acima. Nada a fazer, mas o conversor precisa
   saber disso para não alarmar.

1. **Ganha um atalho** — é um conceito do DSL que a folha ainda não traduz (provável para `Field.public`,
   `Descriptor.interface`, os `Descriptor.window.*`).
2. **É ignorado** — é decoração do FreeMind, sem significado no `.mi` (provável para `yes`, que é o
   ícone de "visto" do editor). Ignorar deliberadamente é diferente de deixar passar cru.
3. **Vira erro** — o mapa usa algo que o dialeto atual não suporta, e converter em silêncio é pior do que
   falhar alto.

Enquanto a decisão não for tomada, o destino real é o pior dos três: passa cru. O relatório é o que impede
que isso passe despercebido.

## Como estender

1. Acrescente um `<xsl:when test="$iconName = 'SeuIcone'">a</xsl:when>` ao `xsl:choose` de `exportMI.xsl`
   (para ignorar, emita string vazia).
2. Acrescente a linha correspondente à tabela **Conhecidos** acima.
3. Rode `convert.sh` de novo e confirme que o ícone sumiu do relatório.
4. `mi push` e `struct`: a conversão só termina na validação do DOM.
