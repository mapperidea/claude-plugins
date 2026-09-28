#!/usr/bin/env bash
# test-i1-archetype-method.sh — o método da tríade sobreviveu à subtração?
#
# Mesmo gate do F7 do agent-kit, aplicado aos arquétipos do IADD: fixa as
# afirmações de método que não podem sumir numa edição futura.
set -uo pipefail
IADD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
A="$IADD_ROOT/archetypes"
PASS=0; FAIL=0

check() { # <arquivo> <rótulo> <regex>
  local f="$1" label="$2" re="$3"
  if tr -s '[:space:]' ' ' < "$A/$f" 2>/dev/null | grep -qiE "$re"; then
    echo "  PASS  $f — $label"; PASS=$((PASS+1))
  else echo "  FAIL  $f — $label (não encontrado: $re)"; FAIL=$((FAIL+1)); fi
}
header() { echo; echo "── $1 ──────────────────────────────────────────"; }

header "Comum à tríade"
for f in domain-mapper.md generator-author.md cli-runner.md; do
  check "$f" "tabela da tríade com fronteiras"  'A tríade \(fronteiras duras\)|par operacional'
  check "$f" "uma pergunta objetiva"            '\*\*uma\*\* (pergunta|vez)'
  check "$f" "seção de incerteza"               '## Diante de incerteza'
  check "$f" "o que vai querer mudar aqui"      'O que você provavelmente vai querer mudar aqui'
  check "$f" "separa método do resto"           '\*\*O que é método\*\*'
done

header "domain-mapper"
check domain-mapper.md "ordem por bounded context"       'do mais independente para o mais dependente'
check domain-mapper.md "critério de relacionamento"      'deletar A implica deletar B'
check domain-mapper.md "cross-context sempre \[r\]"      'nunca .{0,3}m.{0,3}/.{0,3}o.{0,3} cross-context'
check domain-mapper.md "tipos de negócio, não técnicos"  'nunca tipos técnicos'
check domain-mapper.md "checklist antes de salvar"       'antes de salvar'
check domain-mapper.md "não roda CLI"                    'Não executar comandos shell'
check domain-mapper.md "nunca adivinhar em silêncio"     'adivinhe em silêncio'

header "generator-author"
check generator-author.md "aponta para o guia"           'generator-authoring-guide'
check generator-author.md "struct-first"                 'struct-first'
check generator-author.md "dispatch por dicionário"      'nunca por literal de tipo|Nunca hardcodar'
check generator-author.md "TODO-on-unhandled"            'TODO-on-unhandled'
check generator-author.md "não edita mapa de negócio"    'Nunca editar mapa de negócio'
check generator-author.md "não opera o CLI"              'Nunca operar o CLI'
check generator-author.md "saída sobrescrita por inteiro" 'sobrescrita por inteiro'
check generator-author.md "varre a correção nas irmãs"   'varrer as irmãs'
check generator-author.md "saída vazia não é 'nada a gerar'" 'não conclua que'

header "cli-runner"
check cli-runner.md "detecta o HOME, não fixa"           'Nunca fixe o caminho'
check cli-runner.md "reinterpreta erro de autorização"   'Error loading authorization'
check cli-runner.md "push é o único validador"           'único.{0,3} meio de validação real'
check cli-runner.md "grep não é validação"               'não é validação'
check cli-runner.md "cadência init/push/generate"        'push.{0,40}antes de.{0,40}generate|a cada alteração'
check cli-runner.md "não escreve .mi"                    'Não edite nem crie arquivos'
check cli-runner.md "nunca roda authorize"               'Não rode .{0,3}authorize'
check cli-runner.md "sabe que push publica"              'publica os mapas na conta'
check cli-runner.md "campo que sumiu é o achado"         'SUMIRAM|sumiu'

echo
echo "════════════════════════════════════════════════"
printf '  I1 Results: %d passed · %d failed · 0 skipped\n' "$PASS" "$FAIL"
echo "════════════════════════════════════════════════"
[ "$FAIL" -eq 0 ]
