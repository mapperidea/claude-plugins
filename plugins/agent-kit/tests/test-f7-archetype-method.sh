#!/usr/bin/env bash
# test-f7-archetype-method.sh — o método sobreviveu à subtração?
#
# Um arquétipo nasce de um agente real, do qual se subtraem domínio e fiação.
# O risco dessa operação é levar método junto no corte. Este teste fixa, por
# arquétipo, as afirmações de MÉTODO que precisam continuar lá — e falha se
# alguma sumir numa edição futura.
#
# Não verifica qualidade de redação; verifica presença. É o gate mínimo.
set -uo pipefail
KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
A="$KIT_ROOT/archetypes"
PASS=0; FAIL=0

check() { # <arquivo> <rótulo do método> <regex>
  local f="$1" label="$2" re="$3"
  # achata o arquivo antes de casar: as afirmações de método quebram em várias
  # linhas na formatação, e um grep por linha as perderia (falso negativo).
  if tr -s '[:space:]' ' ' < "$A/$f" 2>/dev/null | grep -qiE "$re"; then echo "  PASS  $f — $label"; PASS=$((PASS+1))
  else echo "  FAIL  $f — $label (não encontrado: $re)"; FAIL=$((FAIL+1)); fi
}
header() { echo; echo "── $1 ──────────────────────────────────────────"; }

header "Método comum a todo arquétipo (das convenções de autoria)"
for f in product-manager.md architecture-reviewer.md board-sync.md test-engineer.md; do
  check "$f" "uma única pergunta de esclarecimento"   'uma.{0,3}\*{0,2} (pergunta|vez)|\*\*uma\*\*'
  check "$f" "seção de incerteza e erros"             '## (Diante de incerteza|Incerteza)'
  check "$f" "seção 'o que você vai querer mudar'"    'O que você provavelmente vai querer mudar aqui'
  check "$f" "separa método de domínio/fiação"        '\*\*O que é método\*\*'
done

header "product-manager — método de produto"
check product-manager.md "INVEST"                        'INVEST'
check product-manager.md "Given/When/Then"               'Given/When/Then'
check product-manager.md "MoSCoW e WSJF"                 'MoSCoW.*WSJF'
check product-manager.md "padrões de split"              'split'
check product-manager.md "proíbe 'como sistema'"         'Como sistema'
check product-manager.md "conflito sinalizado ANTES"     '\*\*antes\*\* de escrever'
check product-manager.md "nunca adivinhar em silêncio"   'adivinhe em silêncio'
check product-manager.md "fonte de verdade relida"       'autoridade viva|releia'

header "architecture-reviewer — método de revisão"
check architecture-reviewer.md "relê autoridade a cada review"  'releia-os a cada review'
check architecture-reviewer.md "divergência É um achado"        'isso é um achado'
check architecture-reviewer.md "verifica na branch base"        'branch base'
check architecture-reviewer.md "verificação empírica"           'Verificar empiricamente|verificar empiricamente'
check architecture-reviewer.md "read-only com exceção única"    'READ-ONLY'
check architecture-reviewer.md "três níveis de veredito"        'BLOQUEIA MERGE.*BLOQUEIA PRODUÇÃO'
check architecture-reviewer.md "dívida assumida ≠ regressão"    'regressão de arquitetura'
check architecture-reviewer.md "achado cita a cláusula"         'cláusula'
check architecture-reviewer.md "decisão de merge é humana"      'decisão é humana'

header "board-sync — método de board"
check board-sync.md "verdade é o código, não o tracker"  'fonte de verdade do STATUS'
check board-sync.md "funil gateado sem atalho"           'sem atalho'
check board-sync.md "concluído é gate humano"            'Concluído é humano|concluído sozinho'
check board-sync.md "evidência no movimento"             'evidência'
check board-sync.md "propõe pessoa, aplica fato"         'proponha, não atribua'
check board-sync.md "não inventa escopo"                 'não invente escopo'
check board-sync.md "contexto sensível não sai"          'Contexto sensível nunca sai'
check board-sync.md "relatório compacto, sem JSON cru"   'JSON cru'
check board-sync.md "degrada sem tracker"                'degradar|degrade'

header "test-engineer — método de teste"
check test-engineer.md "risco técnico × risco de negócio"  'Risco Técnico.*Risco de Negócio'
check test-engineer.md "encontrar defeitos, não confirmar" 'encontrar defeitos'
check test-engineer.md "mapa unidade → técnica"            'valor-limite'
check test-engineer.md "tabela de decisão"                 'tabela de decisão'
check test-engineer.md "transição de estado"               'transição de estado'
check test-engineer.md "oracle definido antes"             'oracle'
check test-engineer.md "válidos E inválidos"               'inválidas'
check test-engineer.md "roda e reporta o real"             'resultado real'
check test-engineer.md "não mexe em produção p/ passar"    'Não alterar código de produção'
check test-engineer.md "teste ruim vs bug real"            'teste ruim de bug real'

echo
echo "════════════════════════════════════════════════"
printf '  F7 Results: %d passed · %d failed · 0 skipped\n' "$PASS" "$FAIL"
echo "════════════════════════════════════════════════"
[ "$FAIL" -eq 0 ]
