# stopandgo FLAVOR 

Imoportante correr esto para los logos:
./scripts/use_logo.sh stopandgo

flutter build apk --flavor zorros -t lib/main_zorros.dart


Flavors Android:
flutter build aab --flavor zorros -t lib/main_zorros.dart
flutter build aab --flavor mainapp -t lib/main_stopandgo.dart
flutter build aab --flavor raidersqro -t lib/main_raidersqro.dart


Flavors iOS
flutter build ios --config-only --debug --flavor mainapp --target=lib/main_mainapp.dart

flutter build ios --flavor zorros -t lib/main_zorros.dart
flutter build ios --flavor mainapp -t lib/main_stopandgo.dart


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




### ANDROID - WORKING

# Zorros a producción
fastlane deploy_zorros_production

# Mainapp a producción
fastlane deploy_mainapp_production

# RaidersQro a producción
fastlane deploy_raidersqro_production



IOS - WORKS

# mainapp
deprecated - ./scripts/use_logo.sh stopandgo
deprecated - flutter build ios --config-only --release --flavor mainapp --target=lib/main_mainapp.dart

fastlane deploy_mainapp

# zorros
deprecated - ./scripts/use_logo.sh zorros
deprecated - flutter build ios --config-only --release --flavor zorros --target=lib/main_zorros.dart

fastlane deploy_zorros




Nuevo Flavor

- crear assets en https://makeappicon.com/ 
- agregar logo a branding
- .vscode launcher agregar tarea y el comando de assets
- crear el main de dart y configurar el flavor en flutter
- en android 
  - carpeta de iconos
  - agregar en build.gradle



# FIREBASE CONFIGUR:
flutterfire configure \
  --project=stopandgomx-4ab82 \
  --android-app-id=app.stopandgomx.raidersqro \
  --platforms=android \
  --out=lib/firebase_options_raidersqro.dart

Copiar el json a su carpeta en src

# KEY ID IOS:
CLT625F29B

# TEAM ID IOS:
M25Y63Z23D


# LIST FLAVORS:

- StopAndGoMX - 

  # Bundle
    Android: app.stopandgomx.main
    iOS: app.stopandgomx.stopandgo
  # demo user
    manager@stopandgo.app
    123456

- Zorros Football Academy - 
  
  # Bundle
    Android: app.stopandgomx.zorros
    iOS: app.stopandgomx.zorros
  # demo user
    manager@zorros.com
    123456

- Raiders Queretaro - 
  
  # Bundle
    Android: app.stopandgomx.raidersqro
    iOS: app.stopandgomx.raidersqro
  # demo user
    manager@raiders.com
    123456