# Exemplo executável do pack `quarkus`

O mapa mínimo, **fora de qualquer domínio real**, cujo `generate` produz uma pilha Java/Quarkus que
**compila**. É a prova de que o pack funciona fora do projeto que o gerou — e o tutorial de entrada.

```
exemplo/main.mi                 config/maps + registro dos 7 sub-geradores + CurrentSchema
exemplo/dominio/Cliente.mi      referenciado por Pedido ([r])
exemplo/dominio/Fornecedor.mi   referenciado por ItemPedido ([r]); carrega Long e Binary
exemplo/dominio/Pedido.mi       a entidade de prova: enum, datas, monetário, [r] e [o]
exemplo/dominio/ItemPedido.mi   o detalhe, lado [m] da relação fraca
```

## O que o mapa exercita

| Forma / propriedade | Onde |
|---|---|
| as 9 famílias do `mapNativeTypes` (`String`, `BigString`, `Integer`, `Long`, `Double`, `Boolean`, `Date`, `DateTime`, `Binary`) | `Texto`, `TextoLongo`, `Inteiro`, `InteiroLongo`, `ValorMonetario`, `Boolean`, `Data`, `DataHora`, `Binario` |
| enum (bloco `values`) | `Pedido.situacao` |
| referência `[r]` (normaliza como `oneToOne`) | `Pedido.cliente`, `ItemPedido.fornecedor` |
| relação fraca `[o]`/`[m]` (`oneToMany`/`manyToOne`) | `Pedido.itens` ↔ `ItemPedido.pedido` |
| `cn` — inclusive **nas relações**, onde vira o `@JoinColumn` | todas |
| `required`, `defaultValue`, `readOnly`, `storageOnly`, `searchable` | `Pedido`, `Cliente`, `Fornecedor`, `ItemPedido` |
| `apiRelation` = `EMBEDDED` (a lista de itens sai dentro do Pedido) | `Pedido.itens` |
| `fetch` = `EAGER` | `Pedido.cliente` |
| `nondeterministicSearchField` | `nome`, `razaoSocial` (ver a nota sobre `unaccent` abaixo) |
| `CurrentSchema/projectNames` (título, host e tokenUrl do OpenAPI) | `main.mi` |

**Não** exercita `tenantKey` (o exemplo não é multi-tenant, e sem `tenantKey` o bloco `escopo-*` do
repository não é emitido — não é preciso editar o gerador). Se ligar `tenantKey` num atributo, o
repository passa a importar `com.exemplo.tenant.EscopoTenant` e a chamar `boolean irrestrito()` e
`String exigir(String coluna)` — escreva essa classe no seu projeto, ou troque o `import` em
`quarkus-repository.mi` (pattern `escopo-import`).

## Como rodar

**Rode a partir da pasta do pack, não de `exemplo/`.** Os caminhos `#` de um mapa são relativos à pasta
onde se fez o `mi init` (a *home* do projeto), e o `mi push` só envia o que está dentro dela — por isso o
`main.mi` aponta `quarkus-domain.mi` e `exemplo/dominio/Pedido.mi`, e por isso `../` não funciona.

```sh
cd plugins/iadd/packs/quarkus
mi init exemplo-quarkus exemplo/main.mi     # uma vez; o nome do projeto é sugestão
mi push exemplo-quarkus                     # publica na sua conta — envia, não valida

mi generate exemplo-quarkus quarkus domain modelName=Pedido package=com.exemplo.domain.loja
```

> `mi push` **publica na sua conta em nuvem** tudo o que está sob a pasta do pack (geradores, este
> README, o exemplo). É rotina do fluxo, mas é uma ação externa.

O `package` segue a convenção do pack, `<raiz>.domain.<contexto>`: `com.exemplo.domain.loja` gera em
`com.exemplo.loja.{domain,entity,builder,repository,mapper,resource}`, e as classes de suporte ficam na
raiz, `com.exemplo.{exceptions,results}`.

### Gerar a pilha inteira

Seis sub-geradores × quatro entidades, mais o OpenAPI do pacote:

```sh
PKG=com.exemplo.domain.loja
OUT=<seu-projeto-maven>/src/main/java/com/exemplo/loja
for sub in domain entity builder repository mapper resource; do mkdir -p $OUT/$sub; done
for e in Cliente Fornecedor Pedido ItemPedido; do
  mi generate exemplo-quarkus quarkus domain     modelName=$e package=$PKG > $OUT/domain/$e.java
  mi generate exemplo-quarkus quarkus entity     modelName=$e package=$PKG > $OUT/entity/${e}Entity.java
  mi generate exemplo-quarkus quarkus builder    modelName=$e package=$PKG > $OUT/builder/${e}EntityBuilder.java
  mi generate exemplo-quarkus quarkus repository modelName=$e package=$PKG > $OUT/repository/${e}Repository.java
  mi generate exemplo-quarkus quarkus mapper     modelName=$e package=$PKG > $OUT/mapper/${e}Mapper.java
  mi generate exemplo-quarkus quarkus resource   modelName=$e package=$PKG > $OUT/resource/${e}Resource.java
done
mi generate exemplo-quarkus swagger restAPI packageName=$PKG > loja.yaml

# mi generate devolve 0 mesmo quando falha, e escreve o erro DENTRO do arquivo de saída:
if grep -rl 'EMI[0-9]\{4\}' $OUT loja.yaml; then echo "falhou a geração"; exit 1; fi
```

