> ## Como usar este template
>
> Este é o **guia de modelagem de domínio com DDD e Mapper Idea**, extraído de um projeto real em
> 17/09/2026. Ele é **semente**: copie para o seu projeto e edite.
>
> Os exemplos usam um **domínio de ensino** — uma loja: `Cliente`, `Fornecedor`, `Pedido`, `ItemPedido`,
> `Comprador` — o mesmo do [pack `_exemplar`](../packs/_exemplar/), para que o kit inteiro ensine sobre um
> domínio só. Substituí-los pelos seus é o seu trabalho de adoção, e é trabalho útil: modelar os **seus**
> bounded contexts enquanto lê é exatamente o exercício que o guia propõe.
>
> | Seção | Natureza | O que fazer |
> |---|---|---|
> | 1–3 (visão, pré-requisitos, as cinco fases) | **método puro** | mantenha |
> | 4 (Linguagem Ubíqua) | método + glossário de origem | mantenha o processo, troque o glossário |
> | 5 (Hierarquia e regras estruturais) | **método puro** | mantenha |
> | 6 (Modelagem por Bounded Context) | **exemplo longo** no domínio de ensino | é o maior bloco a
>   substituir: refaça com os seus contextos, na ordem de dependência deles |
> | 7–8 (Revisão, Documentação para aprovação) | **método puro** | mantenha |
> | 9 (Princípios de design) | método + exemplos de regra de negócio | mantenha os princípios
>   estruturais; troque os que são regra de negócio (isolamento por tenant, retenção, auditoria) |
> | 10 (Ícones) | **referência da ferramenta** | mantenha |
> | 11 (Checklist por entidade) | **método puro** | mantenha — ajuste só os campos de controle |
> | 12–13 (Estrutura de arquivos, o que vem depois) | fiação | reescreva com os seus caminhos |
>
> **O critério de relenvio da seção 9.1** é a peça mais transferível do documento inteiro, e a que
> mais evita retrabalho: se deletar A implica deletar B **e** os dois estão no mesmo bounded context, use
> `[m]`/`[o]`; caso contrário, `[r]`. Cross-context é **sempre** `[r]`.
>
> Para não inventar domínio ao preencher, use o `knowledge-extractor` do `agent-kit` apontado para os seus
> documentos de negócio.

---

# Guia de Modelagem de Domínio com DDD e Mapper Idea

**Versão:** 1.0
**Contexto:** Estratégia desenvolvida e validada no projeto Loja
**Objetivo:** Documento de referência para replicar este processo em novos projetos

---

## 1. Visão Geral

Este guia descreve o processo de modelagem de domínio que combina os princípios de **Domain-Driven Design (DDD)** com a metodologia **Mapper Idea** como ferramenta de captura e centralização do conhecimento.

O resultado esperado ao final deste processo é:

- Um modelo de domínio rico, revisado e aprovado pelo time
- Uma linguagem ubíqua estabelecida e documentada
- Bounded Contexts com responsabilidades claras e dependências explícitas
- Decisões arquiteturais registradas com justificativa
- Documentação em português e inglês pronta para circulação

O processo é iterativo por natureza — cada fase alimenta a próxima, e revisões são esperadas e bem-vindas.

---

## 2. Pré-requisitos

Antes de iniciar a modelagem, garanta que os seguintes elementos estejam disponíveis:

**Contexto de negócio:**
- Descrição do problema que o sistema resolve
- Quem são os atores principais (quem usa, quem é impactado)
- Qual o domínio principal (financeiro, saúde, logística etc.)
- Requisitos legais ou regulatórios relevantes (LGPD, GDPR, regulamentações setoriais)

**Estrutura do projeto:**
- Repositório criado com pasta `mi/` para os mapas e `docs/` para documentação
- CLI do Mapper Idea instalada e projeto inicializado (`mapperidea init`)
- `CLAUDE.md` criado na raiz com visão geral do projeto, convenções e glossário inicial

**Time:**
- Ao menos um representante de negócio capaz de validar a linguagem do domínio
- Clareza sobre quem tem autoridade para aprovar o modelo antes de avançar para implementação

---

## 3. As Cinco Fases do Processo

```
Fase 1: Linguagem Ubíqua
      ↓
Fase 2: Hierarquia e Regras Estruturais
      ↓
Fase 3: Modelagem por Bounded Context
      ↓
Fase 4: Revisão Geral do Modelo
      ↓
Fase 5: Documentação para Aprovação
```

---

## 4. Fase 1 — Linguagem Ubíqua

### Objetivo
Estabelecer um vocabulário comum entre negócio e tecnologia antes de qualquer código ou mapa. Ambiguidade de linguagem é a principal causa de retrabalho em projetos de software.

### Como fazer

**1. Liste todos os termos do domínio**
Pergunte ao negócio: "Quais são as coisas que existem neste sistema?" Não pense em tabelas ou classes — pense em conceitos de negócio. Exemplos: "O que é um Fornecedor? O que é um Acordo? O que é uma Quitação?"

**2. Para cada termo, defina:**
- O nome técnico em português (usado no código e nos mapas)
- O nome de negócio coloquial (termo usado em conversas e interfaces, quando diferente do técnico)
- Uma definição precisa em uma frase

**3. Identifique ambiguidades e sinônimos**
É comum o mesmo conceito ter nomes diferentes dependendo de quem fala. Escolha um único termo canônico e documente os sinônimos como aliases — não como termos alternativos válidos.

Exemplo da Loja:
> "Comprador" é o termo técnico. "Cliente" é o termo usado na notificação do usuário. O modelo usa "Comprador" no código e reconhece "Cliente" como alias contextual — mas nunca mistura os dois no mesmo contexto.

**4. Registre em `docs/`**
Crie um arquivo de glossário (ex: `padronizacaoTermos.md`) com a tabela completa. Este documento é vivo — atualiza-o ao longo do projeto sempre que um novo termo emergir.

### Entregável
Tabela de linguagem ubíqua com: termo técnico (PT), nome de negócio coloquial (quando diferente), definição clara.

