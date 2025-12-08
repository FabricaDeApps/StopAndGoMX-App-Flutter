#!/bin/bash

set -e  # Si una lane falla, detiene el script
set -o pipefail

echo "🔧 Iniciando deploy completo StopAndGoMX..."

# Entrar a android
cd android || exit 1

echo "🚀 Deploy MAINAPP (Producción)"
fastlane deploy_mainapp_production

echo "🚀 Deploy ZORROS (Producción)"
fastlane deploy_zorros_production

echo "🚀 Deploy RAIDERSQRO (Producción)"
fastlane deploy_raidersqro_production

echo "🚀 Deploy WOLVERINESQRO (Producción)"
fastlane deploy_wolverinesqro_production

echo "🎉 Todos los deploys finalizados correctamente."