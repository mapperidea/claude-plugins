# Sintaxe `.mi` — referência completa

*Referência da skill `mapperidea` — carregada sob demanda. Volte ao `SKILL.md` para o roteiro.*

## Sintaxe `.mi` — Referência Completa

### Gramática

```
ArquivoMI      ::= (Nó)+
Nó             ::= (Indentação)* (DefinicaoIcone " ")? Texto
DefinicaoIcone ::= "[" ListaDeIcones "]"
ListaDeIcones  ::= Icone ("," Icone)*
Texto          ::= TextoEmLinhaUnica | TextoEmLinhas
TextoEmLinhas  ::= [Texto L1] (QuebraDeLinha + Indentação* + " "* + "|" + [Texto LN])*
Indentação     ::= ("    " | \t)   ← 4 espaços OU 1 tab, NUNCA misturar
```

**Regra crítica:** a hierarquia pai-filho é definida exclusivamente pela indentação. 4 espaços ou 1 tab por nível. Nós sem ícone são válidos.

**Texto multi-linha:** use `|` nas linhas seguintes, alinhado abaixo do `]` do ícone:
```
[e] description
    [v] Primeira linha
      | segunda linha
      | terceira linha
```

---

### Ícones e Atalhos

Sempre prefira o atalho ao nome completo quando disponível.

| Atalho | Nome Completo | Uso |
|--------|--------------|-----|
| `b` | `Descriptor.bean` | Classe de domínio persistível (entidade DDD) |
| `c` | `Descriptor.class` | Classe auxiliar / tipo complexo não persistido |
| `g` | `Descriptor.grouping` | Agrupador visual — não afeta o DOM |
| `p` | `Package` | Pacote/namespace (letras minúsculas) |
| `d` | `Mapping.directToField` | Atributo simples (string, número, data, etc.) |
| `r` | `Mapping.oneToOne` | Referência para outra classe (equivalente a FK) |
| `o` | `Mapping.oneToMany` | Coleção Mestre→Detalhe |
| `m` | `Mapping.manyToOne` | Dependência Detalhe→Mestre |
| `h` | `Mapping.directMap` | Mapeamento direto |
| *(sem atalho)* | `Mapping.composite` | Composição forte sem referência inversa |
| `x` | `Method.public` | Método público |
| `e` | `element` | Propriedade de metadados |
| `v` | `tag_green` | Valor de uma propriedade |
| `t` | `textNode` | Nó de texto simples |
| `k` | `bullet_key` | Chave |
| `y` | `tag_yellow` | Anotação amarela |

---

### Declarando Classes

```
[b] PessoaFisica
```
→ DOM: `<class name="PessoaFisica" mode="bean"/>`

Com pacote (hierarquia de `[p]` define o `package`):
```
[p] domain
    [p] pessoa
        [b] PessoaFisica
```
→ DOM: `<class name="PessoaFisica" mode="bean" package="domain.pessoa"/>`

---

### Declarando Atributos

Padrão: `[ícone] nomeAtributo: Tipo(parametros)`

**Atributo simples (`[d]` — Mapping.directToField):**

O tipo é definido pelo mapeador de negócios em linguagem de negócio. Exemplos de tipos comuns:

| Tipo | Parâmetro | Exemplo |
|------|-----------|---------|
| `Texto` | tamanho | `[d] nome: Texto(100)` |
| `TextoLongo` | — | `[d] observacoes: TextoLongo()` |
| `Inteiro` | tamanho | `[d] cpf: Inteiro(11)` |
| `Decimal` | precisão,escala | `[d] quantidade: Decimal(15,3)` |
| `ValorMonetario` | — ou x,y | `[d] valorTotal: ValorMonetario()` |
| `Boolean` | — | `[d] ativo: Boolean()` |
| `Data` | — | `[d] dataNascimento: Data()` |
| `DataHora` | — | `[d] dataCadastro: DataHora()` |

> O mapeador de negócios pode criar tipos próprios — eles serão mapeados nos geradores via `config/toSwaggerTypes`, `config/mapNativeTypes` etc. Não há lista fechada de tipos.

