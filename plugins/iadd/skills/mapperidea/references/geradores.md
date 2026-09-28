# Mapa de Arquitetura — anatomia e padrões de gerador

*Referência da skill `mapperidea` — carregada sob demanda. Volte ao `SKILL.md` para o roteiro.*

## Mapa de Arquitetura — Geradores

### Estrutura Geral do Mapa

```
[p] com.example
    config
        [e] mapperidea
            [e] generators
                [e] nomeGerador
                    ...
    [p] domain
        [b] MinhaClasse
            ...
```

### Anatomia de um Gerador

```
[e] nomeGerador
    #                              ← referência a arquivo externo (opcional)
        ../main.mm
    [e] parameters
        [e] nomeParametro
            [v] VALOR_PADRAO
    [e] vars
        [e] nomeVar
            [e] select
                [v] //xpath/para/valor
    [e] inject
        [v] nomeInjectable
    [e] start
        [e] match
            [v] classes/class[@name=$nomeParametro]
        [e] body
            [e] write-pattern
                [v] nomePattern
            [e] apply-templates
                [e] select
                    [v] attributes/attribute
                [e] mode
                    [v] nomeModo
    [e] fragments
        [e] nomeFragmento
            [v] expressaoXPath
    [e] patterns
        [e] nomePattern
            [v] linha de código {{ expressaoXPath }}
            [v] outra linha {{ @name }}
    [e] templates
        [e] mode
            [v] nomeModo
            [e] template
                [e] match
                    [v] attribute[@type='Texto']
                [e] body
                    [e] write-pattern
                        [v] nomePattern
```

### Instruções de Gerador

| Instrução | Propósito |
|-----------|-----------|
| `[e] start` | Ponto de entrada do gerador |
| `[e] match` | XPath que seleciona o contexto de execução |
| `[e] body` | Bloco de execução |
| `[e] write-pattern` | Escreve o conteúdo de um pattern nomeado |
| `[e] apply-templates` | Loop: seleciona elementos com `select` e aplica `mode` |
| `[e] patterns` | Define templates de código (texto com `{{ xpath }}`) |
| `[e] templates > mode` | Agrupa templates por modo de processamento |
| `[e] template` | Template com `match` + `body` dentro de um `mode` |
| `[e] fragments` | Fragmentos XPath reutilizáveis (referência: `f#[nome]`) |
| `[e] injectables` | Módulos reutilizáveis (sem `start`/`parameters`) |
| `[e] inject` | Importa um injectable dentro de um gerador |
| `[e] vars` | Variáveis globais do gerador, preenchidas via XPath |

### Expressões em Patterns (Mustache)

Dentro de `[v]` use `{{ expressaoXPath }}` para injetar valores dinâmicos. O contexto XPath é determinado pelo `match` do template ou `start` que chamou o `write-pattern`.

```
[v] public class {{ @name }} {
[v]     private {{ $class/@name }} {{ @name }};
[v] CREATE TABLE {{ mi:lower-case-add-underline(@name,'') }}
[v] {{ mi:if-else(position() = last(), '', ',') }}
```

### Fragments

Reutilize expressões XPath complexas com `f#[nome]`:

```
[e] fragments
    [e] paramSeparator
        [v] mi:if-else(position() = last(), '', ',')
    [e] tituloUpper
        [v] upper-case(properties/titulo/value)

[e] patterns
    [e] construtorParam
        [v] {{ @name }}{{ f#[paramSeparator] }}
    [e] logAtributo
        [v]     console.log('=== {{ f#[tituloUpper] }} ===');
```

O fragmento é substituído textualmente **antes** da avaliação do XPath.

### Injectables

Módulos sem `start`/`parameters` para reuso entre geradores:

