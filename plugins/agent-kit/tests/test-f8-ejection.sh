#!/usr/bin/env bash
# test-f8-ejection.sh — o que é COPIADO para o projeto do usuário não pode
# apontar para dentro do kit.
#
# A regra: ${CLAUDE_PLUGIN_ROOT} e caminhos do kit são legítimos DENTRO do kit
# (skills, docs, scripts do próprio plugin) e proibidos em tudo que é copiado
# (arquétipos, templates), porque o agente gerado tem de continuar funcionando
# depois que o plugin for desinstalado.
set -uo pipefail
KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IADD_ROOT="$(cd "$KIT_ROOT/../iadd" 2>/dev/null && pwd || true)"
PASS=0; FAIL=0

deny() { # <rótulo> <diretório> <regex proibida>
  local label="$1" dir="$2" re="$3"
  [ -d "$dir" ] || { echo "  SKIP  $label — $dir não existe"; return; }
  local hits
  # README.md de uma pasta é documentação DO KIT — não é copiado para o projeto
  # do usuário, então pode citar caminhos do kit à vontade.
  hits=$(grep -rlE --exclude='README.md' "$re" "$dir" 2>/dev/null || true)
  if [ -z "$hits" ]; then echo "  PASS  $label"; PASS=$((PASS+1))
  else echo "  FAIL  $label — encontrado em:"; echo "$hits" | sed 's/^/          /'; FAIL=$((FAIL+1)); fi
}

echo
echo "── Regra de ejeção: nada do kit dentro do que é copiado ──────────────"
deny "arquétipos do agent-kit sem CLAUDE_PLUGIN_ROOT" "$KIT_ROOT/archetypes"  'CLAUDE_PLUGIN_ROOT'
deny "templates sem CLAUDE_PLUGIN_ROOT"               "$KIT_ROOT/templates"   'CLAUDE_PLUGIN_ROOT'
deny "arquétipos do agent-kit sem caminho do kit"     "$KIT_ROOT/archetypes"  '(plugins/(agent-kit|iadd)/|mapperidea-iadd/)'
deny "templates sem caminho do kit"                   "$KIT_ROOT/templates"   '(plugins/(agent-kit|iadd)/|mapperidea-iadd/)'
if [ -n "$IADD_ROOT" ]; then
  deny "arquétipos do iadd sem CLAUDE_PLUGIN_ROOT"    "$IADD_ROOT/archetypes" 'CLAUDE_PLUGIN_ROOT'
  deny "arquétipos do iadd sem caminho do kit"        "$IADD_ROOT/archetypes" '(plugins/(agent-kit|iadd)/|mapperidea-iadd/)'
fi

echo
echo "── O hook que o wizard propõe é relativo ao PROJETO ──────────────────"
if grep -qE 'command: "scripts/check-write-path\.sh' "$KIT_ROOT/skills/agent-creator/references/helpers.md" 2>/dev/null; then
  echo "  PASS  hook proposto usa caminho relativo ao projeto"; PASS=$((PASS+1))
else
  echo "  FAIL  hook proposto não usa mais 'scripts/check-write-path.sh' relativo"; FAIL=$((FAIL+1))
fi

echo
echo "════════════════════════════════════════════════"
printf '  F8 Results: %d passed · %d failed · 0 skipped\n' "$PASS" "$FAIL"
echo "════════════════════════════════════════════════"
[ "$FAIL" -eq 0 ]
