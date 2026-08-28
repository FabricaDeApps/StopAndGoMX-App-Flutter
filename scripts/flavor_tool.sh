#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Uso: $0 stores <generate|validate> --config RUTA [--output RUTA] [--publish]" >&2
  exit 64
}

[[ ${1:-} == "stores" ]] || usage
shift

action=${1:-generate}
if [[ "$action" == "generate" || "$action" == "validate" ]]; then
  shift
else
  action="generate"
fi

exec ruby "$(dirname "$0")/store_tool.rb" "$action" "$@"