### Sinal de que está pronto
Qualquer membro do time consegue ler um nome de entidade no modelo e saber imediatamente o que ela representa no negócio — sem precisar perguntar.

---

## 5. Fase 2 — Hierarquia e Regras Estruturais

### Objetivo
Definir a espinha dorsal do sistema: quem é o tenant raiz, como os dados se organizam hierarquicamente e quais regras estruturais nunca podem ser violadas.

### Como fazer

**1. Identifique o modelo de multi-tenancy (se aplicável)**
Pergunte: "Quem opera o sistema? Para quem? Com que nível de isolamento de dados?"

Mapeie a hierarquia de cima para baixo:
```
Quem opera → Quem é cliente → Quem é impactado
```

No Loja:
```
Cliente (opera) → Fornecedor (cliente) → Comprador (impactado)
```

**2. Identifique as regras de isolamento**
Regras que definem quais dados podem ser compartilhados e quais são estritamente isolados. No Loja, a regra LGPD determina que dados de Comprador são isolados por Fornecedor — nenhum Fornecedor acessa dados de outro.

Documente essas regras como invariantes — elas nunca devem ser quebradas, independentemente de conveniência técnica.

**3. Defina a estrutura de pacotes do mapa principal**
Com a hierarquia clara, defina a estrutura de `main.mi`:

```
[p] dominio.empresa          ← namespace da empresa (ex: ai.loja)
    config
    [p] domain               ← todo o modelo de negócio fica aqui
        [p] contexto1
        [p] contexto2
        ...
    [p] window               ← telas (quando necessário, fase futura)
```

O pacote `domain` dentro do namespace da empresa é o padrão adotado porque permite adicionar outros tipos de mapa (telas, fluxos, integrações) sem misturar com o modelo de negócio.

### Entregável
- Diagrama ou descrição textual da hierarquia de tenancy
- Lista de invariantes estruturais do domínio
- Estrutura de pacotes definida em `main.mi`

### Sinal de que está pronto
É possível responder claramente: "Se eu deletar X, o que acontece com Y?" para qualquer par de entidades da hierarquia principal.

---

## 6. Fase 3 — Modelagem por Bounded Context

### Objetivo
Modelar cada domínio de responsabilidade de forma isolada, com suas entidades, atributos, relenvios e regras de negócio.

### O que é um Bounded Context
Um Bounded Context é uma fronteira dentro da qual um modelo de domínio é definido e aplicável. Dentro desta fronteira, os termos da linguagem ubíqua têm significado preciso e consistente. Fora dela, o mesmo termo pode ter outro significado.

### Sequência de modelagem

**Para cada Bounded Context, siga esta ordem:**

#### Etapa 1 — Discussão antes do modelo
Antes de escrever qualquer `.mi`, discuta:
- Qual é a responsabilidade única deste contexto?
- Quais entidades vivem aqui?
- Quais são as regras de negócio não óbvias?
- Quais são as dependências com outros contextos?
- Existem requisitos legais ou técnicos que impactam o modelo?

Esta discussão evita retrabalho e revela decisões que precisam ser registradas.

#### Etapa 2 — Modele a entidade principal
Comece pela entidade mais central do contexto. Defina:
- Atributos de identificação (o que a torna única)
- Atributos de valor (o que ela carrega de informação de negócio)
- Atributos de controle (ativo, dataCriacao — padrão em todas as entidades)
- Status e seu ciclo de vida (se aplicável)

#### Etapa 3 — Modele as entidades dependentes
Entidades que só existem no contexto de outra. Defina os relenvios usando os ícones corretos (ver seção 8).

#### Etapa 4 — Adicione os relenvios com outros contextos
Use referências simples (`[r]`) para apontar para entidades de outros contextos. Nunca use mestre/detalhe (`[o]`/`[m]`) para relenvios cross-context.

#### Etapa 5 — Escreva os metadados completos
Todo campo precisa de `title` e `description` em `pt` e `en`. Não deixe para depois — metadados incompletos significam modelo incompleto.

#### Etapa 6 — Registre no `main.mi`
Adicione a entidade ao pacote correto em `main.mi` com a referência `#` para o arquivo.

**Estrutura obrigatória:** dentro de um `[p]`, cada entidade deve ser declarada como um elemento filho `[b]` com o nome da entidade em PascalCase, e a referência `#` ao arquivo `.mi` deve ser filha desse `[b]` — nunca filha direta do pacote.

```
// CORRETO
[p] cadastro
    [b] Cliente
        #
            cadastro/Cliente.mi
    [b] Contrato
        #
            cadastro/Contrato.mi

// ERRADO — # solto como filho direto do pacote
[p] cadastro
    #
        cadastro/Cliente.mi
    #
        cadastro/Contrato.mi
```

Esta estrutura é necessária porque o motor do Mapper Idea usa o elemento `[b]` como âncora para compor o DOM da entidade a partir do arquivo externo. Sem o `[b]` intermediário, a referência é interpretada como inclusão genérica de conteúdo, e a entidade não é registrada corretamente no grafo de classes do pacote.

### Ordem sugerida de modelagem

Modele os contextos da raiz para as folhas — do mais independente para o mais dependente:

```
1. Cadastro (raiz — sem dependências)
2. Pedidos (depende de Cadastro)
3. Configuração Técnica (depende de Cadastro)
4. Template de Notificacao (depende de Cadastro)
5. Notificacao (depende de Pedidos e Template de Notificacao)
6. Envio (depende de Template de Notificacao, Configuração Técnica, Pedidos)
7. Importação de Pedidos (depende de Cadastro e Pedidos)
```

Esta ordem garante que ao modelar um contexto, as entidades que ele referencia já existem.

### Convenções obrigatórias no arquivo `.mi`

