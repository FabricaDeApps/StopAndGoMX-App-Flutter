#!/bin/bash

# Detiene el script si ocurre algún error
set -e

SUBMIT_REVIEW="${SUBMIT_REVIEW:-false}"

if [[ "$1" == "--submit-review" ]]; then
  SUBMIT_REVIEW="true"
fi

FASTLANE_REVIEW_ARGS=()
SUBMIT_REVIEW_NORMALIZED="$(printf '%s' "$SUBMIT_REVIEW" | tr '[:upper:]' '[:lower:]')"
if [[ "$SUBMIT_REVIEW_NORMALIZED" == "true" ]]; then
  FASTLANE_REVIEW_ARGS=("submit_review:true")
fi

echo "🚀 Iniciando despliegue de TODAS las apps iOS..."
echo "=============================================="
echo "📨 submit_review=${SUBMIT_REVIEW}"
echo ""

# Entrar a la carpeta iOS
echo "📂 Cambiando a carpeta ios/"
cd ios

########################################
# MAINAPP
########################################
echo "📦 Deploy iOS: MAINAPP"
fastlane deploy_mainapp "${FASTLANE_REVIEW_ARGS[@]}"
echo "✅ MAINAPP completado"
echo ""

########################################
# ZORROS
########################################
echo "🐺 Deploy iOS: ZORROS"
fastlane deploy_zorros "${FASTLANE_REVIEW_ARGS[@]}"
echo "✅ ZORROS completado"
echo ""

########################################
# RAIDERSQRO
########################################
echo "🏴‍☠️ Deploy iOS: RAIDERSQRO"
fastlane deploy_raidersqro "${FASTLANE_REVIEW_ARGS[@]}"
echo "✅ RAIDERSQRO completado"
echo ""

########################################
# WOLVERINESQRO
########################################
#echo "🐺💛 Deploy iOS: WOLVERINESQRO"
#fastlane deploy_wolverinesqro "${FASTLANE_REVIEW_ARGS[@]}"
#echo "✅ WOLVERINESQRO completado"
#echo ""

########################################
# BEARSQRO
########################################
echo "🐺💛 Deploy iOS: BEARSQRO"
fastlane deploy_bearsqro "${FASTLANE_REVIEW_ARGS[@]}"
echo "✅ BEARSQRO completado"
echo ""

########################################
# CELTAS
########################################
#echo "☘️ Deploy iOS: CELTAS"
#fastlane deploy_celtas "${FASTLANE_REVIEW_ARGS[@]}"
#echo "✅ CELTAS completado"
#echo ""

########################################
# CIMARRONESQRO
########################################
echo "🐏 Deploy iOS: CIMARRONESQRO"
fastlane deploy_cimarronesqro "${FASTLANE_REVIEW_ARGS[@]}"
echo "✅ CIMARRONESQRO completado"
echo ""

echo "🎉🚀 TODOS LOS DEPLOYS iOS TERMINADOS EXITOSAMENTE"
