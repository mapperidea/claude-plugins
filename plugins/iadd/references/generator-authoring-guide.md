# Guia de autoria de geradores Mapper Idea

**Público**: quem vai escrever o primeiro gerador `.mi` — inclusive quem nunca viu o DSL.
**Pré-requisito**: [o pipeline IADD](../docs/pipeline-iadd.md), pelo menos §2 e §4.
**Companheiro obrigatório**: o pack exemplar em [`../packs/_exemplar/`](../packs/_exemplar/), que é o
código que este guia explica. Leia os dois lado a lado.

Este documento existia antes — **dentro do prompt de um agente**. Era conhecimento pronto no lugar errado:
disponível para a IA e indisponível para a pessoa que quer escrever o gerador dela. Aqui ele é um documento.

---

## 1. O modelo mental

Um gerador Mapper Idea é uma **folha de transformação**: ele casa nós de uma árvore (o DOM do seu modelo de
negócio) e **emite texto**. Quem já viu XSLT reconhece a estrutura — `match`, `apply-templates`, modos,
prioridade de template. Quem nunca viu só precisa reter três frases:

1. **A entrada não é o seu arquivo `.mi`. É o DOM que o servidor produz a partir dele.** São árvores
   diferentes, e escrever `match` contra a que você *escreveu* em vez da que *existe* é o erro nº 1.
2. **A saída é texto puro.** O gerador não sabe o que é Java, TypeScript ou SQL — ele sabe emitir linhas.
3. **Você não escreve laços.** Você declara *padrões* (`patterns`) e *regras* (`templates`), e diz "aplique
   as regras do modo X sobre este conjunto de nós". O motor decide qual regra casa cada nó.

### Os ícones que você precisa conhecer

`.mi` é texto indentado onde cada linha é um nó, e o prefixo `[x]` é o *ícone* — o tipo do nó.
Para autoria de gerador, esta tabela basta:

| Ícone | Nome | Para que serve num gerador |
|---|---|---|
| `[e]` | element | nó estrutural — `parameters`, `vars`, `patterns`, `templates`, `match`, `body`… |
| `[v]` | value | **emite uma linha** (com quebra de linha no fim) ou carrega um valor escalar |
| `[y]` | tag_yellow | **concatena sem quebra de linha** — junta pedaços na mesma linha de saída |
| `[g]` | group | agrupador **puramente visual**; some na normalização. Use para organizar `patterns` |
| `#` | include | inclui outro arquivo `.mi` naquele ponto (caminho relativo ao arquivo que inclui) |
| `//` | comment | comentário — **o texto vai num nó filho**, nunca na mesma linha |

No mapa de **negócio** você verá também `[b]` (entidade persistível), `[c]` (tipo auxiliar),
`[d]` (atributo escalar), `[r]` (referência), `[m]`/`[o]` (os dois lados de uma relação forte),
`[p]` (pacote) e `@` (bloco de propriedades). Você **lê** esses; não os escreve.

### Três regras de sintaxe que quebram tudo em silêncio

- **Nunca misture tabs e espaços** no mesmo arquivo. A hierarquia é a indentação.
- **O conteúdo é sempre filho, nunca irmão.** O texto de um `match` é um `[v]` *dentro* do `[e] match`.
- **`Tipo()` sempre com parênteses**, mesmo sem parâmetro.

---

## 2. A regra zero: struct-first

**Não escreva um `match` antes de ter olhado o DOM.**

```sh
mi push <projeto>
mi generate <projeto> struct xml className=Pedido packageName=com.exemplo.dominio > /tmp/pedido.xml
```

O `struct` é um gerador como qualquer outro — ele só emite o DOM em XML em vez de emitir código. É o
microscópio do método, e está no pack exemplar (`generators/struct.mi`) para você copiar no seu projeto.

Você olha o XML e responde três perguntas antes de escrever qualquer coisa:

1. **O atributo que me interessa existe?** (o que some, some em silêncio)
2. **Qual é o `@type`, o `@mode` e o `@typeParameter` dele?**
3. **As `properties` que meu gerador vai ler estão lá?** (`required`, `cn`, `values`, `title`…)

---

## 3. O DOM normalizado — referência