```
[e] mapperidea
    [e] injectables
        [e] javaCommons
            [e] patterns
                [e] openBrace
                    [v] {
            [e] templates
                [e] mode
                    [v] tiposJava
                    [e] template
                        [e] match
                            [v] attribute[@mode='directToField']
                        [e] body
                            [e] write-pattern
                                [v] openBrace
    [e] generators
        [e] meuGerador
            [e] inject
                [v] javaCommons
            [e] start
                ...
```

---

---

## Padrões Avançados de Geradores

Esta seção rege as regras de engenharia de templates para a Máquina de Inferência. O desenvolvimento de geradores exige rigor no gerenciamento de escopos e navegação de nós .

### 1. Gerenciamento de Variáveis (`vars`): `select` vs `expr`

As variáveis no Mapper Idea são estritamente imutáveis. Elas podem ser declaradas no escopo global do gerador ou no escopo local dentro de um `[e] body` . Existem duas formas de definição com comportamentos distintos:

* **Sintaxe de Seleção (`[e] select`):** Deve ser usada exclusivamente para extrair e armazenar conjuntos de nós (node-sets) puros vindos do DOM .
    ```mi
    [e] vars
        [e] classes
            [e] select
                [v] /classes
    ```
* **Sintaxe de Expressão (`[e] expr`):** Deve ser usada para computar valores escalares dinâmicos, concatenar strings ou executar funções lógicas complexas . Permite também o uso do nó filho `[e] onError` para definir um valor de fallback caso o XPath falhe .
    ```mi
    [e] vars
        [e] var
            [v] optimisticLock
            [e] expr
                [v] if (/classes/package[@name = $package]/properties/optimisticLock/value = 'false') then 'NO' else 'YES'
    ```

### 2. Navegação Cross-Reference via Raiz Global (`$classes`)

Quando estiver processando o contexto isolado de uma classe ou atributo, você pode realizar cruzamentos tridimensionais de dados consultando o nó raiz `/classes` mapeado globalmente. Isso permite que um elemento descubra relações e metadados situados fora do seu próprio bloco de pacotes .

* **Exemplo (Descobrir o nome do campo `manyToOne` inverso em um relacionamento bidirecional):**
    ```mi
    [v] @OneToMany(mappedBy="{{ $classes/class[@name=$currentClassType]/attributes/attribute[@mode='manyToOne' and @type=$currentClassType]/@name }}")
    ```

### 3. Protocolo de Engenharia de Estado e Recursão

Como as variáveis são imutáveis, loops complexos ou processamentos de fluxos de dependência não aceitam acumuladores tradicionais. O estado atualizado deve ser explicitamente propagado como parâmetro a cada nova chamada de template .

* **Passo 1 (Criação do Estado):** Defina as variáveis com o estado inicial no ponto de partida .
* **Passo 2 (Envio do Parâmetro):** Dentro do bloco `[e] apply-templates`, insira o nó `[e] parameters` contendo os estados atuais encapsulados em um `[e] expr` .
* **Passo 3 (Recebimento no Destino):** No `[e] template` receptor, declare o bloco `[e] parameters` clonando os nomes enviados e definindo o valor padrão como `NOT_DEFINED` . Use o prefixo `$` para ler o estado.
* **Passo 4 (Avanço Recursivo):** Calcule o próximo estado em uma variável local e invoque o `apply-templates` recursivamente enviando a nova variável se a condição de parada não for atingida .

**Exemplo Canônico de Repasse de Estado (Fila de Processamento):**
```mi
// 1. Ponto de chamada enviando o estado
[e] apply-templates
    [e] select
        [v] class[@name = $classQueue[1]]
    [e] parameters
        [e] classQueue
            [e] expr
                [v] $nextClassQueue
        [e] processedClassQueue
            [e] expr
                [v] $updatedProcessedQueue
    [e] mode
        [v] definitions

// 2. Ponto de recepção no template correspondente
[e] mode
    [v] definitions
    [e] template
        [e] match
            [v] class
        [e] parameters
            [e] classQueue
                [v] NOT_DEFINED
            [e] processedClassQueue
                [v] NOT_DEFINED
        [e] body
            // O estado fica acessível via $classQueue e $processedClassQueue
            ...

```

