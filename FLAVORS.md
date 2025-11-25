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


FASTLANE:

ZORROS
./scripts/use_logo.sh zorros
fastlane android deploy \
  flavor:zorros \
  target:lib/main_zorros.dart \
  track:internal \
  package_name:app.stopandgomx.zorros

fastlane android deploy flavor:zorros target:lib/main_zorros.dart track:production package_name:app.stopandgomx.zorros


STOPANDGO
./scripts/use_logo.sh stopandgo

ANDROID - WORKING
# Zorros a producción
fastlane deploy_zorros_production

# Zorros a internal
fastlane deploy_zorros_internal

# Mainapp a producción
fastlane deploy_mainapp_production

# Mainapp a internal
fastlane deploy_mainapp_internal


IOS - WORKS
# mainapp
fastlane deploy_mainapp

# zorros
fastlane deploy_zorros


USERS MANAGER DEMO:
manager@stopandgo.app
123456

manager@raiders.com
123456

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

