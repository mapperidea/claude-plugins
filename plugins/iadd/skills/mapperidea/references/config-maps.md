# O bloco `config` e o mapeamento de tipos

*Referência da skill `mapperidea` — carregada sob demanda. Volte ao `SKILL.md` para o roteiro.*

## Bloco `config` — Configuração e Mapeamento de Tipos

O bloco `config` fica no nível raiz do mapa (irmão de `[p] domain`) e contém configurações globais usadas pelos geradores.

```
[p] com.example
    config
        structVersion
            2
        [e] mapperidea
            [e] maps
                [e] toSwaggerTypes
                    ...
                [e] mapNativeTypes
                    ...
                [e] qualquerOutroMap
                    ...
            [e] generators
                ...
            [e] injectables
                ...
```

### `maps` — Área Livre de Configuração Colaborativa

Esta seção define os dicionários de tradução tecnológica. Por convenção O Mapper Idea exige uma separação rígida entre o vocabulário de negócio e a plataforma técnica.

🛑 **REGRA DE OURO PARA A IA (MAPA DE NEGÓCIOS AGNÓSTICO):**

Você **NUNCA** deve utilizar tipos de dados técnicos de linguagens (ex: String, Long, int, BigDecimal, VARCHAR, LocalDateTime) dentro de um Mapa de Negócios.

O Mapa de Negócios aceita exclusivamente o Dicionário de Tipos de Negócio padrão.

### **Dicionário Estrito de Tipos de Negócio (Para uso em Mappings \[d\])**

Sempre utilize esta nomenclatura padrão ao modelar atributos de entidades:

| Tipo de Negócio | Parâmetro | Exemplo no Mapa | Descrição |
| :---- | :---- | :---- | :---- |
| Texto | Tamanho | \[d\] nome: Texto(100) | Strings com limite definido (nomes, códigos, CPFs). |
| TextoLongo | Nenhum | \[d\] observacoes: TextoLongo() | Textos extensos sem limite prático (mural, logs, blobs). |
| Inteiro | Tamanho | \[d\] contador: Inteiro(5) | Números inteiros sem casas decimais (IDs, flags numéricas). |
| Decimal | Precisão, Escala | \[d\] peso: Decimal(10,3) | Números de ponto flutuante não financeiros (medições). |
| ValorMonetario | Nenhum | \[d\] preco: ValorMonetario() | Exclusivo para valores financeiros e contábeis. |
| Boolean | Nenhum | \[d\] ativo: Boolean() | Campos lógicos de verdadeiro ou falso (flags de status). |
| Data | Nenhum | \[d\] vencimento: Data() | Armazena apenas dia, mês e ano, sem fuso ou horário. |
| DataHora | Nenhum | \[d\] criadoEm: DataHora() | Timestamp completo (data, hora, minuto, segundo). |

### **O Bloco maps como Camada de Tradução Técnica**

O bloco maps dentro de config serve como o tradutor oficial do gerador. Quando você precisar criar um gerador para um novo stack tecnológico, siga este modelo para construir a árvore de De/Para de tipos de forma limpa:

config  
    \[e\] mapperidea  
        \[e\] maps  
            \[e\] toJavaTypes       ← Nomeclatura: to \+ Stack \+ Types  
                \[e\] Texto  
                    \[v\] String  
                \[e\] ValorMonetario  
                    \[v\] BigDecimal  
                \[e\] Inteiro  
                    \[v\] Long

💡 **DIRETRIZ DE ENGENHARIA DE MAPAS:**

O bloco maps é uma área colaborativa livre. Além de traduzir tipos, use-o criativamente para padronizar propriedades repetitivas (como chaves de anotação, permissões de API ou caminhos de auditoria), eliminando a verbosidade do Mapa de Negócios.

