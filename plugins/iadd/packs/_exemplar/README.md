# Pack exemplar — o menor gerador completo que existe

Este não é um pack de stack: é o **material didático** do kit. Ele existe para ser lido junto do
[guia de autoria de geradores](../../references/generator-authoring-guide.md), e para ser o esqueleto que
você copia quando for começar um pack de verdade.

Os packs reais são bons de copiar e ruins de aprender, porque começam grandes. Este começa pequeno de
propósito: **um gerador, um alvo trivial, e um exemplar de cada forma que o DOM pode ter**.

## O que tem aqui

```
main.mi                      mapa principal: config/maps (famílias de tipo) + registro dos geradores
dominio/Pedido.mi            a entidade de prova — carrega uma de cada forma (ver abaixo)
dominio/ItemPedido.mi        o detalhe, lado [m] da relação forte
dominio/Cliente.mi           a entidade referenciada, lado [r]
generators/ts-type.mi        o gerador exemplar: uma interface TypeScript por entidade
generators/struct.mi         o microscópio — despeja o DOM normalizado em XML
```

`Pedido` foi desenhado para que **todo ramo do dispatch seja exercitado por uma entidade só**:

| Forma | Atributo |
|---|---|
| escalar obrigatório | `numero: Texto(20)` + `required` |
| escalar opcional | `observacao: TextoLongo()` |
| numérico / monetário | `total: ValorMonetario()` |
| enum | `situacao: Texto(20)` com bloco `values` |
| data | `dataEmissao: Data()`, `dataCriacao: DataHora()` |
| booleano | `ativo: Boolean()` |
| referência (`[r]`) | `cliente: Cliente()` |
| relação fraca (`[o]`/`[m]`) | `itens: ItemPedido()` ↔ `ItemPedido.pedido` |

## Como rodar

```sh
cd plugins/iadd/packs/_exemplar
mi init exemplar main.mi          # uma vez — cria/vincula o projeto na sua conta
mi push exemplar                  # valida (é o ÚNICO validador real)

# olhe o DOM antes de mexer em qualquer gerador
mi generate exemplar struct xml className=Pedido packageName=com.exemplo.dominio > /tmp/pedido.xml

# gere
mi generate exemplar typescript type modelName=Pedido package=com.exemplo.dominio
```

> `mi push` **publica os mapas na sua conta em nuvem** — é rotina do fluxo, mas é uma ação externa.
> O nome `exemplar` do projeto é sugestão; use outro se colidir com algo seu.

## Saída — verificada

Validado em 17/09/2026: `mi init` + `mi push` (`Map structure pushed!`) + `generate` nas três entidades.

```ts
// GERADO por: mi generate exemplar typescript type modelName=Pedido
// Nao editar a mao — a saida e sobrescrita por inteiro a cada geracao.

export interface Pedido {
  id: string
  numero: string
  observacao?: string
  total: number
  situacao: "RASCUNHO" | "CONFIRMADO" | "CANCELADO"
  dataEmissao: string
  ativo?: boolean
  dataCriacao?: string
  cliente: Cliente
  itens?: ItemPedido[]
}
```

`tsc --noEmit --strict` passa sobre a concatenação dos três arquivos gerados. São concatenados porque o
exemplar **não emite `import`** de propósito — resolver dependência entre arquivos é uma boa segunda
funcionalidade para você acrescentar quando estiver adaptando este gerador.

### Dois fatos que só o DOM respondeu

- **`[r] cliente` normaliza como `oneToOne`** (não `manyToOne`). O gerador trata os dois, mas era suposição
  até o `struct` dizer. É o caso de uso do microscópio em uma linha.
- **Um `[v]` vazio não emite linha em branco — não emite nada.** O nó sem texto some na normalização, mesmo
  num pattern dedicado só para isso. Para emitir uma linha em branco use `[v] {{ '' }}`, que é o que o
  pattern `blankLine` deste gerador faz. Vale tanto para o `[v]` solto dentro de um pattern quanto para o
  pattern inteiro.

## O que você provavelmente vai querer mudar aqui

- **O alvo.** Trocar TypeScript por Java, C#, SQL ou ADVPL/TLPP mexe **só nos `patterns`**. O `start`, o
  dispatch e o catch-all ficam iguais — é essa a demonstração.
- **As famílias de tipo** no `main.mi`: o `mapNativeTypes` daqui é mínimo. O seu cresce com os sinônimos que
  o seu modelo usa — **lá**, nunca nos templates.
- **A unidade de geração**: um arquivo por classe é o começo; manifesto único ou um arquivo por pacote são
  variações do `start match`.
- **O domínio**: `Pedido`/`ItemPedido`/`Cliente` não têm nada de especial além de cobrir as formas. Se você
  trocar por entidades suas, mantenha a cobertura da tabela acima — é ela que torna o exemplar um teste.