```xml
<classes>
  <class name="Pedido" mode="bean" package="com.exemplo.dominio">
    <attributes>
      <attribute name="numero" mode="directToField" type="Texto" typeParameter="20">
        <properties>
          <cn><value>numero</value></cn>
          <required><value>true</value></required>
          <title><pt><value>Número do pedido</value></pt><en>…</en></title>
          <description><pt><value>…</value></pt></description>
        </properties>
      </attribute>
      <attribute name="situacao" mode="directToField" type="Texto" typeParameter="20">
        <properties>
          <values>
            <RASCUNHO><title><pt><value>Rascunho</value></pt></title></RASCUNHO>
            <CONFIRMADO>…</CONFIRMADO>
          </values>
        </properties>
      </attribute>
      <attribute name="cliente" mode="manyToOne" type="Cliente"/>
      <attribute name="itens"   mode="oneToMany" type="ItemPedido"/>
    </attributes>
  </class>
</classes>
```

### O que a normalização faz com o que você escreveu

| No mapa de negócio | No DOM |
|---|---|
| `[g] identificacao` agrupando atributos | **some** — todos os atributos ficam direto sob `attributes` |
| `[d] numero: Texto(20)` | `attribute[@name='numero'][@type='Texto'][@typeParameter='20'][@mode='directToField']` |
| `[r] cliente: Cliente()` | `@mode = 'oneToOne'` ou `'manyToOne'` |
| `[o] itens: ItemPedido()` | `@mode = 'oneToMany'` |
| `[m] pedido: Pedido()` | `@mode = 'manyToOne'` |
| bloco `@` com `required`, `cn`, `values`, `title` | `properties/required`, `properties/cn`, `properties/values/*`, `properties/title/pt/value` |
| chave `@` **que o vocabulário não conhece** | **descartada, em silêncio** |

Essa última linha é a armadilha mais cara do DSL, e vale repetir: o DOM materializa um **vocabulário
conhecido** de propriedades (`type`, `label`, `icon`, `required`, `cn`, `values`, `title`, `description`,
`mask`, `display`, `sortable`, `placeholder`, `route`, `opens`, `condition`…). Uma chave inventada por você
não vira erro — vira nada. `exists(properties/minhaChave)` simplesmente é `false` para sempre. Antes de
inventar uma propriedade, procure uma conhecida que signifique a mesma coisa.

### Como se diz "isto é uma relação"

Não existe atributo `isRelation`. A regra é:

> **relação = `@type` que NÃO está no dicionário `mapNativeTypes`.**

Na prática você ramifica por `@mode`: `directToField` é escalar, qualquer outro valor é relação.

---

## 4. Anatomia — as sete seções

Todo gerador tem a mesma espinha. Na ordem em que você vai escrevê-las:

| Seção | O que é | Obrigatória? |
|---|---|---|
| `parameters` | entradas da invocação, com valor default (`NOT_DEFINED` por convenção) | sim, na prática |
| `vars` | variáveis de gerador, resolvidas uma vez (node-set via `select`, escalar via `expr`) | quase sempre |
| `fragments` | pedaços de XPath reutilizáveis, chamados com `f#[nome]` dentro dos patterns | opcional |
| `patterns` | os moldes de texto — cada `[v]` é uma linha de saída, com `{{ xpath }}` interpolado | sim |
| `start` | a regra de entrada: `match` (o nó-raiz da geração) + `body` (o que fazer) | **sim** |
| `templates` | as regras por `mode`, disparadas pelos `apply-templates` do `body` | sim, se houver dispatch |
| `inject` | importa um *injectable* (módulo sem `start`/`parameters`) compartilhado entre geradores | opcional |

As instruções que existem dentro de um `body`:

| Instrução | O que faz |
|---|---|
| `write-pattern` | escreve o pattern nomeado, avaliando os `{{ }}` no **nó de contexto atual** |
| `apply-templates` | percorre os nós de `select` aplicando as regras do `mode` indicado |
| `vars` | declara variável local do corpo — **com `expr`**, nunca com `select` (ver §9) |
| `if` | condicional em volta de um trecho do corpo |

---

## 5. O exemplar, decisão a decisão

O pack `_exemplar` gera uma `interface` TypeScript por entidade. São ~109 linhas de `.mi` — mas só
**oito decisões**. É isso que você replica para qualquer alvo.

