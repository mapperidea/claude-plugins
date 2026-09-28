# Funções disponíveis nos patterns

*Referência da skill `mapperidea` — carregada sob demanda. Volte ao `SKILL.md` para o roteiro.*

## Funções Disponíveis nos Patterns

Documentação completa: https://docs.mapperidea.io/ref-guide/en/

### Funções `mi:` — Exclusivas do Mapper Idea

| Função | Assinatura | Descrição | Exemplo |
|--------|-----------|-----------|---------|
| `mi:first-upper` | `(s: string) → string` | Primeira letra maiúscula | `mi:first-upper('hello')` → `Hello` |
| `mi:first-lower` | `(s: string) → string` | Primeira letra minúscula | `mi:first-lower('QUERY')` → `qUERY` |
| `mi:lower-case-add-underline` | `(s: string, last: string) → string` | camelCase → snake_case | `mi:lower-case-add-underline('PessoaFisica','')` → `pessoa_fisica` |
| `mi:lower-case-add-hifen` | `(s: string, last: string) → string` | camelCase → kebab-case | `mi:lower-case-add-hifen('PessoaFisica','')` → `pessoa-fisica` |
| `mi:concat-change-pattern` | `(s: string, token: string, between: string, last: string)` | Quebra por regex e recombina com separadores | `mi:concat-change-pattern('CompanyGroup','([A-Z])','_$1','_id')` → `Company_Group_id` |
| `mi:if-else` | `(test: boolean, then: string, else: string) → string` | Condicional inline | `mi:if-else(position() = last(), '', ',')` |
| `mi:replicate` | `(s: string, count: integer) → string` | Repete string N vezes | `mi:replicate('A', 3)` → `AAA` |
| `mi:tabulate-text` | `(text: string, tabText: string, lineSize: integer)` | Formata texto com indentação e quebra de linha automática | Para Javadoc e comentários |

### Funções XPath Padrão — Mais Usadas em Geradores

**Strings:**
- `upper-case(s)` / `lower-case(s)` — maiúsculas/minúsculas
- `substring-before(s, sep)` / `substring-after(s, sep)` — antes/depois de separador
- `substring(s, start)` / `substring(s, start, length)` — recorte por posição
- `concat(s1, s2, ...)` / `string-join((s1,s2), sep)` — concatenação
- `contains(s, sub)` / `starts-with(s, sub)` / `ends-with(s, sub)` — testes
- `replace(s, pattern, replacement)` — substituição por regex
- `translate(s, from, to)` — substituição char a char
- `normalize-space(s)` — remove espaços extras
- `string-length(s)` — tamanho da string
- `codepoints-to-string(n)` — char por codepoint Unicode (ex: `10` = newline)

**Sequências/Posição:**
- `position()` — posição atual no loop (1-based)
- `last()` — total de itens no contexto atual
- `count(seq)` — conta elementos
- `exists(seq)` / `empty(seq)` — testa se sequência tem elementos
- `index-of(seq, value)` — posição de um valor na sequência
- `reverse(seq)` — inverte ordem
- `subsequence(seq, start, length?)` — recorte de sequência

**Números:**
- `abs(n)` / `round(n)` / `ceiling(n)` / `floor(n)` — operações numéricas
- `sum(seq)` / `avg(seq)` / `max(seq)` / `min(seq)` — agregações
- `number(s)` — converte para número

**Booleanos:**
- `not(expr)` — negação
- `boolean(expr)` — converte para booleano
- `true()` / `false()` — constantes booleanas

**Data/Hora:**
- `current-date()` / `current-dateTime()` / `current-time()` — valores atuais
- `year-from-date(d)` / `month-from-date(d)` / `day-from-date(d)` — extração
- `hours-from-dateTime(dt)` / `minutes-from-dateTime(dt)` / `seconds-from-dateTime(dt)` — tempo

### Funções `functx:` — Biblioteca FunctX

**Strings:**
- `functx:lines(s)` — divide texto em sequência de linhas (essencial com `mi:tabulate-text`)
- `functx:camel-case-to-words(s, sep)` — camelCase para palavras separadas
- `functx:words-to-camel-case(s)` — palavras para camelCase
- `functx:capitalize-first(s)` — primeira letra maiúscula
- `functx:format-as-title-en(s)` — formata como título inglês
- `functx:reverse-string(s)` — inverte string
- `functx:replace-first(s, pattern, replacement)` — substitui apenas primeira ocorrência
- `functx:replace-multi(s, patterns, replacements)` — múltiplas substituições
- `functx:escape-for-regex(s)` — escapa caracteres especiais de regex
- `functx:substring-before-last(s, delim)` / `functx:substring-after-last(s, delim)` — antes/após última ocorrência
- `functx:contains-word(s, word)` — contém palavra completa
- `functx:word-count(s)` — conta palavras
- `functx:line-count(s)` — conta linhas

**Sequências:**
- `functx:value-union(seq1, seq2)` — união por valor
- `functx:value-intersect(seq1, seq2)` — interseção por valor
- `functx:value-except(seq1, seq2)` — diferença por valor
- `functx:index-of-node(seq, node)` — posição de nó na sequência

**Números:**
- `functx:pad-integer-to-length(n, len)` — preenche com zeros à esquerda
- `functx:ordinal-number-en(n)` — ordinal em inglês (1st, 2nd...)
- `functx:is-a-number(s)` — testa se string representa número

**Data:**
- `functx:add-months(date, n)` — adiciona meses a uma data
- `functx:days-in-month(date)` — dias no mês
- `functx:is-leap-year(year)` — é ano bissexto?
- `functx:total-days-from-duration(dur)` / `functx:total-seconds-from-duration(dur)` — duração total

---