**Estrutura padrão de uma entidade:**
```
[b] NomeDaEntidade
    @
        [e] title
            [e] pt
                [v] Nome em Português
            [e] en
                [v] Name in English
        [e] description
            [e] pt
                [v] Descrição em português do que esta entidade representa
            [e] en
                [v] Description in English of what this entity represents
    [g] grupo-de-atributos
        [d] nomeAtributo: Tipo(parametro)
            @
                [e] title
                    [e] pt
                        [v] Título PT
                    [e] en
                        [v] Title EN
                [e] description
                    [e] pt
                        [v] O que este campo significa no negócio
                    [e] en
                        [v] What this field means in the business
    [g] controle
        [d] ativo: Boolean()
            ...
        [d] dataCriacao: DataHora()
            ...
    [g] relenvios
        [m] entidadeMestre: EntidadeMestre()   ← quando é detalhe de outra entidade do mesmo contexto
        [r] referencia: OutraEntidade()         ← quando é referência cross-context
        [o] detalhes: EntidadeDetalhe()         ← quando possui detalhes do mesmo contexto
```

**Grupos recomendados por tipo de informação:**
- `identificação` — campos que identificam o registro (nome, código, documento)
- `valores` — campos numéricos e monetários
- `datas` — campos de data e hora relevantes ao negócio
- `status` — campo de status com enum documentado na description
- `controle` — `ativo` e `dataCriacao` (padrão em todas as entidades)
- `relenvios` — sempre o último grupo

### Convenções de nomenclatura (CN)

#### CN-REL-001 — Campos de relenvio não usam prefixo `id`

Campos declarados com ícone de relenvio (`[r]`, `[o]`, `[m]`) representam **referências a objetos** — não identificadores brutos. O nome deve refletir o conceito de negócio do objeto referenciado, sem o prefixo `id`.

**Correto:**
```
[r] fornecedorRaiz: Fornecedor()      ← referência de objeto; acesso: pedido.getFornecedorRaiz()
[o] contrato: Contrato()          ← coleção/detalhe; acesso: pedido.getContrato()
[m] cliente: Cliente()                ← mestre; acesso: contrato.getCliente()
```

**Incorreto:**
```
[r] idFornecedorRaiz: Fornecedor()        ← prefixo id em campo de objeto — viola CN-REL-001
[o] idContrato: Contrato()        ← idem
[m] idPedido: Cliente()  ← idem
```

**Razão:** em modelo de objetos, o nome do campo é usado para navegação (`objeto.getFornecedorRaiz()`). O prefixo `id` implica que o campo guarda um identificador escalar — o que é tecnicamente errado e cria confusão semântica. O mapeamento para coluna `id_fornecedor_raiz` no banco de dados é responsabilidade do gerador, não do mapa de negócios.

#### CN-REL-002 — Campos que guardam apenas o identificador bruto usam prefixo `id`

Quando o campo guarda exclusivamente o UUID de referência indireta (sem carregar o objeto), declare-o como `[d]` com prefixo `id`:

```
[d] idFornecedorRaiz: Texto(36)       ← UUID bruto; sem carga de objeto; prefixo id correto
```

Use este padrão apenas quando há razão explícita para não usar um relenvio de objeto — por exemplo, em snapshots de auditoria, integrações externas ou referências cross-context onde o objeto não deve ser carregado automaticamente.

#### CN-003 — Todo atributo deve ter `[e] cn` no `@` com o nome canônico snake_case do glossário

Todo atributo (`[d]`, `[r]`, `[m]`, `[o]`) deve declarar um elemento `[e] cn` dentro do seu bloco `@`, contendo o nome canônico em snake_case conforme o glossário do projeto (`docs/pm/glossario.md`). Este elemento é o contrato entre o mapa de negócio e os geradores: garante que nomes de atributos camelCase no modelo sejam mapeados de forma previsível para colunas, campos de API e payloads.

**Regras de formação do cn:**

| Tipo de atributo | Regra de cn | Exemplo |
|---|---|---|
| `[d]` (atributo simples) | snake_case direto do nome canônico | `dataCriacao` → `data_criacao` |
| `[r]` (referência FK sem carga de objeto) | snake_case direto | `fornecedorRaiz` → `fornecedor_raiz` |
| `[m]` (detalhe→mestre, carrega FK) | prefixo `id_` + snake_case do tipo | `cliente: Cliente()` → `id_cliente` |
| `[o]` (mestre→detalhe, sem FK no mestre) | snake_case do nome da relação (sem prefixo `id_`) | `contratos: Contrato()` → `contratos` |

O `[e] cn` deve ser o **primeiro elemento** dentro do `@`, antes de `title` e `description`.

**Exemplo correto:**

```
[d] dataAssinatura: Data()
    @
        [e] cn
            [v] data_assinatura
        [e] title
            [e] pt
                [v] Data de Assinatura
            [e] en
                [v] Signing Date
        [e] description
            [e] pt
                [v] Data em que o Cliente assinou o documento contratual.
            [e] en
                [v] Date on which the Cliente signed the contract document.

[m] cliente: Cliente()
    @
        [e] cn
            [v] id_cliente
        [e] title
            [e] pt
                [v] Cliente
            [e] en
                [v] Client Organization
```

**Por que `id_[entidade]` para `[m]` e não para `[o]`:** o lado `[m]` (detalhe) é quem armazena a chave estrangeira fisicamente no banco — portanto o cn reflete o nome da coluna FK (`id_cliente`). O lado `[o]` (mestre) não armazena FK; o cn reflete apenas o nome da navegação.

### Matriz de Decisão de Ícones de Relenvio (Uso de DDD)

Para garantir o isolamento dos Bounded Contexts e a integridade dos Agregados (Aggregate Roots), a escolha dos ícones de relenvio (`[r]`, `[o]`, `[m]`) deve seguir estritamente as regras abaixo, ignorando a pressuposição de mapeamento ORM tradicional.

> 📊 **FLUXO DE DECISÃO TÁTICA PARA A IA:**
> Quando encontrar um relenvio entre a Entidade A e a Entidade B, avalie:
> 
> 1. **As entidades pertencem a Bounded Contexts (pacotes) diferentes?**
>    * **SIM:** Use obrigatoriamente **`[r]` (referência simples)** no lado que aponta. Nunca use `[o]` ou `[m]` para relações cross-context.
> 
> 2. **As entidades estão no MESMO Bounded Context, mas se a Entidade A for excluída, a Entidade B deve continuar existindo no sistema?**
>    * **SIM:** Use **`[r]` (referência simples)**. Elas possuem ciclos de vida independentes.
> 
> 3. **As entidades estão no MESMO Bounded Context e a Entidade B SÓ EXISTE se a Entidade A existir (Dependência estrita de Mestre/Detalhe)?**
>    * **SIM:** Use **`[o]` na Entidade A** (apontando para a coleção) e **`[m]` na Entidade B** (apontando de volta para a dona do ciclo de vida).