**Decisão 1 — a unidade de geração.** Um arquivo por classe. Isso se declara no `start`:

```
[e] start
    [e] match
        [v] /classes/class[@name = $modelName and @package = $package]
```

O gerador roda uma vez por invocação, para **uma** classe; quem varre a lista de entidades é o script do
projeto, não o gerador. (Um gerador que itera todas as classes de um pacote também é possível — o `match`
passa a ser o pacote e o `start` faz `apply-templates` sobre `class`. Comece pelo simples.)

**Decisão 2 — os parâmetros.** Por-entidade, a dupla canônica é `modelName` + `package`. Eles chegam pela
linha de comando (`modelName=Pedido package=com.exemplo.dominio`) e viram `$modelName` e `$package`.

**Decisão 3 — carregar o dicionário de tipos.**

```
[e] vars
    [e] mapNativeTypes
        [e] select
            [v] //maps/mapNativeTypes
```

Isso lê o bloco `config/mapperidea/maps/mapNativeTypes` do `main.mi`, onde as famílias de tipo são
declaradas **uma vez para todos os geradores**. É o *seam* do DSL — o lugar onde "`ValorMonetario` é um
Double" é dito, em vez de repetido em 16 templates.

**Decisão 4 — os moldes de texto.** Cada `[v]` dentro de um pattern é uma linha; `{{ … }}` interpola XPath
avaliado no nó atual:

```
[e] interface-start
    [v] export interface {{ @name }} {
```

**Decisão 5 — o fragmento.** A pergunta "este campo é opcional?" aparece em todas as linhas de campo.
Escreva-a uma vez:

```
[e] fragments
    [e] optionalMark
        [v] mi:if-else(exists(properties/required), '', '?')
```

e chame com `{{ f#[optionalMark] }}`. O fragmento é substituído **textualmente antes** da avaliação do
XPath — é macro, não função.

**Decisão 6 — o corpo.** Cabeçalho, abertura, o laço sobre os atributos, fechamento:

```
[e] body
    [e] write-pattern
        [v] header
    [e] write-pattern
        [v] interface-start
    [e] apply-templates
        [e] select
            [v] attributes/attribute
        [e] mode
            [v] fields
    [e] write-pattern
        [v] interface-end
```

**Decisão 7 — o dispatch.** É o coração, e tem seção própria (§7).

**Decisão 8 — o catch-all.** O último template do modo casa `attribute` puro e emite um `@TODO`. Ver §7.3.

---

## 6. Patterns, mustache e funções

- `{{ expressão }}` dentro de um `[v]` interpola. O contexto é o nó do `match` do template que chamou.
- `[v]` quebra linha; **`[y]` não** — use `[y]` para montar uma linha a partir de vários nós.
- **Um `[v]` vazio não emite uma linha em branco: não emite nada.** O nó sem texto some na normalização —
  e isso vale inclusive para um pattern dedicado só a isso. Para emitir linha em branco, use `[v] {{ '' }}`.
- Chaves literais na saída (JSX, TS genéricos, blocos `{}`) colidem com o mustache. **Escape**:
  `{\{ … }\}` gera `{{ … }}`.

Funções que você vai usar no primeiro dia:

| Função | Para quê |
|---|---|
| `mi:first-upper(s)` / `mi:first-lower(s)` | `Pedido` ↔ `pedido` |
| `mi:lower-case-add-underline(s,'')` | `PedidoItem` → `pedido_item` (snake) |
| `mi:lower-case-add-hifen(s,'')` | `PedidoItem` → `pedido-item` (kebab) |
| `mi:if-else(teste, entao, senao)` | condicional inline — o `?:` do DSL |
| `mi:replicate(s, n)` | indentação, separadores |
| `mi:tabulate-text(texto, tab, largura)` | comentário/Javadoc a partir da `description` |
| `position()` / `last()` | vírgula em todos menos no último: `mi:if-else(position() = last(), '', ',')` |
| `exists(seq)` / `not(exists(seq))` | o teste mais frequente de todos |
| `string-join(seq, sep)` + `for $x in … return …` | unir valores — ex.: o enum vira `"A" \| "B"` |

XPath 2.0 padrão e a biblioteca `functx:` estão disponíveis.

---

## 7. Dispatch por tipo — o mecanismo central

### 7.1 Ramifique pelo dicionário, nunca por literal

