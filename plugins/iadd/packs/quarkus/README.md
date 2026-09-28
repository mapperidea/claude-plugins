# Pack `quarkus` — contrato

Sete geradores que emitem, por entidade, a pilha Java/Quarkus completa a partir do Mapa de Negócio:

| Sub-gerador | Emite |
|---|---|
| `domain` | o objeto de domínio |
| `entity` | a entidade JPA |
| `builder` | o builder da entidade |
| `repository` | o repositório, com filtro multi-tenant e busca |
| `mapper` | a conversão domínio ↔ entidade, com mascaramento de dado pessoal |
| `resource` | o recurso REST |
| `swagger/restAPI` | o contrato OpenAPI do pacote inteiro |
| `struct/xml` | não emite código: despeja o DOM de uma classe — cópia do `struct` do pack padrão, para validar o mapa |

São **476 KB de geradores testados em produção** — e o valor principal deles, para você, provavelmente não
é usá-los: é **lê-los**. Eles são a demonstração mais completa que existe de como observar o DOM, fazer
dispatch por tipo, resolver relacionamento e emitir um arquivo por classe.

## O que o seu mapa precisa ter para eu gerar

**No `main.mi`** — o bloco `config/mapperidea/maps`:

- `mapNativeTypes` com as famílias `String`, `BigString`, `Integer`, `Long`, `Double`, `Boolean`, `Date`,
  `DateTime`, `Binary`, cada uma listando os sinônimos que o seu modelo usa. **Sem isso nenhum dispatch
  casa** e tudo cai no `@TODO`.
- `toSwaggerTypes` se for usar o gerador de OpenAPI.
- `nondeterministicSearchField` para a busca do repositório.
- O registro dos sub-geradores sob `config/mapperidea/generators/quarkus/<sub>`.

**Nas entidades** — as propriedades do bloco `@` que estes geradores leem:

| Propriedade | Para quê |
|---|---|
| `cn` | nome da coluna física |
| `required` | obrigatoriedade |
| `values` | enum |
| `title`, `description` | Javadoc e documentação da API |
| `defaultValue` | valor padrão (a propriedade mais lida do pack) |
| `readOnly`, `storageOnly` | campo que não entra na escrita / não sai na leitura |
| `searchable`, `sk`/`SK` | participa da busca / chave secundária |
| `tenantKey` | o campo que carrega o tenant |
| `apiRelation`, `fetch` | como a relação aparece na API e como é carregada |
| `optimisticLock`, `transaction` | controle de concorrência |
| `path`, `in`, `summary`, `resources`, `mimeType` | contrato REST/OpenAPI |

Propriedade que o DOM não conhece **não chega ao gerador** — ele só materializa vocabulário conhecido.
(A lista acima é o que *estes geradores* leem, não o vocabulário do DOM: `projectNames` e `language`, por
exemplo, chegam e são lidas.)

**O que o mapa precisa e não é óbvio** — cada item custou uma volta de gerar–compilar–ler no
[exemplo executável](exemplo/):

| Precisa de | Senão |
|---|---|
| `id: Texto(36)` em toda entidade | o entity emite `@Id` + `GenerationType.UUID` a partir dele, com o `length` do parâmetro. `idErp`, `uuid` e `version` também são nomes com significado fixo |
| `cn` **também nas relações** (`[r]`, `[m]`) | `@JoinColumn(name="")` — **compila**, e está errado |
| tamanho explícito em `Inteiro(n)` / `InteiroLongo(n)` | o `swagger/restAPI` aborta com `EMI9005 … mi:replicate()` (`swagger-restAPI.mi:96,99,102`: o `mi:if-else` avalia os dois ramos, e a guarda `exists` não protege) |
| nada de `:` na `description` do pacote | o OpenAPI a emite sem aspas e o YAML não parseia |
| uma classe `CurrentSchema` com `@ projectNames/projectName`, `host`, `tokenUrl` | título, host e tokenUrl do OpenAPI saem vazios |

Três grafias e níveis que enganam:

- **`SK` e `sk` não são sinônimos**: `domain`, `mapper` e `swagger` leem `properties/SK`; `repository` e
  `resource` leem `properties/sk`. Declare os dois, ou escolha e ajuste os geradores.
- **`optimisticLock` e `transaction` são propriedades do pacote**, não da entidade. Sem `optimisticLock`,
  o padrão liga o `@Version`.
- **`nondeterministicSearchField`** gera busca com `unaccent()` — função do **PostgreSQL**; em outro banco
  a busca com `*` dá erro de SQL.

**O pacote** segue o padrão `<raiz>.domain.<contexto>`: o repositório deriva o pacote da entidade JPA com
`substring-before(@package,'.domain.')`. Se o seu pacote não tiver o segmento `.domain.`, essa derivação
sai errada — é o primeiro lugar a olhar. Com `com.exemplo.domain.loja`, as camadas saem em
`com.exemplo.loja.{domain,entity,builder,repository,mapper,resource}`.