### 4. `vars` com `expr` — variáveis computadas

Além de `select` (que seleciona nós XPath), `vars` pode usar `expr` para computar um valor dinâmico:

```
[e] vars
    [e] currentClassType
        [e] expr
            [v] concat(substring-after($package,'.domain.'),'.',$modelName)
    [e] optimisticLock
        [e] expr
            [v] if (/classes/package[@name = $package]/properties/optimisticLock/value = 'false') then 'NO' else 'YES'
```

- `select` → retorna um conjunto de nós (node-set), navegável com XPath
- `expr` → avalia uma expressão e retorna um valor escalar (string, boolean, etc.)

`$optimisticLock` acima lê uma propriedade da classe/pacote e devolve `'YES'` ou `'NO'`, simplificando condicionais nos patterns.

---

### 5. Manipulação de nomes de pacote

Padrão recorrente para construir `package` e `import` a partir do atributo `@package` da classe. O `@package` tem formato `com.empresa.domain.subdominio`:

```
[v] package {{ substring-before(@package,'.domain.') }}.{{ substring-after(@package,'.domain.') }}.entity;
```
→ `com.empresa.domain.pessoa` → `package com.empresa.pessoa.entity;`

```
[v] import {{ substring-before(@package,'.domain.') }}.{{ substring-after(@package,'.domain.') }}.domain.{{ @name }};
```
→ `import com.empresa.pessoa.domain.Pessoa;`

Padrão com variável `$package` do parâmetro:
```
[v] import {{ substring-before($package, '.domain.') }}.{{ $packageAttribute }}domain.{{ $nameAttribute }};
```

---

### 6. Lógica condicional dentro de `[v]`

XPath `if/then/else` funciona diretamente dentro de `{{ }}` nos patterns:

```
[v] {{ if ($optimisticLock = 'YES') then 'import jakarta.persistence.Version;' else 'import jakarta.persistence.Transient;' }}
[v] {{ if ($optimisticLock = 'YES') then '@Version' else '//For future use of optimistic lock' }}
[v] {{ if (properties/defaultValue/value) then concat('"',properties/defaultValue/value,'"') else 'null' }}
[v] {{ if (properties/id/column/value) then upper-case(properties/id/column/value) else concat('ID_',upper-case(properties/table/value)) }}
```

Útil para gerar código que varia por flag de propriedade sem criar múltiplos templates.

---

### 7. Propriedades em classes e pacotes

Além de atributos, **classes e pacotes** também podem ter `@` com propriedades — e os geradores as leem via XPath:

**No mapa de negócios:**
```
[b] MinhaClasse
    @
        table: TB_MINHA_CLASSE
        optimisticLock: false
    [g] atributos
        [d] nome: Texto(128)
            @
                column: NM_NOME
                defaultValue: Sem nome
```

**No gerador, acessando:**
```
[v] @Table(name = "{{ upper-case(properties/table/value) }}")
[v]         this.{{ @name }} = {{ if (properties/defaultValue/value) then concat('"',properties/defaultValue/value,'"') else 'null' }};
```

**Propriedades de pacote** (acessadas pelo XPath absoluto):
```
/classes/package[@name = $package]/properties/optimisticLock/value
```

---

### 8. Cross-reference entre classes via `$classes`

A variável `$classes` (carregada via `vars` com `select: /classes`) permite navegar por todas as classes do mapa de dentro de um template:

```
[e] vars
    [e] classes
        [e] select
            [v] /classes
```

Uso no pattern — encontrar o atributo `manyToOne` da classe relacionada:
```
[v] @OneToMany(mappedBy="{{ $classes/class[@name=$currentClassType]/attributes/attribute[@mode='manyToOne' and @type=$currentClassType]/@name }}", fetch = FetchType.LAZY)
```

