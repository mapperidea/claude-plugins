#!/usr/bin/env bash
# convert.sh — converte mapas FreeMind (.mm) em mapas Mapper Idea (.mi), em lote.
#
#   ./convert.sh <origem> <destino> [--strict]
#
# <origem>   arquivo .mm ou diretório (varre recursivamente)
# <destino>  diretório de saída; a árvore de pastas da origem é preservada
# --strict   sai com código 1 se algum ícone não mapeado for encontrado
#
# A conversão NÃO termina aqui: valide o resultado com `mi push` e inspecione o DOM
# com o gerador `struct` antes de confiar no .mi. Ver ../../docs/pipeline-iadd.md §1.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XSL="$SCRIPT_DIR/exportMI.xsl"

die() { printf 'erro: %s\n' "$*" >&2; exit 2; }

[ $# -ge 2 ] || die "uso: $0 <origem> <destino> [--strict]"
SRC="$1"; DEST="$2"; STRICT="${3:-}"

command -v xsltproc >/dev/null || die "xsltproc não encontrado (Debian/Ubuntu: apt install xsltproc)"
[ -f "$XSL" ] || die "folha de estilo não encontrada: $XSL"
[ -e "$SRC" ] || die "origem não existe: $SRC"

# Os ícones conhecidos são lidos da PRÓPRIA folha de estilo, para que a tabela e o
# código não divirjam. Ver icon-table.md.
KNOWN_ICONS="$(grep -o "\$iconName = '[^']*'" "$XSL" | sed "s/.*'\(.*\)'/\1/" | sort -u)"

# Famílias que passam CRUS de propósito: o nome completo do ícone É o atalho no .mi.
# Os estereótipos de tela são assim — `[Descriptor.window.editor]` é a forma correta,
# e vira mode="window.editor" na normalização. Não são ícones desconhecidos.
PASSTHROUGH='^Descriptor\.window\.'


if [ -d "$SRC" ]; then
  SRC_ROOT="${SRC%/}"
  mapfile -t FILES < <(find "$SRC_ROOT" -type f -name '*.mm' | sort)
else
  SRC_ROOT="$(dirname "$SRC")"
  FILES=("$SRC")
fi
[ "${#FILES[@]}" -gt 0 ] || die "nenhum arquivo .mm encontrado em: $SRC"

total_in=0; total_out=0; unmapped_total=0; converted=0; failed=0
report_rows=""; unmapped_report=""; pass_report=""

for f in "${FILES[@]}"; do
  rel="${f#"$SRC_ROOT"/}"
  out="$DEST/${rel%.mm}.mi"
  mkdir -p "$(dirname "$out")"

  if ! xsltproc "$XSL" "$f" 2>/tmp/mm2mi-err.$$ | sed 's/§/ /g' > "$out"; then
    printf '  FALHOU  %s\n' "$rel" >&2
    sed 's/^/          /' /tmp/mm2mi-err.$$ >&2
    failed=$((failed+1)); rm -f /tmp/mm2mi-err.$$; continue
  fi
  rm -f /tmp/mm2mi-err.$$

  in_b=$(wc -c < "$f"); out_b=$(wc -c < "$out")
  total_in=$((total_in+in_b)); total_out=$((total_out+out_b)); converted=$((converted+1))
  pct=$(( in_b > 0 ? (in_b - out_b) * 100 / in_b : 0 ))

  # Ícones do .mm que a folha de estilo não conhece: passam CRUS para o .mi, em silêncio.
  # Este é o achado que a conversão manual perdia.
  used="$(grep -o 'BUILTIN="[^"]*"' "$f" | sed 's/BUILTIN="\(.*\)"/\1/' | sort -u)"
  unmapped="$(comm -23 <(printf '%s\n' "$used" | grep -v '^$' || true) <(printf '%s\n' "$KNOWN_ICONS") \
              | grep -vE "$PASSTHROUGH" || true)"
  passthrough="$(printf '%s\n' "$used" | grep -E "$PASSTHROUGH" || true)"
  n_pass=$(printf '%s\n' "$passthrough" | grep -c . || true)
  [ "$n_pass" -gt 0 ] && pass_report+="  $rel"$'\n'"$(printf '%s\n' "$passthrough" | sed 's/^/      /')"$'\n' 
  n_unmapped=$(printf '%s\n' "$unmapped" | grep -c . || true)

  report_rows+="$(printf '  %-44s %9d → %9d  (-%2d%%)  %s\n' \
      "$rel" "$in_b" "$out_b" "$pct" \
      "$([ "$n_unmapped" -gt 0 ] && echo "⚠ $n_unmapped ícone(s)" || echo '')")"$'\n'

  if [ "$n_unmapped" -gt 0 ]; then
    unmapped_total=$((unmapped_total+n_unmapped))
    unmapped_report+="  $rel"$'\n'
    unmapped_report+="$(printf '%s\n' "$unmapped" | sed 's/^/      /')"$'\n'
  fi
done

echo
echo "Convertidos: $converted arquivo(s)${failed:+, $failed falha(s)}  →  $DEST"
echo
printf '%s' "$report_rows"
if [ "$total_in" -gt 0 ]; then
  echo
  printf '  %-44s %9d → %9d  (-%2d%%)\n' "TOTAL" "$total_in" "$total_out" \
      $(( (total_in - total_out) * 100 / total_in ))
fi

if [ "$unmapped_total" -gt 0 ]; then
  cat <<EOF

⚠  ÍCONES NÃO MAPEADOS ($unmapped_total) — passaram CRUS para o .mi, em silêncio.
   O nome do ícone do FreeMind virou o "atalho" entre colchetes, e o mapa NÃO vai
   normalizar como você espera. Adicione cada um ao xsl:choose de exportMI.xsl
   (e à tabela em icon-table.md) e converta de novo.

EOF
  printf '%s' "$unmapped_report"
fi

if [ -n "$pass_report" ]; then
  cat <<EOF

ℹ  ÍCONES QUE PASSAM CRUS POR DESIGN — o nome completo É o atalho no .mi.
   Estereótipos de tela: [Descriptor.window.editor] vira mode="window.editor" na
   normalização. Não há nada a corrigir aqui.

EOF
  printf '%s' "$pass_report"
fi

cat <<EOF

Próximo passo — a conversão não termina aqui:
  mi push <projeto>                                       # o único validador real
  mi generate <projeto> struct xml className=<C> packageName=<p>   # confira o @mode no DOM
EOF

[ "$failed" -gt 0 ] && exit 2
[ "$STRICT" = "--strict" ] && [ "$unmapped_total" -gt 0 ] && exit 1
exit 0
