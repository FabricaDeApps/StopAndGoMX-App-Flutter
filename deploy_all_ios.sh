#!/bin/bash

# Detiene el script si ocurre algún error
set -e

echo "🚀 Iniciando despliegue de TODAS las apps iOS..."
echo "=============================================="
echo ""

# Entrar a la carpeta iOS
echo "📂 Cambiando a carpeta ios/"
cd ios

########################################
# MAINAPP
########################################
echo "📦 Deploy iOS: MAINAPP"
#fastlane deploy_mainapp
echo "✅ MAINAPP completado"
echo ""

########################################
# ZORROS
########################################
echo "🐺 Deploy iOS: ZORROS"
#fastlane deploy_zorros
echo "✅ ZORROS completado"
echo ""

########################################
# RAIDERSQRO
########################################
echo "🏴‍☠️ Deploy iOS: RAIDERSQRO"
#fastlane deploy_raidersqro
echo "✅ RAIDERSQRO completado"
echo ""

########################################
# WOLVERINESQRO
########################################
echo "🐺💛 Deploy iOS: WOLVERINESQRO"
#fastlane deploy_wolverinesqro
echo "✅ WOLVERINESQRO completado"
echo ""

########################################
# BEARSQRO
########################################
echo "🐺💛 Deploy iOS: BEARSQRO"
fastlane deploy_bearsqro
echo "✅ BEARSQRO completado"
echo ""

echo "🎉🚀 TODOS LOS DEPLOYS iOS TERMINADOS EXITOSAMENTE"