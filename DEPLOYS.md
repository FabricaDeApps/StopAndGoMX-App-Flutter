# FASTLANE:

ZORROS
./scripts/use_logo.sh zorros
fastlane android deploy \
  flavor:zorros \
  target:lib/main_zorros.dart \
  track:internal \
  package_name:app.stopandgomx.zorros

fastlane android deploy flavor:zorros target:lib/main_zorros.dart track:production package_name:app.stopandgomx.zorros

# Branding flavor
STOPANDGO
./scripts/use_logo.sh stopandgo

./scripts/use_logo.sh raidersqro




### ANDROID - WORKING

# Mainapp a producción
fastlane deploy_mainapp_production

# Zorros a producción
fastlane deploy_zorros_production

# RaidersQro a producción
fastlane deploy_raidersqro_production

# WolverinesQro a producción
fastlane deploy_wolverinesqro_production



IOS - WORKS

# mainapp
deprecated - ./scripts/use_logo.sh stopandgo
deprecated - flutter build ios --config-only --release --flavor mainapp --target=lib/main_mainapp.dart

fastlane deploy_mainapp

# zorros
fastlane deploy_zorros

# raidersqro
fastlane deploy_raidersqro


# wolverinesqro
fastlane deploy_wolverinesqro