### O projeto Maven que compila a saída

O código gerado depende de três classes que **não são geradas** e que você escreve uma vez:

```java
// com/exemplo/exceptions/NotFoundException.java
package com.exemplo.exceptions;
public class NotFoundException extends jakarta.ws.rs.WebApplicationException {
    public NotFoundException(String message) { super(message, 404); }
}

// com/exemplo/exceptions/InvalidInputException.java
package com.exemplo.exceptions;
public class InvalidInputException extends jakarta.ws.rs.WebApplicationException {
    public InvalidInputException(String message) { super(message, 400); }
    public InvalidInputException(String message, Throwable cause) { super(message, cause, 400); }
}

// com/exemplo/results/CountResult.java
package com.exemplo.results;
public class CountResult {
    private long count;
    public long getCount() { return count; }
    public void setCount(long count) { this.count = count; }
}
```

E de um `pom.xml` Quarkus 3 (Java 17) com o BOM `io.quarkus.platform:quarkus-bom` e estas extensões:

| Extensão | Por quê |
|---|---|
| `quarkus-hibernate-orm-panache` | entity + repository (`PanacheRepositoryBase`, Criteria) |
| `quarkus-rest-jackson` | resource (JAX-RS) e `@JsonFormat`/`@JsonIgnore` do domain |
| `quarkus-hibernate-validator` | `@NotNull`/`@NotEmpty`/`@Size` do domain |
| `quarkus-smallrye-jwt` | o resource injeta `JsonWebToken` |
| `quarkus-jdbc-<banco>` | só para **subir** a aplicação, não para compilar |

Para compilar basta isso. Para **subir** a aplicação, o JWT exige uma chave pública
(`mp.jwt.verify.publickey.location`) e o datasource um banco.

## Saída — verificada

Verificado em 2026-09-25 com mi 1.0.9, Java 17.0.8, Maven 3.9.7 e Quarkus 3.15.5: `mi push`
(`Map structure pushed!`), 24 arquivos Java + 1 YAML gerados, nenhum `@TODO`, nenhum `EMI`.

```
$ mvn -B clean compile
[INFO] Compiling 27 source files with javac [debug release 17] to target/classes
[INFO] BUILD SUCCESS
```

(27 = 24 gerados + as 3 classes de suporte.) `mvn package` com o `quarkus-maven-plugin` também passa, e
a aplicação sobe com H2 em memória.

Um trecho de `PedidoEntity.java`:

```java
@Entity
@Table(name = "PEDIDO")
public class PedidoEntity {
    @Version
    @Column(name="VERSION")
    private LocalDateTime version;
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "ID", updatable = false, nullable = false, length = 36)
    private String id;
    ...
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name="CLIENTE_ID", nullable = true)
    private ClienteEntity cliente;

    @OneToMany(mappedBy="pedido", fetch = FetchType.LAZY)
    private List<ItemPedidoEntity> itens;
```

## O que o mapa precisou ter além do README de contrato

Cada item abaixo custou uma volta de gerar–compilar–ler. Estão no mapa, comentados aqui:

- **`id: Texto(36)` declarado em toda entidade.** O entity emite `@Id` + `GenerationType.UUID` a partir
  dele, com o `length` tirado do parâmetro do tipo.
- **`cn` também nas relações** (`[r]`, `[m]`) — sem ele sai `@JoinColumn(name="")`, que compila.
- **Tamanho explícito em `Inteiro(n)` e `InteiroLongo(n)`.** Sem ele o `swagger/restAPI` aborta com
  `EMI9005 … mi:replicate()` (o `domain`/`entity` não se importam).
- **Nada de `:` em `description` de pacote** — o OpenAPI a emite sem aspas, e o YAML quebra.
- **A classe `CurrentSchema`**, com `projectNames/projectName`, `host` e `tokenUrl` — sem ela o título,
  o host e o tokenUrl do OpenAPI saem vazios.

## Limites conhecidos (do pack, não do exemplo)

- **Referência só com `{ "id": … }` não resolve**: `isAnyNotKeyFieldsDefined()` conta o próprio `id`,
  então o objeto nunca é tratado como referência fraca, e o Hibernate recusa a entidade destacada sem
  `version`. Enviar o objeto referenciado completo (com `version`) funciona.
- **`required` não é imposto** na entrada: o domain tem `@NotEmpty`/`@NotNull`, mas o resource não usa
  `@Valid`.
- **`nondeterministicSearchField` usa `unaccent()`** do PostgreSQL na busca com `*` — em outro banco
  essa busca dá erro de SQL.
- **`values` (enum) não vira `enum` Java** nem validação — o campo é `String`. No OpenAPI, a lista de
  valores só é emitida para enum de tipo `Integer`.
- No OpenAPI, `TextoLongo` sai como referência (`IdReference`) e a lista `itens` aponta para
  `#/definitions/ItemPedido`, mas a definição se chama `loja.ItemPedido`.