#### Tabela de Correspondência Conceitual:

| Cenário de Negócio | Ícone Correto | Comportamento Arquitetural Gerado |
|---|---|---|
| Referência entre contextos diferentes (Cross-Context) | `[r]` | Chave estrangeira conceitual (Fk), sem carregamento automático pesado ou cascade indesejado. |
| Entidade independente no mesmo contexto | `[r]` | Associação simples de objetos. Ciclos de vida isolados. |
| Coleção dependente (Fronteira do mesmo Agregado) | `[o]` (Mestre) / `[m]` (Detalhe) | Relação Mestre/Detalhe legítima. Ativa deleção em cascata (Cascade Delete) no banco e na memória. |

#### Exemplo Prático de Modelagem Errada vs. Certa para a IA:

* **Cenário:** O contexto de `Cadastro` possui a entidade `Cliente`. O contexto de `Pedidos` possui a entidade `Comprador`.
* **Abordagem Incorreta (Visão ORM linear):** Colocar `[o] compradores: Comprador()` dentro de `Cliente` (Mistura contextos e gera cascade indesejado).
* **Abordagem Correta (Visão DDD Mapper Idea):** Dentro de `Comprador.mi` (Contexto de Pedidos), criar uma referência simples para o outro contexto: `[r] contratanteOrigem: Cliente()`.

### Entregável
Arquivos `.mi` para cada entidade, devidamente registrados em `main.mi`.

### Sinal de que está pronto
Qualquer pessoa do time consegue ler um arquivo `.mi` e entender o que a entidade faz, o que cada campo significa e como ela se relaciona com o resto do modelo — sem precisar de explicação adicional.

---

## 7. Fase 4 — Revisão Geral do Modelo

### Objetivo
Validar consistência, completude e coerência semântica de todo o modelo antes de gerar documentação final ou código.

### Checklist de revisão

#### Metadados
- [ ] Toda entidade tem `title` e `description` em `pt` e `en`?
- [ ] Todo atributo tem `title` e `description` em `pt` e `en`?
- [ ] Todo pacote em `main.mi` tem `title` e `description`?

#### Relenvios
- [ ] Todo `[m]` (detalhe→mestre) tem um `[o]` (mestre→detalhe) correspondente na entidade mestre do **mesmo contexto**?
- [ ] Relenvios cross-context usam `[r]` (referência simples)?
- [ ] Nenhum `[o]` aponta para entidade de outro contexto (implicaria cascade indesejado)?

#### Ciclos de vida
- [ ] Todos os campos `status` têm os valores possíveis documentados na `description`?
- [ ] Os status cobrem todos os estados que o negócio requer?
- [ ] Existem transições de status que precisam de campo de data correspondente? (ex: `paidAt`, `closedAt`, `completedAt`)

#### Consistência
- [ ] Nomes de campos equivalentes são consistentes entre entidades? (ex: `dataCriacao` em todas — não `dataCriacao` em uma e `criadoEm` em outra)
- [ ] Tipos de dados são consistentes? (ex: documentos sempre como `Texto(14)`)
- [ ] Campos `ativo` e `dataCriacao` presentes em todas as entidades persistíveis?

#### Dependências cross-context
- [ ] Referências cross-context usam `[r]` e não `[m]`?
- [ ] Dados que precisam de histórico (ex: configurações no momento do evento) são copiados, não apenas referenciados?

### Como conduzir a revisão
Leia o modelo entidade por entidade e siga o checklist. Anote cada problema encontrado com:
1. O que está errado
2. Por que está errado (semântica, inconsistência, lacuna)
3. O que deve ser feito

Aplique as correções e re-verifique os pontos afetados.

### Entregável
Modelo revisado sem pendências abertas no checklist.

---

## 8. Fase 5 — Documentação para Aprovação

### Objetivo
Transformar o modelo técnico em documentação legível para todos os membros do time — inclusive os não-técnicos — para aprovação formal antes do início da implementação.

### Documentos a produzir

**`docs/modelo-de-dominio-pt.md`** — versão em português
**`docs/domain-model-en.md`** — versão em inglês

Ambos os documentos devem cobrir:

1. **Visão geral** — o que o sistema faz em dois parágrafos
2. **Linguagem ubíqua** — tabela de termos canônicos (PT) com definições
3. **Hierarquia de tenancy e regras de isolamento** — a espinha dorsal do modelo
4. **Bounded Contexts** — um por seção, cada um com:
   - Responsabilidade do contexto
   - Tabela de campos de cada entidade (sem verbosidade técnica)
   - Ciclo de vida de status (quando relevante)
   - Regras de negócio específicas do contexto
5. **Decisões arquiteturais** — as escolhas de design com justificativa
6. **Mapa de referências** — diagrama mostrando dependências entre contextos
7. **Próximos passos** — o que vem depois da aprovação

### Nível de linguagem
Os documentos devem ser lidos por pessoas de negócio, não apenas por desenvolvedores. Evite jargão técnico nas descrições. Nomes de entidades e campos usam os termos técnicos canônicos em português, conforme o glossário do projeto. Toda explicação deve ser em linguagem de negócio.

### Entregável
Dois documentos aprovados pelo time (PT e EN).

---

## 9. Princípios de Design Adotados

Estes são os princípios que guiaram as decisões de modelagem na Loja e devem ser aplicados nos próximos projetos:

### 9.1 Referência simples antes de mestre/detalhe

**Regra:** use `[r]` (referência oneToOne) para relenvios entre entidades de contextos diferentes. Use `[m]`/`[o]` (mestre/detalhe com cascade) apenas quando o ciclo de vida da entidade filha é genuinamente dependente da mãe e ambas estão no mesmo contexto.