```
[e] template
    [e] match
        [v] attribute[@type = $mapNativeTypes/String/value and not(exists(properties/values))]
```

Não escreva `attribute[@type='Texto']`. No dia em que o modelo usar `varchar`, `Caractere` ou `String`, o
literal não casa e o campo cai no catch-all. **Tipo novo se resolve adicionando um sinônimo à família no
`maps`** — em um lugar, para todos os geradores.

### 7.2 Torne os `match` mutuamente exclusivos

Um enum é `String` **e** tem `values`: dois templates o casam. E aqui está a armadilha que ninguém adivinha:

> Templates de mesma especificidade têm **prioridade igual**, e no empate o motor usa o **último em ordem de
> documento** — não o primeiro.

Nunca dependa da ordem. Torne os predicados exclusivos: o específico testa `exists(properties/values)`, e o
genérico testa `not(exists(properties/values))`. O exemplar faz exatamente isso.

### 7.3 TODO-on-unhandled — o último template, sempre

```
[e] template
    [e] match
        [v] attribute
    [e] body
        [e] write-pattern
            [v] field-todo
```

emitindo `// @TODO tipo nao tratado: {{ @name }} (type={{ @type }} mode={{ @mode }})`.

Isso transforma o modo de falha padrão — **campo somindo em silêncio** — em um comentário visível no código
gerado, que o build ou a revisão pega. Um gerador sem catch-all mente por omissão.

---

## 8. Registro no `main.mi` e invocação

```
[e] generators
    [e] typescript              ← GRUPO
        [e] type                ← SUB-GERADOR
            #
                generators/ts-type.mi
```

```sh
mi generate <projeto> typescript type modelName=Pedido package=com.exemplo.dominio > src/types/Pedido.ts
```

Três regras que custam uma tarde quando ignoradas:

1. **A invocação são exatamente 2 tokens**: `<grupo> <sub>`. Não existe terceiro nível. Um `main.mi` com
   `grupo/sub/subsub` simplesmente **não é invocável** — sintoma: saída vazia e exit 0.
2. **A raiz do arquivo do gerador tem de ser o nome do sub-gerador.** O `#` mescla o nó-pai com a raiz do
   arquivo incluído: `[e] type` no `main.mi` + arquivo cuja primeira linha é `[e] type`.
3. **O `#` usa caminho relativo ao arquivo que o contém.**

A saída vai para `stdout` — quem decide o caminho do arquivo é o **redirecionamento**, e é por isso que o
projeto tem um script que mapeia entidade → caminho de destino em vez de o gerador saber onde escrever.

---

## 9. Variáveis: `select` vs `expr`, gerador vs corpo

| Onde | Como declarar | Erro se trocar |
|---|---|---|
| `vars` do **gerador** (nível topo) | `[e] select` com o XPath | — |
| `vars` dentro do **corpo de um template** | `[e] var` + `[e] expr` | `EMI2005: The expression is empty` / `<variable select=""/>` |

Variáveis são **imutáveis**. Não existe "acumular numa variável": para somar, junte com `string-join`, ou
repense em termos de `apply-templates`.

Cuidado com **sombreamento**: uma `var` de corpo com o mesmo nome de um parâmetro de template, num caminho
onde o nó pode ser nulo, produz vazio silencioso. Renomeie.

---

## 10. Relacionamento e navegação cross-class

Dentro de um `attribute` de relação, `@type` é o **nome da classe-alvo**. Para chegar nela, você precisa da
raiz global — declare uma var:

```
[e] classes
    [e] select
        [v] /classes
```

e navegue: `$classes/class[@name = current()/@type]/attributes/attribute[…]`.

**A armadilha de contexto** (custa horas, e o sintoma engana): num predicado aninhado, um passo relativo
**rebinda** para o nó de dentro, não para o de fora. Em

```
field[ $dom/attribute[@name = substring(value,2)] ]
```

o `value` de dentro é o do nó de domínio, não o do `field`. Corrija ligando o nó externo explicitamente:

```
for $f in field[…] return substring($f/value,2)
```

ou, **em corpo de template** (nunca em `match`), use `current()`.

E a irmã dela: **função como passo de caminho é XPath inválido** — `field[…]/substring(value,2)` aborta a
compilação do gerador, com **saída vazia e exit 0**. Use a forma `for … return …`.