**Referência para outra classe (`[r]`):**
```
[r] naturalidade: Cidade()
```
→ DOM: `<attribute name="naturalidade" mode="oneToOne" type="Cidade" typeParameter=""/>`

**Coleção Mestre/Detalhe (`[o]` e `[m]`):**
```
[b] PessoaFisica
    [o] enderecos: Endereco()       ← Mestre aponta para Detalhe
[b] Endereco
    [m] pessoaFisica: PessoaFisica() ← Detalhe referencia o Mestre
```
Ao deletar o Mestre, todos os Detalhes são removidos junto.

**Composição (`[Mapping.composite]`):**
```
[Mapping.composite] cnh: CarteiraNacionalHabilitacao()
```
Dependência forte — o Detalhe é criado e destruído com o Mestre, mas não sabe quem o possui.

---

### Metadados com Propriedades (`@`)

Adicione um nó `@` como filho direto do atributo/classe. Dois modos:

**Modo 1 — estrutura explícita com ícones:**
```
[d] nome: Texto(128)
    @
        [e] description
            [v] Nome completo da pessoa
            [v] Usar o nome que consta em documentos oficiais
        [e] required
            [v] true
```
XPath: `properties/description/value` | `properties/required/value`

**Modo 2 — chave-valor compacto:**
```
[d] nome: Texto(128)
    @
        description: Nome completo da pessoa
        required: true
```
XPath: `properties/property[@name='description']/@value`

---

### Agrupadores Visuais

`[g]` organiza visualmente sem impactar o DOM:
```
[b] PessoaFisica
    [g] atributos
        [d] nome: Texto(128)
        [d] cpf: Inteiro(11)
    [g] métodos
        [x] calculaIdade: Inteiro(2)
```

---

### Métodos e Lógica

#### Declaração de método

O ícone `[x]` declara um método público. A assinatura define apenas o nome e o tipo de retorno — os parâmetros ficam num bloco `parameter` filho:

```
[x] nomeMetodo: TipoRetorno()
    parameter
        nomeParam1: Tipo1()
        nomeParam2: Tipo2()
    body
        ...
```

- O tipo de retorno usa a mesma sintaxe `Tipo()` dos atributos
- `parameter` (sem `s`) é o bloco de declaração de parâmetros — cada filho segue o padrão `nome: Tipo()`
- `body` contém a lógica do método

**Parâmetro com metadados (`@`):**
```
[x] getCalendarioMensal: CalendarioMensal()
    parameter
        em: EntityManager()
        request: HttpServletRequest()
            @
                [e] varargs
    body
        ...
```
O `@` funciona como em atributos — pode anotar um parâmetro com propriedades como `varargs`.

**Método sem parâmetros:**
```
[x] calculaIdade: Inteiro()
    body
        ...
```

---

#### Variáveis locais (`var`)

O bloco `var` declara uma ou mais variáveis de escopo local, todas como filhos diretos:

```
var
    calendarioMensalList: List<CalendarioMensal>
    calendarioMensal: CalendarioMensal()
    anoMes: Integer()
```

Múltiplas variáveis podem ser declaradas no mesmo bloco `var`. O tipo segue a mesma sintaxe de atributos, incluindo genéricos como `List<Tipo>`.

---

#### Atribuição e Cálculos: Protocolo de Decomposição (AST)

A pseudo-linguagem do Mapper Idea não utiliza notação linear (infixa) nem parênteses para cálculos. Ela utiliza uma **Árvore de Operadores** (notação prefixa estruturada via indentação).

> 🧠 **RECEITA COGNITIVA PARA A IA (PENSE ANTES DE GERAR):**
> Sempre que precisar escrever uma atribuição ou cálculo matemático/lógico, execute mentalmente estes 4 passos antes de escrever o código `.mi`:
> 
> 1. **Identifique o Alvo:** Quem vai receber o valor final? Escreva esta variável/atributo isolada na linha raiz.
> 2. **Abra a Atribuição:** Indente exatamente um nível abaixo (4 espaços) do Alvo e coloque o operador `=` isolado.
> 3. **Ache a Operação Externa (Raiz do Cálculo):** Olhe para a fórmula tradicional e identifique qual é a **última** operação que seria executada (aquela que engloba as outras e fica fora dos parênteses). Coloque esse operador isolado, indentado um nível abaixo do `=`.
> 4. **Decomponha de Fora para Dentro:** Escreva os operandos (termos) indentados abaixo do operador. A ordem das linhas determina os lados (1ª linha filha = esquerda, 2ª linha filha = direita). Se um operando for outro cálculo, o operador dele vira nó pai e seus respectivos sub-elementos ficam abaixo dele.