**Por quê:**
- `[m]`/`[o]` implica delete em cascata — perigoso para relenvios cross-context
- `[r]` evita carregamento antecipado de dados que não serão usados a todo momento
- Exclusões mais controladas: cada entidade pode ser gerenciada de forma independente

**Como decidir:**
> "Se eu deletar a entidade A, a entidade B deve ser deletada automaticamente?"
> - Sim, e A e B são do mesmo contexto → `[m]`/`[o]`
> - Não, ou são de contextos diferentes → `[r]`

### 9.2 Isolamento de dados como invariante de negócio

Em sistemas multi-tenant com requisitos LGPD/GDPR, o isolamento de dados por tenant não é uma decisão técnica — é uma regra de negócio que deve estar **visível no modelo**. Documente o escopo de acesso em cada entidade que carrega dados pessoais.

### 9.3 Preservação do dado bruto para rastreabilidade regulatória

Quando o sistema recebe dados de fontes externas (importações, integrações, webhooks), preserve o conteúdo original bruto junto ao registro processado. Isso garante rastreabilidade de origem exigida por regulamentações como LGPD.

### 9.4 Credenciais nunca no modelo de domínio

Nenhuma entidade deve armazenar tokens, senhas ou chaves de API diretamente. Use um campo de referência (ex: `credentialsRef`) que aponta para um cofre de segredos externo.

### 9.5 Auditoria por snapshot, não por referência

Quando um evento de negócio precisa ser auditado (ex: um envio enviado), registre o estado das configurações usadas **no momento do evento**, não apenas a referência. Configurações mudam — o histórico não deve ser distorcido por mudanças posteriores.

### 9.6 Status com ciclo de vida documentado

Todo campo `status` deve ter seus valores possíveis documentados na `description` do atributo no mapa. Nunca deixe um enum implícito ou "descoberto no código". O modelo é a fonte de verdade.

### 9.7 Enums estruturados com `[e] values`

Todo atributo com tipo enum deve declarar um bloco `[e] values` dentro do seu `@`, listando cada valor possível com `title` e `description` bilíngues (`pt` e `en`). Esta estrutura é consumida por geradores para criar validações automáticas, mensagens de erro localizadas e documentação de API.

**Estrutura obrigatória:**

```
[d] status: Texto(20)
    @
        [e] title
            ...
        [e] description
            ...
        [e] required
            [v] true
        [e] values
            [e] VALOR_DO_ENUM
                [e] title
                    [e] pt
                        [v] Rótulo legível em português (para exibição em tela)
                    [e] en
                        [v] Human-readable label in English
                [e] description
                    [e] pt
                        [v] Explicação do que este valor significa no negócio,
                          | incluindo pré-condições, efeitos e restrições.
                    [e] en
                        [v] Explanation of what this value means in the business,
                          | including pre-conditions, effects and restrictions.
```

**Regras:**
- O nome do `[e]` filho de `values` é o valor técnico exato do enum (ex: `RASCUNHO`, `CONFIRMADO`) — em `SNAKE_CASE_MAIUSCULO`.
- `title` contém o rótulo exibido ao usuário em tela — em linguagem de negócio, sem underscores.
- `description` explica a semântica completa do valor: quando ocorre, o que habilita/bloqueia, se é reversível.
- O bloco `[e] values` deve ser o último elemento dentro do `@`, após `required` (quando presente).
- Geradores podem acessar os values via XPath: `properties/values/*/title/pt/value` para títulos e `properties/values/*/description/pt/value` para descrições.

**Exemplo completo:**

```
[d] status: Texto(20)
    @
        [e] title
            [e] pt
                [v] Status
            [e] en
                [v] Status
        [e] description
            [e] pt
                [v] Estado atual do registro. Valores documentados em [e] values.
            [e] en
                [v] Current state of the record. Values documented in [e] values.
        [e] required
            [v] true
        [e] values
            [e] PENDENTE
                [e] title
                    [e] pt
                        [v] Pendente
                    [e] en
                        [v] Pending
                [e] description
                    [e] pt
                        [v] Estado inicial. Aguardando processamento.
                    [e] en
                        [v] Initial state. Awaiting processing.
            [e] CONCLUIDO
                [e] title
                    [e] pt
                        [v] Concluído
                    [e] en
                        [v] Completed
                [e] description
                    [e] pt
                        [v] Processamento finalizado com sucesso.
                    [e] en
                        [v] Processing completed successfully.
```

**Por que esta abordagem:**
- Geradores de validação podem iterar sobre `properties/values/*` para criar enums de linguagem de programação e mensagens de erro sem conhecer os valores no template.
- Documentação de API (Swagger/OpenAPI) pode ser gerada automaticamente com descrições por valor.
- A `description` do atributo continua descrevendo o campo como um todo (incluindo a lista resumida de valores para leitura humana rápida); o `[e] values` adiciona a estrutura consumível por máquina.

### 9.8 Campos de data associados a transições de status

Para cada transição de status relevante, considere se há uma data associada que precisa ser registrada. Exemplos: `paidAt`, `closedAt`, `verifiedAt`, `completedAt`. A data de transição tem valor de auditoria e frequentemente de negócio.

### 9.9 Serviços de domínio com métodos de transição de estado

Quando o ciclo de vida de uma entidade é suficientemente complexo para exigir documentação explícita das pré-condições, mutações e efeitos colaterais de cada transição, modele-o como um **serviço de domínio** separado usando `[c]` (classe auxiliar não persistível) com métodos `[x]`.

**Quando usar este padrão:**
- A entidade tem 5+ transições de estado com pré-condições distintas
- Cada transição produz efeitos colaterais em outras entidades (cascata)
- As regras de transição são referenciadas externamente (ex: TR-01 a TR-10, na numeração do seu projeto)
- O time precisa de documentação executável — não apenas declarativa

**Estrutura do serviço:**