O bloco `maps` não tem estrutura fechada. **Qualquer mapa pode ser criado** por acordo entre o Mapeador de Negócios e o Arquiteto — é uma área de criatividade que permite evitar repetição, centralizar convenções e simplificar tanto o mapa de negócios quanto os geradores.

Exemplos de usos comuns e criativos:

---

#### `toSwaggerTypes` — De/Para tipo de negócio → tipo alvo

```
[e] toSwaggerTypes
    [e] Texto
        [v] string
    [e] Inteiro
        [v] integer
    [e] Decimal
        [v] number
    [e] Boolean
        [v] boolean
    [e] Data
        [v] string
    [e] DataHora
        [v] string
    [e] ValorMonetario
        [v] number
```

Cada gerador pode ter seu próprio mapa de tipos (`toJavaTypes`, `toSqlTypes`, `toTypeScriptTypes`, etc.).

---

#### `mapNativeTypes` — Agrupamento de tipos equivalentes em famílias

Normaliza variações de um mesmo tipo para que o gerador faça match por família:

```
[e] mapNativeTypes
    [e] Date
        [v] Data
        [v] Date
        [v] date
        [v] data
    [e] DateTime
        [v] DateTime
        [v] datetime
        [v] DataHora
    [e] String
        [v] Texto
        [v] varchar
        [v] String
        [v] text
    [e] BigString
        [v] TextoLongo
        [v] longtext
```

XPath usando família: `attribute[@type = $mapNativeTypes/String/value]`
→ Captura `Texto`, `varchar`, `String` e `text` de uma vez.

---

#### `defaultProperties` — Propriedades padrão por nome de campo (exemplo criativo)

Problema: o Mapeador de Negócios precisa declarar as mesmas propriedades (`title`, `description`, `column`) toda vez que usa um campo comum como `nome` ou `cpf`. Isso é repetitivo.

Solução combinada entre Mapeador e Arquiteto:

```
[e] defaultProperties
    [e] nome
        [e] properties
            [e] title
                [v] Nome completo
            [e] description
                [v] Usar o nome que consta em documentos oficiais
            [e] column
                [v] nm_nome
    [e] cpf
        [e] properties
            [e] title
                [v] CPF
            [e] description
                [v] Número do CPF sem formatação (apenas dígitos)
            [e] column
                [v] nr_cpf
```

No gerador, ao processar um atributo, o template verifica se há `defaultProperties` para aquele campo e faz o merge:

```
[e] vars
    [e] defaultProps
        [e] select
            [v] //maps/defaultProperties

[e] templates
    [e] mode
        [v] processaAtributo
        [e] template
            [e] match
                [v] attribute[@mode='directToField']
            [e] body
                [e] write-pattern
                    [v] campoComDefault
```

```
[e] patterns
    [e] campoComDefault
        [v] {{ @name }}: {{ $defaultProps/*[name()=current()/@name]/properties/title/value }}
```

→ O Mapeador de Negócios declara apenas `[d] nome: Texto(128)` no mapa de negócios, e o gerador busca automaticamente as propriedades padrão em `defaultProperties/nome/properties/*`.

---

**Resumo:** `maps` é um contrato colaborativo. O Mapeador de Negócios e o Arquiteto definem juntos quais mapas fazem sentido para o projeto — não há lista fechada. O objetivo é sempre reduzir repetição no mapa de negócios e tornar os geradores mais inteligentes sem exigir termos técnicos do lado do negócio.

### Acessando `maps` em geradores via `vars`

Geradores mapeiam seções do `config` para variáveis locais com `vars`:

```
[e] vars
    [e] mapNativeTypes
        [e] select
            [v] //maps/mapNativeTypes
    [e] toSqlTypes
        [e] select
            [v] //maps/toSqlTypes
    [e] defaultProps
        [e] select
            [v] //maps/defaultProperties
```

Após isso, `$mapNativeTypes`, `$toSqlTypes` e `$defaultProps` ficam disponíveis como variáveis XPath em todo o gerador.

---