**Exemplo Prático - Decompondo a fórmula:** `precoFinal = (quantidade * valorUnitario - desconto) * 1.05`

```mi
self.precoFinal
    =
        *
            -
                *
                    self.quantidade
                    self.valorUnitario
                self.desconto
            1.05

```

> ❌ **GUARDRAILS ABSOLUTOS DE ATRIBUIÇÃO E OPERADORES:**
> * **NUNCA** coloque o operador `=` na mesma linha ou no mesmo nível de indentação (irmão) da variável alvo. Ele é sempre **filho**. (Ex: `anoMes =` é estritamente proibido).
> * **NUNCA** escreva operadores de forma linear no meio das variáveis (Ex: `self.qtd * self.valor`). Isso causará erro crítico na Máquina de Inferência.
> * Para atributos da própria classe no Mapa de Negócios, sempre use o prefixo `self.`.
> 
> 

**Tabela de Operadores (Sempre atuam como "pais" de seus operandos):**

| Operador | Significado |
| --- | --- |
| `=` | Atribuição (quando filho de variável) ou igualdade (quando filho de `condition`) |
| `!=` | Diferente de |
| `>` / `<` / `>=` / `<=` | Comparações |
| `+` / `-` / `*` / `/` | Aritméticos |

**Exemplo - Condicional e Comparação (O operador de comparação também é o pai):**

```mi
if
    condition
        !=
            calendarioMensalList
            null
    then
        ...

```

---
#### **Chamadas de Função e Parâmetros Indentados**

A gramática do Mapper Idea define a hierarquia visual e de dados exclusivamente por meio de recuos (indentação). Funções agem estritamente como nós "pais", e seus argumentos devem ser mapeados como nós "filhos".

🛑 **REGRA DE OURO PARA CHAMADAS DE FUNÇÃO (IA):**

Em blocos de lógica ou serviços de domínio (pre, do, emit), chamadas de função ou disparos de eventos DEVEM usar parênteses vazios () na linha do nome. Cada argumento/parâmetro DEVE ser escrito em uma nova linha própria, indentada um nível abaixo (4 espaços).

* **Sintaxe de Parâmetros Simples:** Referências diretas a variáveis ou atributos locais ficam sozinhas em sua linha filha.  
* **Sintaxe de Parâmetros com Atribuição:** Caso o argumento precise passar um valor estático, tipo ou flag de enum vinculada, utilize a estrutura : valor na mesma linha do parâmetro.

**Exemplo Correto (Estrutura em Árvore de Parâmetros):**

```
emit  
    PedidoConfirmado()  
        idPedido  
        idAtor  
        timestampAtivacao  
        canalOrigem: EM_CHECKOUT  
    EmailConfirmacaoEnviado()  
        destinatarios: cliente
```

❌ **CRITICAL GUARDRAIL (PROIBIÇÃO DE ARGUMENTOS INLINE):**

* **NUNCA** liste argumentos separados por vírgula dentro dos parênteses de uma função (Ex: PedidoConfirmado(idPedido, idAtor) é um erro grave).

*Justificativa Técnica:* Parâmetros inline transformam a chamada em uma string de texto contínua e indivisível na memória. Ao usar parâmetros indentados, cada argumento vira um nó XML filho independente no DOM, tornando-se navegável por XPath para os geradores de código.

#### Funções e encadeamento

**Chamada de função:** a função é o nó pai; seus argumentos são filhos em ordem:

```
parseInt()
    FuncoesTempo
        .
            hoje()
                .
                    format()
                        "yyyyMM"
```
→ `parseInt(FuncoesTempo.hoje().format("yyyyMM"))`