```
[c] CicloNomeDaEntidade
    @
        [e] title / [e] description (pt + en)

    [x] verboDominio: TipoRetorno()
        @
            [e] cn
                [v] TR-XX            ← código da regra de transição (referência externa)
            [e] title / [e] description (pt + en)
        parameter
            entidade: NomeDaEntidade()
            ator: TipoDeAtor()
            parametrosAdicionais: TipoParametro()
        body
            pre
                =
                    entidade.status
                    ESTADO_ESPERADO
                condicao narrativa descritiva (texto livre)
                if
                    condition
                        =
                            entidade.atributoDeGuarda
                            false
                    then
                        lancar ExcecaoDominio()
                            "motivo da excecao"
            do
                entidade.status
                    =
                        NOVO_ESTADO
                entidade.campoDaTransicao
                    =
                        valor
                efeito em outra entidade
            emit
                EventoDeDominio()
                    parametro1
                    parametro2
```

**Convenções:**
- O nome do método segue clean code: verbo de domínio em camelCase, sem abreviações, sem o código da regra (ex: `confirmarPedido`, não `executarTR02`)
- O código da regra fica exclusivamente no `[e] cn` do `@` do método
- `pre` — bloco de pré-condições: guarda da transição; se não satisfeita, lança exceção de domínio
- `do` — bloco de mutações de estado: o que muda nos objetos envolvidos
- `emit` — bloco de eventos e efeitos colaterais assíncronos ou observáveis
- `pre`, `do` e `emit` são nós de texto sem ícone (válidos na gramática `.mi`) — cada linha filha indentada é uma pré-condição, mutação ou evento
- Dependências abertas são documentadas com `//` dentro do `body` — nunca silenciadas (ver seção 9.10 para sintaxe correta de `//`)
- O tipo de retorno é o tipo principal afetado pela transição (ex: `Cliente()`); transições de exclusão usam `Void()`
- O arquivo do serviço é nomeado em PascalCase com prefixo `Ciclo` (ex: `CicloCliente.mi`)

**Exemplo completo (TR-02 do domínio de exemplo):**

```
[x] confirmarPedido: Pedido()
    @
        [e] cn
            [v] TR-02
        [e] title
            [e] pt
                [v] TR-02 — Confirmar Pedido
            [e] en
                [v] TR-02 — Confirm Order
        [e] description
            [e] pt
                [v] Transição RASCUNHO → CONFIRMADO. Congela os precos dos itens e
                  | reserva o estoque; a partir daqui o pedido nao e mais editavel.
            [e] en
                [v] Transition RASCUNHO → CONFIRMADO. Freezes item prices and reserves
                  | stock; from here the order is no longer editable.
    parameter
        pedido: Pedido()
        ator: UsuarioOperador()
    body
        pre
            =
                pedido.situacao
                RASCUNHO
            ao menos um ItemPedido com quantidade maior que zero
            pedido.cliente.ativo = true
            estoque disponivel para todos os itens (TR-02a)
        do
            pedido.situacao
                =
                    CONFIRMADO
            pedido.dataConfirmacao
                =
                    agora
            itens.precoUnitario
                =
                    congelado no valor vigente
        emit
            PedidoConfirmado()
                idPedido
                idAtor
                timestamp
                totalConfirmado
            EmailConfirmacaoEnviado()
                destinatario: cliente
```

**Relação com o arquivo de entidade:** o serviço de domínio não substitui o arquivo de entidade (`Cliente.mi`). Os atributos, tipos, relenvios e documentação de cada valor de enum continuam no arquivo da entidade. O serviço documenta o **comportamento** — a entidade documenta a **estrutura**.

### 9.10 Sintaxe de comentários `//`

Comentários em `.mi` são nós na árvore hierárquica — o texto do comentário é sempre **filho indentado** do nó `//`, nunca escrito na mesma linha.

**Correto — texto como filho:**
```
//
    Este é o texto do comentário.
    Linhas adicionais ficam no mesmo bloco filho,
    alinhadas na mesma profundidade.
```

**Incorreto — texto na mesma linha:**
```
// Este texto está errado — nunca na mesma linha que //
// Idem para continuação em linha seguinte com // repetido
```

**Regras:**
- O nó `//` fica sozinho na linha, sem texto
- O texto do comentário é filho direto do `//`, indentado 4 espaços abaixo
- Múltiplas linhas de texto pertencem ao mesmo comentário enquanto mantiverem a mesma indentação — não repita `//` por linha
- Comentários que documentam um elemento (ex: dependência aberta dentro de `body`) ficam **dentro** do elemento que comentam, não antes dele no nível pai

**Exemplo com dependência aberta dentro de `emit`:**
```
emit
    PedidoReaberto()
        idPedido
        idAtor
        motivo
        timestamp
    //
        D-07 — Dependencia aberta: comportamento das reservas de estoque ja emitidas
                 nao documentado. Impacto alto — bloqueia implementacao de TR-05.
```

**Separadores de seção como comentários:**

Quando `//` é usado para criar separadores visuais entre métodos, o separador pertence ao método que vem depois — coloque-o como primeiro filho do `[x]`, não como irmão do método no nível acima:

```
[x] meuMetodo: TipoRetorno()
    //
        ──────────────────────────────────────────────────────────────────────────
    //
        Título da seção ou identificador do método (ex: TR-01)
    //
        ──────────────────────────────────────────────────────────────────────────
    @
        ...
    body
        ...
```

### 9.11 Sintaxe de chamadas de função/evento com parâmetros indentados

Em blocos `emit`, `pre` e `do` de serviços de domínio, chamadas de função/evento com parâmetros devem usar a sintaxe com parâmetros como filhos indentados — nunca como argumentos inline entre parênteses.

**Correto — parâmetros como filhos indentados:**
```
emit
    PedidoConfirmado()
        idPedido
        idAtor
        timestampConfirmacao
        totalConfirmado
    EmailConfirmacaoEnviado()
        destinatario: cliente do pedido
```

**Incorreto — parâmetros inline:**
```
emit
    PedidoConfirmado(idPedido, idAtor, timestampConfirmacao, totalConfirmado)
    EmailConfirmacaoEnviado(destinatario: cliente do pedido)
```

**Regras:**