Outro uso — carregar uma classe de configuração especial pelo nome:
```
[e] classSchema
    [e] select
        [v] /classes/class[@name = 'CurrentSchema']
```

---

### 9. Anotações compostas com `[y]` (tag_yellow)

O ícone `[y]` é usado para construir anotações em partes, que são montadas condicionalmente pelos templates. Cada parte é um pattern separado:

```
[g] annotation
    [e] annotation-oneToOne-inicio
        [y]     @ManyToOne(
    [e] annotation-oneToOne-fim
        [v] )
        [v]     @JoinColumn(name="{{ f#[column] }}", nullable = true)
    [e] annotation-fetch-eager
        [y] fetch = FetchType.EAGER
    [e] annotation-fetch-padrao
        [y] fetch = FetchType.LAZY
    [e] annotationColumn-inicio
        [y]     @Column(name="{{ f#[column] }}"
    [e] annotationColumn-length
        [y] , length={{ @typeParameter }}
    [e] annotationColumn-precision
        [y] , precision = {{ functx:substring-before-if-contains(@typeParameter, ',') }}
    [e] annotationColumn-fim
        [v] )
```

O template monta a anotação chamando os write-patterns na ordem correta, permitindo variações sem duplicar o padrão inteiro.

---

### 10. `functx:if-absent` — valor padrão para nós opcionais

Quando uma propriedade pode não existir no mapa, use `functx:if-absent` para fornecer um default:

```
[v]         this.{{ @name }} = {{ functx:if-absent(properties/defaultValue/value, '0.0') }};
[v]         this.{{ @name }} = {{ functx:if-absent(properties/defaultValue/value, false) }};
```

Diferente de `if/then/else`, é mais conciso quando só há um fallback.

---

### 11. Convenção de nomes em patterns

Os geradores de produção seguem um padrão consistente de nomenclatura:

| Padrão | Exemplo | Uso |
|--------|---------|-----|
| `acao-tipoAlvo` | `attributeString`, `attributeDate` | Pattern para um tipo específico de atributo |
| `contexto-start` / `contexto-close` | `class-start`, `defaultConstructor-start` | Abertura e fechamento de blocos |
| `contexto-parteMontagem` | `allArgsConstructor-paramString`, `allArgsConstructor-bodyDate` | Partes de uma estrutura composta (ex: construtor em 3 fases: params, body-start, body) |
| `annotation-alvo-posicao` | `annotation-oneToOne-inicio`, `annotation-fetch-eager` | Partes de anotações compostas |
| `import-tipo` | `import-list`, `import-date`, `import-manyToOne` | Imports condicionais por tipo |

---

### 12. Gerador com múltiplos `parameters`

Geradores de produção tipicamente recebem dois parâmetros: o nome da classe-alvo e o pacote:

```
[e] parameters
    [e] modelName
        [v] NOT_DEFINED
    [e] package
        [v] NOT_DEFINED
```

Chamada CLI:
```bash
mapperidea generate quarkus-domain \
    modelName=Pessoa \
    package=com.empresa.domain.pessoa \
    > output/Pessoa.java
```

---

### 13. Fragment `tabulaDescription` — Javadoc automático

Padrão recorrente para gerar comentários Javadoc a partir da `description` do mapa de negócios:

```
[e] fragments
    [e] tabulaDescription
        [v] for $linha in functx:lines(string-join(properties/description/value,codepoints-to-string(10))) return mi:tabulate-text(concat(normalize-space($linha),codepoints-to-string(10)),'* ',80)
```

Uso no pattern:
```
[v] /*
[v] {{ f#[tabulaDescription] }}
[v] */
[v] public class {{ @name }} {
```

Resultado: cada linha da `description` vira uma linha do Javadoc, quebrada automaticamente em 80 chars com prefixo `* `.

---