**Relação aninhada é o ponto cego nº 1** (ex.: grade → detalhe → `oneToMany`). Um XPath que só olha o
atributo de topo perde as classes referenciadas transitivamente — e o sintoma aparece longe, num `import`
faltando no código gerado.

---

## 11. Playbook de armadilhas

| Sintoma | Causa provável | O que fazer |
|---|---|---|
| **Saída vazia, exit 0** | `start match` não casou, ou uma expressão de `var` abortou a compilação | rode o `generate` e leia o erro `EMI…` (ele **não** aparece no `push`); confira `modelName`/`package` contra o DOM |
| **Gerador "não existe"** | registrado em 3 níveis, ou raiz do arquivo ≠ nome do sub | §8 |
| **Template não dispara** | `@type` fora do `mapNativeTypes`, ou `@mode` diferente do imaginado | confira no `struct` |
| **Dois templates casam o mesmo nó** | prioridade igual → vence o **último** | predicados mutuamente exclusivos |
| **`properties/algo` sempre vazio** | propriedade fora do vocabulário conhecido → descartada no DOM | reuse uma propriedade conhecida |
| **`title`/`values` vazio dentro de um template** | profundidade relativa errada ao nó atual | confira o caminho no XML do `struct` |
| **Identificador inválido na saída** (`a.b`) | nome com ponto | `translate(nome,'.','_')` |
| **`EMI2005: expression is empty`** | `var` de corpo declarada com `select` | use `expr` (§9) |
| **Chave `{` do alvo some ou quebra** | colisão com mustache | escape `{\{ … }\}` |
| **Literal TS alargado para `string`** | objeto literal em TypeScript | emita `} as const` |
| **`grep` mata seu script de geração** | `grep` sem casamento retorna 1 e, sob `set -e`/`pipefail`, aborta | encadeie `\|\| true` |
| **Linha em branco não sai** | `[v]` vazio — nó sem texto some na normalização | `[v] {{ '' }}` |
| **Correção funcionou numa variante e não nas irmãs** | famílias de gerador compartilham a lógica | varra a correção em todas |

---

## 12. Checklist antes de entregar um gerador

```
[ ] Sub-gerador registrado no main.mi (grupo/sub) com # relativo; raiz do arquivo = nome do sub
[ ] parameters declarados com default NOT_DEFINED
[ ] DOM real inspecionado via struct — os match conferem com a forma normalizada
[ ] Dispatch usa mapNativeTypes, não literais de tipo
[ ] Dispatch cobre todas as famílias usadas pelas entidades-alvo
[ ] Sem overlap de match (predicados de exclusão onde dois poderiam casar)
[ ] Catch-all @TODO no fim de cada modo
[ ] Identificadores sanitizados onde o nome puder conter ponto
[ ] push + generate numa entidade REAL: saída não-vazia e sintaticamente válida
[ ] A saída passa no build/typecheck do projeto que a consome
```

---

## 13. O que você provavelmente vai querer mudar aqui

Este guia e o pack exemplar são **semente**: você copia, adapta e passa a ser dono. Os pontos onde quase
todo mundo mexe, e o que considerar em cada um:

- **O alvo.** O exemplar emite TypeScript porque é a linguagem com menos cerimônia para demonstrar. Trocar
  para Java, C#, SQL ou ADVPL/TLPP muda os `patterns` — **não muda nada do resto**. É essa a evidência de
  que o método transfere.
- **A unidade de geração.** Um arquivo por classe é o começo. Manifesto único, um arquivo por pacote ou um
  arquivo por relação são variações do `start match`.
- **As famílias de tipo.** O `mapNativeTypes` do exemplar é mínimo de propósito. O seu vai crescer com os
  sinônimos que o seu modelo usa — e é lá que ele deve crescer, não nos templates.
- **O vocabulário de propriedades.** Antes de inventar uma chave `@`, confira se ela sobrevive à
  normalização (§3). Se não sobreviver, reuse uma conhecida.
- **A convenção de nomes.** `patterns` com nome `field-<familia>` e modos com nome de seção do arquivo de
  saída é convenção deste pack, não regra do DSL. Mantenha *alguma* convenção: geradores grandes viram
  ilegíveis sem ela.