- O nome da função/evento fica na primeira linha com `()` vazio — sem parâmetros entre os parênteses
- Cada parâmetro fica como filho indentado (4 espaços) abaixo da linha do nome da função
- Parâmetros com valor padrão, tipo específico ou enum vinculado usam `: valor` na mesma linha do parâmetro (ex: `origemEstado: RASCUNHO`)
- Parâmetros simples — referências a variáveis do contexto — ficam sozinhos na linha, sem `: valor`
- A mesma sintaxe se aplica a chamadas `lancar` dentro de blocos `pre`:

```
pre
    if
        condition
            !=
                pedido.dataFaturamento
                null
        then
            lancar ExclusaoVedada()
                "Pedido ja faturado — TR-04"
```

**Por que esta sintaxe:**
A gramática `.mi` define hierarquia exclusivamente por indentação. Parâmetros entre parênteses formam um valor textual único no mesmo nó — não são filhos na árvore, portanto não são navegáveis por XPath e não podem receber `@` com metadados. Com parâmetros indentados, cada argumento é um nó filho independente, permitindo que geradores iterem sobre eles e que metadados sejam adicionados por parâmetro quando necessário.

### 9.12 Sintaxe de condições no bloco `pre`

**Regra geral: o operador é sempre o nó pai. Os operandos são seus filhos.**

Essa estrutura é consistente com toda a pseudo-linguagem do Mapper Idea — a mesma lógica do bloco `if/condition` nos métodos se aplica ao `pre`. Nunca escreva operadores na mesma linha que seus operandos.

O bloco `pre` aceita quatro formas de condição. A escolha depende do grau de estruturação necessário:

#### Forma 1 — Igualdade e comparação estrutural

Use quando a pré-condição é uma comparação direta entre um atributo e um valor. O operador (`=`, `!=`, `>`, `<`, `>=`, `<=`) é o nó pai; o operando esquerdo e o operando direito são seus filhos, em ordem.

```
pre
    =
        pedido.situacao
        RASCUNHO
    =
        pedido.cliente.ativo
        PENDENTE
```

Operadores disponíveis: `=`, `!=`, `>`, `<`, `>=`, `<=`

Múltiplas condições em sequência no mesmo `pre` são tratadas como AND implícito — todas devem ser satisfeitas.

#### Forma 2 — Alternativa lógica com `OR`

Use quando a pré-condição admite duas ou mais alternativas equivalentes. O `OR` é o nó pai; cada alternativa é um filho. Alternativas podem ser condições estruturais (com operador como pai) ou texto narrativo — os dois tipos podem coexistir como filhos do mesmo `OR`.

```
pre
    OR
        =
            entrega.flagSemPrazo
            true
        entrega.dataPrevista preenchida
```

O primeiro filho do `OR` acima é uma condição estrutural; o segundo é texto narrativo. Ambos são válidos como filhos do `OR`.

#### Forma 3 — Guard com exceção (`if/condition/then`)

Use quando a pré-condição deve lançar uma exceção de domínio se não satisfeita. A estrutura espelha exatamente o bloco `if/condition` dos métodos: `if` é o nó pai, `condition` contém a expressão lógica (com operador como pai), e `then` declara a ação.

```
pre
    if
        condition
            !=
                pedido.dataFaturamento
                null
        then
            lancar ExclusaoVedada()
                "Pedido ja faturado — TR-04"
```

**Estrutura do guard:**
- `if` é o nó pai
- `condition` contém o operador como pai, com os dois operandos como filhos
- `then` contém a ação `lancar` com seus argumentos como filhos
- Texto descritivo sobre o resultado da guarda volta ao nível do `pre` — nunca é filho do `lancar` ou do `then`

#### Forma 4 — Condição narrativa (texto livre)

Use quando a pré-condição é descritiva e não requer operadores estruturais. Cada linha filho do `pre` é um nó de texto simples, sem operador formal.

```
pre
    estoque disponivel para todos os itens (TR-02a)
    ao menos um ItemPedido com quantidade maior que zero
    para cada item com entrega agendada: item.dataEntrega maior que hoje (TR-02b)
```

Condições narrativas são válidas e preferíveis quando a expressão em texto de negócio é mais clara do que a forma estrutural.

---

#### Anti-padrões no `pre`

**Errado — operador como filho do operando (padrão invertido):**

```
pre
    pedido.situacao
        = RASCUNHO
    pedido.cliente.ativo
        = PENDENTE
```

**Correto — operador como pai, operandos como filhos:**

```
pre
    =
        pedido.situacao
        RASCUNHO
    =
        pedido.cliente.ativo
        PENDENTE
```

**Errado — operador inline na mesma linha que o operando:**

```
pre
    pedido.situacao = RASCUNHO
```

**Correto:**

```
pre
    =
        pedido.situacao
        RASCUNHO
```

**Errado — uso de `se` como condicional (proibido em qualquer forma):**

```
pre
    se pedido.dataFaturamento != null
        lancar ExclusaoVedada()
            "Pedido ja faturado — TR-04"
```

`se` não existe na gramática `.mi`. Toda condicional usa `if/condition/then` — inclusive guards com `lancar`.

**Correto:**

```
pre
    if
        condition
            !=
                pedido.dataFaturamento
                null
        then
            lancar ExclusaoVedada()
                "Pedido ja faturado — TR-04"
```

**Errado — notação lambda (não existe na gramática .mi):**

```
pre
    pedido.itens.any()
        i => i.quantidade > 0
```

**Correto — texto livre de negócio:**

```
pre
    ao menos um ItemPedido com quantidade maior que zero
```

**Errado — texto descritivo do resultado como filho do `lancar`:**

```
pre
    if
        condition
            =
                revalidacaoTecnica.aprovada
                false
        then
            lancar FalhaRevalidacaoTecnica()
                errosPorCanal
                pedido permanece EM_SEPARACAO  ← filho errado do lancar
```

**Correto — texto descritivo no nível do `pre`:**

```
pre
    if
        condition
            =
                revalidacaoTecnica.aprovada
                false
        then
            lancar FalhaRevalidacaoTecnica()
                errosPorCanal
    pedido permanece EM_SEPARACAO  ← no nível correto, filho do pre
```

---

## 10. Guia Rápido de Ícones Mapper Idea

Referência rápida dos ícones usados na modelagem de domínio:

