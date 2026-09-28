#!/usr/bin/env bash
# install-into-project.sh — copia os scripts de hook do kit para dentro de um projeto.
#
#   ./install-into-project.sh <diretório-do-projeto>
#
# Por que isto existe: os agentes gerados declaram o hook com caminho RELATIVO ao
# projeto (`scripts/check-write-path.sh`), de propósito — assim o agente continua
# funcionando se o plugin for desinstalado (regra de ejeção). O preço é que os
# scripts precisam existir no projeto ANTES do primeiro agente com hook rodar.
# É isso que este comando faz. Idempotente: não sobrescreve o que já está lá,
# a menos que --force.
set -uo pipefail

KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
die() { printf 'erro: %s\n' "$*" >&2; exit 2; }

[ $# -ge 1 ] || die "uso: $0 <diretório-do-projeto> [--force]"
DEST_ROOT="${1%/}"; FORCE="${2:-}"
[ -d "$DEST_ROOT" ] || die "diretório não existe: $DEST_ROOT"

mkdir -p "$DEST_ROOT/scripts"
installed=0; kept=0
for s in check-write-path.sh validate-bash.sh; do
  src="$KIT_ROOT/scripts/$s"; dst="$DEST_ROOT/scripts/$s"
  [ -f "$src" ] || die "script do kit não encontrado: $src"
  if [ -f "$dst" ] && [ "$FORCE" != "--force" ]; then
    echo "  mantido    scripts/$s (já existe — use --force para sobrescrever)"
    kept=$((kept+1))
  else
    cp "$src" "$dst" && chmod +x "$dst"
    echo "  instalado  scripts/$s"
    installed=$((installed+1))
  fi
done

cat <<EOF

$installed instalado(s), $kept mantido(s) em $DEST_ROOT/scripts/

Os scripts agora pertencem ao projeto — edite-os à vontade. Um agente que declare

  hooks:
    PreToolUse:
      - matcher: "Write|Edit"
        hooks:
          - type: command
            command: "scripts/check-write-path.sh"

funciona a partir de agora, com ou sem o plugin instalado.
EOF
