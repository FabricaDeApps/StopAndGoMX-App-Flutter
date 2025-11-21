# stopandgo

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


./scripts/make_module.sh home    

Imoportante correr esto para los logos:
./scripts/use_logo.sh stopandgo

flutter build apk --flavor zorros -t lib/main_zorros.dart


Flavors Android:
flutter build aab --flavor zorros -t lib/main_zorros.dart
flutter build aab --flavor mainapp -t lib/main_stopandgo.dart


Flavors iOS
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

ANDROID
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




Nuevo Flavor

- crear assets en https://makeappicon.com/ 
- agregar logo a branding
- .vscode launcher agregar tarea y el comando de assets
- crear el main de dart y configurar el flavor en flutter
- en android 
  - carpeta de iconos
  - agregar en build.gradle
  


