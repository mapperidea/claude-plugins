#!/usr/bin/env bash
# test-i4-mm-to-mi-links.sh — o conversor reescreve os links entre mapas para .mi.
#
# Antes, o .mi convertido continuava apontando `window.mm`. Resolvia no servidor, mas o mapa
# mentia sobre os próprios arquivos — e quem lê o mapa, pessoa ou IA, procura um .mm que não
# existe mais. Link de mapa (.mm local) vira .mi; o resto (URL, outros arquivos) passa como está.
set -uo pipefail
IADD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
XSL="$IADD_ROOT/tools/mm-to-mi/exportMI.xsl"
PASS=0; FAIL=0; SKIP=0
ok(){ echo "  PASS  $1"; PASS=$((PASS+1)); }
bad(){ echo "  FAIL  $1"; FAIL=$((FAIL+1)); }

echo
echo "── Links entre mapas ────────────────────────────────────────────────"
if ! command -v xsltproc >/dev/null; then
  echo "  SKIP  xsltproc ausente"; SKIP=1
else
  MM="$(mktemp)"; trap 'rm -f "$MM"' EXIT
  cat > "$MM" <<'EOF'
<map version="1.0.1"><node TEXT="com.exemplo">
<node TEXT="a" LINK="dominio/Pedido.mm"/>
<node TEXT="b" LINK="window.mm"/>
<node TEXT="c" LINK="https://exemplo.com/mapa.mm"/>
<node TEXT="d" LINK="generators/struct.xsl"/>
<node TEXT="e" LINK="x.mmx"/>
</node></map>
EOF
  out="$(xsltproc "$XSL" "$MM" | sed 's/§/ /g')"
  check(){ printf '%s\n' "$out" | grep -qxE "\s*$2" && ok "$1" || bad "$1 — esperado '$2'"; }
  check "link relativo .mm vira .mi"         'dominio/Pedido\.mi'
  check "link na mesma pasta .mm vira .mi"   'window\.mi'
  check "URL passa como está"                'https://exemplo\.com/mapa\.mm'
  check "link que não é mapa passa"          'generators/struct\.xsl'
  check "só a extensão exata .mm muda"       'x\.mmx'
  printf '%s\n' "$out" | grep -qE '^\s*(dominio/Pedido|window)\.mm$' \
    && bad "sobrou link .mm local" || ok "nenhum link .mm local sobrou"
fi

echo
echo "════════════════════════════════════════════════"
printf '  I4 Results: %d passed · %d failed · %d skipped\n' "$PASS" "$FAIL" "$SKIP"
echo "════════════════════════════════════════════════"
[ "$FAIL" -eq 0 ]