## O que o seu projeto precisa ter para compilar a saída

O código gerado importa três classes que **não são geradas**, na raiz do pacote:
`<raiz>.exceptions.NotFoundException`, `<raiz>.exceptions.InvalidInputException` e
`<raiz>.results.CountResult` (o [exemplo](exemplo/README.md) traz as três, prontas). E as extensões
Quarkus `hibernate-orm-panache`, `rest-jackson`, `hibernate-validator` e **`smallrye-jwt`** — todo
resource injeta `JsonWebToken`. Com casos que o exemplo não exercita, o resource importa ainda
`<raiz>.results.StatusProcessamentoUpload` e `<raiz>.service.<X>Service`/`<X>UploadService`.

**`mi generate` devolve 0 mesmo quando falha**, e escreve o `EMI…` no stdout — com `>`, o erro fica
**dentro** do arquivo gerado. Depois de gerar: `grep -rl 'EMI[0-9]' <saída>`.

## O que aqui é do projeto de origem, e você vai querer trocar

| Onde | O quê | O que fazer |
|---|---|---|
| `quarkus-repository.mi:531` | `import com.exemplo.tenant.EscopoTenant;` — pacote **placeholder** | só é emitido se algum atributo tiver `tenantKey` — **se o seu projeto não é multi-tenant, não precisa fazer nada**. Se for, aponte para a sua classe, que precisa de `boolean irrestrito()` e `String exigir(String coluna)` |
| `quarkus-mapper.mi:129,293,386`, `quarkus-resource.mi:244,366,381,405,420,486` | `@Transactional(propagation = …, transactionManager = …)` — API do **Spring**; `:366` tem `"tenantTransactionManager"` fixo | só sai com `transaction` no pacote. Ligado, a saída **não compila** num Quarkus puro: troque pela anotação do seu projeto |
| — | *(nada mais)* — os identificadores de issue e nomes de teste do projeto de origem, que eram **emitidos dentro do código gerado**, foram removidos em 17/09/2026 | — |
| convenção de pacote | o segmento `.domain.` descrito acima | ajuste a derivação se o seu layout for outro |

Os geradores não emitem cabeçalho de geração no código de saída.

## Limites conhecidos

Achados rodando a aplicação gerada (não são gate de compilação):

- **Referência só com `{ "id": … }` dá 500.** A seleção do modo `weakReference` (`quarkus-domain.mi`,
  `isAnyNotKeyFieldsDefined()`) conta o próprio `id` como campo não-chave — só exclui `idErp`, `uuid` e o
  `SK` —, então o objeto nunca é tratado como referência fraca. Mandar o objeto inteiro (com `version`)
  funciona.
- **`required` não é imposto na entrada**: o domain tem `@NotNull`/`@NotEmpty`, mas o resource não usa
  `@Valid`.
- **Filtro por campo de relação é aceito e ignorado** (ex.: `Pedido?nome=…` do cliente): o repository
  recebe `clienteNome` e nenhum predicado o usa.
- **`values` não vira `enum` Java** nem validação; no OpenAPI, a lista só sai para enum de tipo `Integer`.
- **OpenAPI**: `TextoLongo` sai como `$ref: IdReference`; uma lista aponta para
  `#/definitions/ItemPedido`, mas a definição se chama `loja.ItemPedido`; `readOnly` some do schema em
  vez de sair marcado.

## Estado

Versão da cópia: **2026-09-17** (contrato revisado e exemplo executável em 2026-09-25), extraída de um monorepo em produção. **Semente, sem canal de atualização**
— correções feitas na origem depois desta data não chegam aqui; se quiser, diffe contra uma cópia mais nova
por conta própria.

## Exemplo executável

[`exemplo/`](exemplo/) — uma loja de ensino (Cliente, Fornecedor, Pedido, ItemPedido) com as 9 famílias
de tipo, um enum, uma relação fraca e duas referências. **Prova que o pack gera fora do projeto de
origem**: 24 arquivos Java + o OpenAPI, e `mvn clean compile` → `BUILD SUCCESS` (verificado em
2026-09-25, mi 1.0.9, Java 17, Quarkus 3.15). Nenhum gerador foi editado para isso.

```sh
cd plugins/iadd/packs/quarkus          # a pasta do main.mi: ela vira a home do projeto
mi init exemplo-quarkus main.mi
mi push exemplo-quarkus
mi generate exemplo-quarkus quarkus entity modelName=Pedido package=com.exemplo.domain.loja
```

O comando completo (as 6 camadas × 4 entidades), o `pom.xml` e as classes de suporte estão no
[README do exemplo](exemplo/README.md). Para aprender a escrever gerador, comece pelo
[`_exemplar`](../_exemplar/).
