#!/usr/bin/env bash
# test-f9-tier-memory.sh — o wizard e a tabela de tiers não podem se contradizer.
#
# Origem: um teste de cliente real rodou o wizard duas vezes no mesmo cenário e
# obteve comportamentos diferentes. A causa era uma contradição interna — a tabela
# de tiers dizia que conhecimento Tier D grava MEMORY.md, e cinco pontos do wizard
# tratavam D como se fosse E (não grava). O sintoma era SILENCIOSO: o agente saía
# com um comentário de tier apontando para um conhecimento que ele não tinha.
#
# A regra: Tier D foi capturado do usuário em conversa e não existe em nenhum outro
# lugar — não gravar é PERDER. Só o Tier E (dados de treino) pula.
set -uo pipefail
KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# A skill é o NÚCLEO + as referências que ele roteia: o conteúdo mudou de arquivo
# na divisão por disclosure progressivo, não deixou de existir. As asserções abaixo
# perguntam "o wizard diz isto?", não "este arquivo diz isto".
SKILL_DIR="$KIT_ROOT/skills/agent-creator"
SKILL="$(mktemp)"; trap 'rm -f "$SKILL"' EXIT
cat "$SKILL_DIR/SKILL.md" "$SKILL_DIR/references"/*.md > "$SKILL"
HELPERS="$KIT_ROOT/skills/agent-creator/references/helpers.md"
PASS=0; FAIL=0

ok()   { echo "  PASS  $1"; PASS=$((PASS+1)); }
bad()  { echo "  FAIL  $1"; FAIL=$((FAIL+1)); }
want() { grep -qE "$2" "$3" && ok "$1" || bad "$1 (esperado: $2)"; }
deny() { grep -qE "$2" "$3" && bad "$1 (não deveria existir: $2)" || ok "$1"; }

echo
echo "── Tier D grava MEMORY.md; só o Tier E pula ─────────────────────────"
want "helpers: linha do Tier D diz Write"   '^\| D .*Write' "$HELPERS"
want "helpers: linha do Tier E diz Skip"    '^\| E .*Skip'  "$HELPERS"
want "wizard: só o Tier E zera o conteúdo"  'KNOWLEDGE_TIER=E. → set .MEMORY_CONTENT=null' "$SKILL"
deny "wizard: D não é tratado como E"       'KNOWLEDGE_TIER=D. or .E. → set .MEMORY_CONTENT=null' "$SKILL"
deny "wizard: nenhuma decisão de memória exclui D" 'KNOWLEDGE_TIER. is A, B, or C' "$SKILL"
want "wizard: a razão está escrita"         'Tier D writes MEMORY.md' "$SKILL"

echo
echo "── O wizard aplica as convenções do próprio kit ─────────────────────"
want "lê as convenções de autoria"          'references/agent-authoring-conventions\.md' "$SKILL"
want "aplica o checklist antes de mostrar"  'review checklist in .8' "$SKILL"
want "acha o helpers pelo plugin root"      'CLAUDE_PLUGIN_ROOT./skills/agent-creator/references/helpers\.md' "$SKILL"

echo
echo "════════════════════════════════════════════════"
printf '  F9 Results: %d passed · %d failed · 0 skipped\n' "$PASS" "$FAIL"
echo "════════════════════════════════════════════════"
[ "$FAIL" -eq 0 ]
