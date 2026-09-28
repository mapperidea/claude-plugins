#!/usr/bin/env bash
# test-i2-init-skill.sh — a skill /iadd:init não pode violar as regras que ela existe para aplicar.
#
# Ela instala agentes no projeto do usuário. Os dois jeitos de ela estragar tudo:
# deixar o agente apontando para dentro do plugin (quebra a ejeção) ou operar o
# CLI por conta própria (push publica na conta em nuvem do usuário).
set -uo pipefail
IADD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S="$IADD_ROOT/skills/init/SKILL.md"
PASS=0; FAIL=0
flat() { sed 's/^[[:space:]]*> \?//' "$S" | tr -s '[:space:]' ' '; }
want() { if flat | grep -qiE -e "$2"; then echo "  PASS  $1"; PASS=$((PASS+1)); else echo "  FAIL  $1 (esperado: $2)"; FAIL=$((FAIL+1)); fi; }
# para textos que contêm chaves duplas, casar literal — {{ em ERE é inferno de escape
wantF() { if flat | grep -qiF -e "$2"; then echo "  PASS  $1"; PASS=$((PASS+1)); else echo "  FAIL  $1 (esperado literal: $2)"; FAIL=$((FAIL+1)); fi; }

echo
echo "── A skill existe e é invocável ─────────────────────────────────────"
if [ -f "$S" ]; then echo "  PASS  skills/init/SKILL.md existe"; PASS=$((PASS+1));
else echo "  FAIL  skills/init/SKILL.md não existe"; FAIL=$((FAIL+1)); fi
want "tem frontmatter com name"                'name: init'
want "declara quando usar"                     'when_to_use'

echo
echo "── Regras que ela existe para aplicar ───────────────────────────────"
want "ejeção: nada aponta para dentro do plugin"  'Nunca faça o agente apontar para dentro do plugin'
want "copia os guias para o projeto"              'Copie-os para dentro do projeto'
wantF "não deixa placeholder cru"                 'Nunca deixe um `{{PLACEHOLDER}}` no arquivo final'
want "não sobrescreve agente sem perguntar"       'Nunca sobrescreva um agente existente sem perguntar'
want "não opera o CLI"                            'Nunca rode .mi init., .mi push'
want "sabe que push publica"                      'publica na conta em nuvem'
want "entrevista a partir da tabela do arquétipo" 'Ela é a sua lista de perguntas'
want "uma mensagem só de perguntas"               'Uma mensagem só'
wantF "verifica no fim"                           "grep -c '{{' .claude/agents/*.md" 
want "lembra da sessão nova"                      'só aparecem em sessão nova'

echo
echo "── Porta B: a base instalada entra pelo init ────────────────────────"
want "procura mapas .mm"                       'Há mapas .{0,3}\.mm'
want "reconhece as duas portas de entrada"     'porta B|Porta B'
want "converte com o conversor do plugin"      'tools/mm-to-mi/convert\.sh'
want "pergunta antes de converter"             'Pergunte antes de converter'
want "lê o relatório de ícones em voz alta"    'ícones não mapeados'
want "apresenta a decisão dos três destinos"   'três destinos'
want "não confunde passa-cru-por-design com erro" 'passam crus por design'
want "estender a tabela é numa cópia no projeto" 'cópia do conversor dentro do projeto'
want "não declara a conversão concluída"       'Nunca declare a conversão concluída'
want "detecta o principal pela estrutura"      'carrega o bloco .config., e dentro'
want "exige config + structVersion"            'TEXT=.structVersion.'
want "sabe dos falsos positivos"               'ainda deixa falsos positivos'
want "usa os dois sinais discriminantes"       'filho direto da raiz'
want "anota os candidatos antes de perguntar"  'anote cada candidato com os dois sinais'
wantF "detecta também em .mi"                  "--include='*.mi'" 
want "não deduz pelo tamanho"                  'Nunca deduza pelo tamanho|maior mapa raramente'
want "trata 0, 1 e N candidatos"               'exatamente 1|mais de 1|nenhum'
want "sem principal = tarefa do domain-mapper" 'criá-lo é a primeira tarefa do .domain-mapper'

echo
echo "── O nome do projeto no CLI vem do registro ─────────────────────────"
want "procura o registro antes de perguntar"   'Não pergunte antes de procurar'
want "acha o projeto pelo caminho"             'mainMindMapHome'
want "reaproveita o nome que os scripts usam"  'Reaproveite o nome que os scripts do usuário já usam'
want "diz por que o nome importa"              'escrito dentro dos scripts de geração'
want "avisa da divergência push × generate"    'push. e .generate. usarem nomes diferentes'
want "explica o sintoma: código velho sem erro" 'código velho, sem erro nenhum'
want "manda procurar o nome nos scripts"       'procure o nome dentro deles'
want "cuidado com o HOME, como o cli-runner"   'HOME do processo pode divergir'

echo
echo "════════════════════════════════════════════════"
printf '  I2 Results: %d passed · %d failed · 0 skipped\n' "$PASS" "$FAIL"
echo "════════════════════════════════════════════════"
[ "$FAIL" -eq 0 ]
