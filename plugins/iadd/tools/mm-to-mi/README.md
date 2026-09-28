# `mm-to-mi` — a porta de entrada da base instalada

Converte mapas FreeMind (`.mm`) em mapas Mapper Idea (`.mi`), em lote, preservando a árvore de pastas e
**relatando o que não soube converter**.

Quem já usa Mapper Idea tem domínio modelado há anos em `.mm`. Sem esta ferramenta, entrar em IADD
significa remodelar do zero — a parede que a maioria não atravessa. Com ela, é um comando.

```sh
./convert.sh <origem> <destino> [--strict]
```

- `<origem>` — arquivo `.mm` ou diretório (varrido recursivamente)
- `<destino>` — diretório de saída; a estrutura de pastas da origem é preservada
- `--strict` — sai com código 1 se algum ícone não mapeado for encontrado (útil em CI)

Requer `xsltproc` (Debian/Ubuntu: `apt install xsltproc`).

## O que você recebe

```
Convertidos: 7 arquivo(s), 0 falha(s)  →  /tmp/saida

  smpl.bi.mm                     2037 →     455  (-77%)
  smpl.customizer.mm             7420 →    4428  (-40%)  ⚠ 1 ícone(s)
  …
  TOTAL                       1310570 →  616009  (-52%)

⚠  ÍCONES NÃO MAPEADOS (18) — passaram CRUS para o .mi, em silêncio.
  smpl.customizer.mm
      Field.public
  …
```

Duas coisas de uma vez:

1. **A redução** — ~53% em bytes sobre material real. Em tokens tende a ser maior: XML tokeniza pior que
   texto indentado, e o `.mm` carrega *bookkeeping* de editor (`CREATED`, `STYLE`, `map_styles`) que é
   ruído puro para a IA.
2. **O relatório de ícones** — o que a conversão manual perdia. Ícone desconhecido **não falha**: o nome
   cru vira o atalho (`[Field.public] currentUser: ThreadLocal()`), e o `.mi` parece bom. Ver
   [`icon-table.md`](icon-table.md).

## Qual dos mapas convertidos é o principal

Ele não se identifica pelo nome nem pelo tamanho — **o maior mapa raramente é o principal**. Identifica-se
pela estrutura: o principal é o que carrega o bloco `config` e, dentro dele, o nó `mapperidea`.

```sh
grep -rl 'TEXT="mapperidea"' --include='*.mm' <origem>     # antes de converter
grep -rlE '(^|[] ])mapperidea\b' --include='*.mi' <destino>  # depois
```

Isso importa porque é o mapa principal que vai no `mi init <projeto> <mapa>` — e apontar para o mapa
errado ali produz um projeto que sobe sem os geradores e sem o dicionário de tipos.

## A conversão não termina aqui

O `.mi` gerado é uma hipótese até o CLI dizer o contrário:

```sh
mi push <projeto>                                                  # o único validador real
mi generate <projeto> struct xml className=<C> packageName=<p>     # confira o @mode no DOM
```

O `@mode` real **pode divergir** do que o ícone do FreeMind sugere — armadilha conhecida, e o motivo de o
passo de `struct` estar no fim de cada execução do script. Ver [o pipeline](../../docs/pipeline-iadd.md) §1.