**Encadeamento com `.`:** o operador `.` é filho do objeto/classe, e o método chamado é filho do `.`. Cada nível de encadeamento fica um nível mais profundo:

```
FuncoesTempo          ← objeto/classe raiz
    .                 ← operador de acesso
        hoje()        ← método chamado em FuncoesTempo
            .         ← novo encadeamento
                format()       ← método chamado no retorno de hoje()
                    "yyyyMM"   ← argumento de format()
```

A ordem dos filhos define a ordem dos argumentos:
```
FuncoesTempo.diferencaAnos()
    self.dataNascimento    ← 1º argumento
    DataHoje()             ← 2º argumento
```

---

#### Estruturas de controle

**Condicional `if/then/else`:**
```
if
    condition
        !=
            calendarioMensalList
            null
    then
        calendarioMensal
            =
                calendarioMensalList.get(0);
    else
        return
            -1
```
- `condition` → expressão lógica avaliada (filhos são os operandos/operadores)
- `then` → bloco executado se a condição for verdadeira
- `else` → bloco opcional executado se falsa

**Laço `for-each`:**
```
for-each
    roda in self.rodas
    do
        roda.validaPressao()
```
- `roda in self.rodas` → variável de iteração e coleção
- `do` → corpo do laço
- `break()` dentro do `do` interrompe o laço

---

#### `find` — busca em coleção

Instrução para consultas a repositórios ou coleções. Os critérios são pares `=` com campo e valor como filhos:

```
calendarioMensalList
    =
        find
            =
                "anoMes"
                anoMes
```
→ Busca registros onde o campo `"anoMes"` é igual à variável `anoMes`, atribuindo o resultado a `calendarioMensalList`.

Múltiplos critérios:
```
resultList
    =
        find
            =
                "status"
                "ATIVO"
            =
                "tipo"
                tipoParam
```

---

#### `return`

O valor retornado é filho de `return`:
```
return calendarioMensal
return
    FuncoesTempo.diferencaAnos()
        self.dataNascimento
        DataHoje()
return -1
```

---

#### Comentários

Comentários são nós estruturais e independentes na árvore do DOM. Eles possuem regras rígidas de isolamento.


**GUARDRAIL CRÍTICO (PROIBIÇÃO ABSOLUTA):**
**NUNCA** escreva texto na mesma linha que o caractere `//`. O símbolo `//` deve ficar totalmente isolado em sua linha.
**NUNCA** faça comentários inline ao lado de atributos, métodos ou comandos (ex: `[d] nome: Texto(10) // Incorreto`).
O texto explicativo **DEVE** ser um nó filho, indentado obrigatoriamente um nível abaixo (4 espaços) do `//`.
Para múltiplas linhas de comentário, **NÃO** repita o símbolo `//`. Mantenha as linhas subsequentes como filhas do mesmo bloco, alinhadas no mesmo recuo.

*Justificativa Técnica:* Texto na mesma linha do `//` corrompe o parser da Máquina de Inferência, interpretando o comentário como um identificador de lógica inválido.

**Exemplo Correto (Estrutura de Bloco Único):**
```mi
//
    Declara variáveis para o processamento.
    Este texto é filho e pode ter múltiplas linhas,
    desde que mantenha este mesmo alinhamento.
var
    resultado: Integer()

//
    Verifica se o valor é válido antes de calcular
if
    condition
        ...
```

---

#### Exemplo completo de método

```
[x] getCalendarioMensal: CalendarioMensal()
    parameter
        em: EntityManager()
        request: HttpServletRequest()
            @
                [e] varargs
    body
        var
            calendarioMensalList: List<CalendarioMensal>
            calendarioMensal: CalendarioMensal()
            anoMes: Integer()
        anoMes
            =
                parseInt()
                    FuncoesTempo
                        .
                            hoje()
                                .
                                    format()
                                        "yyyyMM"
        calendarioMensalList
            =
                find
                    =
                        "anoMes"
                        anoMes
        if
            condition
                !=
                    calendarioMensalList
                    null
            then
                calendarioMensal
                    =
                        calendarioMensalList.get(0);
        return calendarioMensal
```

---
