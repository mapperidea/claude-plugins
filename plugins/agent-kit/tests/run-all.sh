#!/usr/bin/env bash
# run-all.sh — roda a suíte de aceite do agent-kit.
#
# São testes ESTRUTURAIS: verificam que o wizard, os helpers, os templates, o
# extrator e os scripts existem, estão executáveis e contêm as seções que o
# método exige. Não invocam o modelo — não custam tokens e rodam em segundo.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
fail=0
for t in test-f*.sh; do
  echo; echo "═══ $t ═══"
  bash "$t" || fail=$((fail+1))
done
echo
if [ "$fail" -eq 0 ]; then echo "SUÍTE VERDE — $(ls test-f*.sh | wc -l) arquivos de teste"; else echo "SUÍTE VERMELHA — $fail arquivo(s) com falha"; fi
exit $fail
