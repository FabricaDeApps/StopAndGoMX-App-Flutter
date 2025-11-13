#!/usr/bin/env bash
set -e

FLAVOR=$1

if [ -z "$FLAVOR" ]; then
  echo "Uso: ./scripts/use_logo.sh [zorros|tigres|dragones|...]"
  exit 1
fi

SRC="branding/$FLAVOR/logo.png"
DEST="assets/images/logo_generic.png"

if [ ! -f "$SRC" ]; then
  echo "❌ No se encontró el logo para el flavor '$FLAVOR' en: $SRC"
  exit 1
fi

echo "📦 Copiando $SRC -> $DEST"
cp "$SRC" "$DEST"