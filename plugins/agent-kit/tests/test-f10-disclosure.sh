#!/usr/bin/env bash
# test-f10-disclosure.sh — o wizard carrega cada fase sob demanda, e continua carregando.
#
# Ele era um arquivo de 1559 linhas, carregado inteiro a cada invocação. Agora é um
# núcleo que guarda o FLUXO e manda ler a referência ao entrar em cada fase — a
# diferença para uma skill de referência é que aqui a ordem importa, então o núcleo
# não pode perder o roteiro nem as regras transversais.
#
# O que este gate protege: o orçamento do núcleo, e a integridade do roteamento --
# referência órfã (existe e ninguém aponta) ou quebrada (apontada e não existe)
# são as duas formas de a divisão apodrecer.
set -uo pipefail
KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S="$KIT_ROOT/skills/agent-creator/SKILL.md"
R="$KIT_ROOT/skills/agent-creator/references"
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
for b in $(grep -oE 'references/[a-z0-9-]+\.md' "$S" | sort -u | xargs -n1 basename); do
  # transversal do plugin, fora da pasta da skill
  [ "$b" = "agent-authoring-conventions.md" ] && { [ -f "$KIT_ROOT/references/$b" ] \
      && ok "referência transversal $b existe" || bad "aponta para $b, que não existe"; continue; }
  [ -f "$R/$b" ] && ok "referência $b existe" || bad "núcleo aponta para $b, que não existe"
done

echo
echo "── O que não pode sair do núcleo ────────────────────────────────────"
grep -q 'leia a referência de cada fase' "$S" && ok "tem o roteiro das fases"        || bad "perdeu o roteiro das fases"
grep -q 'Step 0'                         "$S" && ok "mantém o parse de argumentos"   || bad "perdeu o Step 0"
grep -q 'Só o Tier E pula'               "$S" && ok "regra do Tier D no núcleo"      || bad "a regra do Tier D saiu do núcleo"
grep -q 'CLAUDE_PLUGIN_ROOT'             "$S" && ok "aponta helpers e convenções"    || bad "perdeu as referências transversais"
grep -q 'Uma mensagem por fase'          "$S" && ok "regra de uma pergunta por fase" || bad "perdeu a regra de agrupar perguntas"
grep -q 'Não construa do zero o que o kit já tem' "$S" && ok "manda reusar arquétipo/template" || bad "perdeu a regra de não construir do zero"
for f in enrich busca-conhecimento orquestrador fase1b-partir-de-pronto; do
  grep -q "references/$f.md" "$S" && ok "roteia o fluxo $f" || bad "não roteia o fluxo $f"
done

echo
echo "── O catálogo é o README: ele precisa estar completo ────────────────"
# A Fase 1b casa o propósito do usuário contra os READMEs de archetypes/ e
# templates/, em vez de manter uma lista dentro da skill. O preço disso é que um
# arquétipo fora do README fica INVISÍVEL para o wizard — existe e nunca é oferecido.
for d in archetypes templates; do
  for f in "$KIT_ROOT/$d"/*.md; do
    b=$(basename "$f" .md)
    [ "$b" = "README" ] && continue
    grep -qF "$b.md" "$KIT_ROOT/$d/README.md" \
      && ok "$d/$b está no catálogo" \
      || bad "$d/$b existe e NÃO está no README — o wizard nunca vai oferecê-lo"
  done
done

echo
echo "════════════════════════════════════════════════"
printf '  F10 Results: %d passed · %d failed · 0 skipped\n' "$PASS" "$FAIL"
echo "════════════════════════════════════════════════"
[ "$FAIL" -eq 0 ]
