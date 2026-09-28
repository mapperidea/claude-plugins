#!/usr/bin/env bash
# test-i3-disclosure.sh — a skill mapperidea carrega sob demanda, e continua carregando.
#
# Ela era um arquivo de 1627 linhas: ~24,4k tokens TODA vez que fosse invocada,
# mesmo para "valide esta sintaxe". Agora é um núcleo que roteia (~2,6k) e
# referências lidas conforme a tarefa.
#
# O que este gate protege: o orçamento do núcleo, e a integridade do roteamento --
# referência órfã (existe e ninguém aponta) ou quebrada (apontada e não existe)
# são as duas formas de a divisão apodrecer.
set -uo pipefail
IADD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S="$IADD_ROOT/skills/mapperidea/SKILL.md"
R="$IADD_ROOT/skills/mapperidea/references"
LIMITE=200
PASS=0; FAIL=0
ok(){ echo "  PASS  $1"; PASS=$((PASS+1)); }
bad(){ echo "  FAIL  $1"; FAIL=$((FAIL+1)); }

echo
echo "── Orçamento do núcleo ──────────────────────────────────────────────"
n=$(wc -l < "$S")
[ "$n" -le "$LIMITE" ] && ok "SKILL.md tem $n linhas (teto $LIMITE)" \
                       || bad "SKILL.md inchou: $n linhas (teto $LIMITE) — mova conteúdo para references/"

echo
echo "── Roteamento íntegro ───────────────────────────────────────────────"
for f in "$R"/*.md; do
  b=$(basename "$f")
  grep -q "references/$b" "$S" && ok "$b é apontado pelo núcleo" \
                               || bad "$b é órfão — existe e o núcleo não aponta"
done
for b in $(grep -oE 'references/[a-z-]+\.md' "$S" | sort -u | xargs -n1 basename); do
  [ -f "$R/$b" ] && ok "referência $b existe" || bad "núcleo aponta para $b, que não existe"
done

echo
echo "── O que não pode sair do núcleo ────────────────────────────────────"
grep -q 'Onde está cada coisa'        "$S" && ok "tem a tabela de roteamento"      || bad "perdeu a tabela de roteamento"
grep -q 'Como Responder a Pedidos'    "$S" && ok "tem o dispatcher de tarefas"     || bad "perdeu o dispatcher"
grep -q 'Ícones — o essencial'        "$S" && ok "tem o resumo de ícones"          || bad "perdeu o resumo de ícones"
grep -q 'Descriptor.window.editor'    "$S" && ok "lembra que tela não tem atalho"  || bad "perdeu a exceção dos estereótipos de tela"

echo
echo "════════════════════════════════════════════════"
printf '  I3 Results: %d passed · %d failed · 0 skipped\n' "$PASS" "$FAIL"
echo "════════════════════════════════════════════════"
[ "$FAIL" -eq 0 ]