| Ícone | Significado | Quando usar |
|---|---|---|
| `[b]` | Entidade (bean) | Toda classe de domínio persistível |
| `[p]` | Pacote | Bounded Context ou namespace |
| `[g]` | Agrupador visual | Organizar atributos por categoria |
| `[d]` | Atributo simples | Texto, número, data, boolean |
| `[r]` | Referência (oneToOne) | FK para outra entidade, cross-context ou ciclo de vida independente |
| `[o]` | Coleção mestre→detalhe | Lista de entidades filhas com cascade delete, mesmo contexto |
| `[m]` | Detalhe→mestre | Lado filho de uma relação mestre/detalhe, mesmo contexto |
| `[e]` | Elemento de metadados | Propriedades dentro do `@` |
| `[v]` | Valor | Conteúdo de uma propriedade |
| `#` | Referência a arquivo | Expansão de conteúdo de outro `.mi` |

**Tipos de dados comuns:**

| Tipo (negócio) | Uso |
|---|---|
| `Texto(n)` | Strings com tamanho máximo definido |
| `TextoLongo()` | Strings sem limite de tamanho (blob, JSON, texto livre) |
| `Inteiro(n)` | Números inteiros |
| `Decimal(p,s)` | Números decimais com precisão e escala |
| `ValorMonetario()` | Valores monetários (mapeados para BigDecimal nos geradores) |
| `Boolean()` | Verdadeiro/falso |
| `Data()` | Data sem hora |
| `DataHora()` | Data com hora e fuso |

---

## 11. Checklist de Qualidade — por Entidade

Use este checklist ao criar ou revisar qualquer entidade:

```
[ ] Nome em PascalCase, singular, em português
[ ] @: title e description em pt e en
[ ] Atributos agrupados com [g] por categoria
[ ] Todos os atributos têm title e description em pt e en
[ ] Campo status tem enum documentado na description (se aplicável)
[ ] Atributos com enum têm [e] values no @ com title e description em pt e en por valor (seção 9.7)
[ ] Campo ativo presente (Boolean)
[ ] Campo dataCriacao presente (DataHora)
[ ] Datas de transição de status presentes onde relevante
[ ] Relenvios no último grupo [g]
[ ] Campos de relenvio ([r], [o], [m]) não usam prefixo id no nome (CN-REL-001)
[ ] Campos [d] com UUID bruto usam prefixo id no nome (CN-REL-002)
[ ] Todo atributo tem [e] cn no @ com o nome canônico snake_case do glossário (CN-003)
[ ] Relenvios intra-contexto usam [m] ou [o]
[ ] Relenvios cross-context usam [r]
[ ] Condições em pre usam operador como pai com operandos como filhos (seção 9.12)
[ ] Não existe se como condicional — usar sempre if/condition/then (seção 9.12)
[ ] Atribuições em do usam alvo como raiz, = como filho, valor como filho do =
[ ] Entidade registrada em main.mi no pacote correto
[ ] Referência # no main.mi é filha de [b] NomeDaEntidade — nunca filha direta do [p]
[ ] Referência # no main.mi usa caminho relativo ao main.mi
```

---

## 12. Estrutura de Arquivos de Referência

```
repositorio/
├── CLAUDE.md                          ← guia do projeto para o assistente de IA
├── mi/
│   ├── main.mi                        ← mapa raiz com todos os pacotes e referências
│   ├── cadastro/
│   │   ├── Cliente.mi
│   │   └── Fornecedor.mi
│   ├── pedidos/
│   │   ├── Comprador.mi
│   │   └── ...
│   ├── contextoN/
│   │   └── Entidade.mi
│   └── generators/                    ← geradores de código (fase futura)
│       └── quarkus/
│           └── entity.mi
└── docs/
    ├── modelo-de-dominio-pt.md        ← documentação do domínio em português
    ├── domain-model-en.md             ← documentação do domínio em inglês
    ├── guia-modelagem-ddd-mapper-idea.md  ← este documento
    └── padronizacaoTermos.md          ← glossário do projeto
```

---

## 13. O que Vem Depois

Após a aprovação do modelo de domínio, os próximos passos naturais são:

**Mapa de Arquitetura (Geradores)**
Com o modelo de negócio estável, é possível criar geradores Mapper Idea que transformam as entidades em código para o stack escolhido (Quarkus, Spring, OpenAPI etc.). O mapa de negócio não muda — apenas o mapa de arquitetura evolui conforme o stack.

**Modelagem de Telas (`window`)**
Quando o domínio estiver aprovado, telas e fluxos de UI podem ser modelados como um pacote irmão de `domain` dentro do namespace da empresa. Isso mantém a separação clara entre o modelo de negócio e a representação visual.

**Refinamento contínuo**
O modelo de domínio é um artefato vivo. À medida que o time aprende mais sobre o negócio, novos conceitos emergem e decisões anteriores precisam ser revisitadas. O Mapper Idea facilita esse refinamento — qualquer alteração no mapa se propaga automaticamente para o código gerado.

---

## Resumo Visual do Processo

```
┌─────────────────────────────────────────────────────────┐
│                  ANTES DE MODELAR                       │
│  Contexto + Atores + Regulações + CLAUDE.md + Repo     │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│              FASE 1 — LINGUAGEM UBÍQUA                  │
│  Termos canônicos PT · Definições · Glossário em docs/  │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│         FASE 2 — HIERARQUIA E REGRAS ESTRUTURAIS        │
│  Tenancy · Isolamento · Pacotes em main.mi              │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│         FASE 3 — MODELAGEM POR BOUNDED CONTEXT          │
│  Discussão → Entidades → Atributos → Relenvios    │
│  Metadados PT+EN → Registro em main.mi                  │
│  (um contexto por vez, do mais independente ao menos)   │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│            FASE 4 — REVISÃO GERAL DO MODELO             │
│  Metadados · Relenvios · Status · Consistência    │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│          FASE 5 — DOCUMENTAÇÃO PARA APROVAÇÃO           │
│  modelo-de-dominio-pt.md · domain-model-en.md           │
│  Aprovação do time → Próxima fase do projeto            │
└─────────────────────────────────────────────────────────┘
```
