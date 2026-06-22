# NUEVO FLAVOR

- crear assets en https://makeappicon.com/ 
- agregar logo a branding
- para `celtas`, dejar el logo base en `branding/celtas/logo.png`
- .vscode launch.json y task.json agregar tarea y el comando de assets
- crear el main de dart y configurar el flavor en flutter

- en android 
  - carpeta de iconos en app/src/_flavor_
  - agregar en build.gradle
  - export PATH="$PATH:$HOME/.pub-cache/bin"
  - correr el comando FIREBASE CONFIGURE
  - revisar el import del main que apunte al fireabase_options correcto del flavor
  - agregar google-services.json en carpeta de flavor
  - flutter clean
  - compilar
  - crear tienda
- en ios
  - Abrir Xcode
  - Primero duplicar y crear el scheme en manage schemes
  - Project -> Info y agregar los build configs y setearlos al scheme
  - Configurar bundle y Appicon en cada buildconfig que se creo, la firma
  - export PATH="$PATH:$HOME/.pub-cache/bin"
  - correr el comando FIREBASE CONFIGURE
  - mover el plist que crea google a la carpeta de los demas flavors
  - ajustar lo de los pods en el podfile y flavors
  - agregar en build phases
  - revisar build phases
  - revisar lo de plist en build settings
  - flutter build ios --config-only --debug --flavor <flavor> --target=lib/main_<flavor>.dart
  - compilar desde run launcher
  - crear tienda

- LANES
  - configurar los lanes una vez que tenemos ya los builds


# stopandgo FLAVOR 

Imoportante correr esto para los logos:
./scripts/use_logo.sh stopandgo

flutter build apk --flavor zorros -t lib/main_zorros.dart


Flavors Android:
flutter build aab --flavor zorros -t lib/main_zorros.dart
flutter build aab --flavor mainapp -t lib/main_stopandgo.dart
flutter build aab --flavor raidersqro -t lib/main_raidersqro.dart
flutter build aab --flavor wolverinesqro -t lib/main_wolverinesqro.dart
flutter build aab --flavor bearsqro -t lib/main_bearsqro.dart
flutter build apk --flavor redskins -t lib/main_redskins.dart
flutter build apk --flavor celtas -t lib/main_celtas.dart


Flavors iOS
flutter build ios --config-only --debug --flavor mainapp --target=lib/main_mainapp.dart
flutter build ios --config-only --release --flavor bearsqro --target=lib/main_bearsqro.dart
flutter build ios --config-only --release

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

./scripts/use_logo.sh raidersqro








# FIREBASE CONFIGURE:
flutterfire configure \
  --project=stopandgomx-4ab82 \
  --android-app-id=app.stopandgomx.raidersqueretaro \
  --platforms=android \
  --out=lib/firebase_options_raidersqro.dart

flutterfire configure \
  --project=stopandgomx-4ab82 \
  --ios-app-id=app.stopandgomx.raidersqro \
  --platforms=ios \
  --out=lib/firebase_options_raidersqro.dart

flutterfire configure \
  --project=stopandgomx-4ab82 \
  --android-app-id=app.stopandgomx.wolverinesqro \
  --platforms=android \
  --out=lib/firebase_options_wolverinesqro.dart

flutterfire configure \
  --project=stopandgomx-4ab82 \
  --ios-bundle-id=app.stopandgomx.wolverinesqro \
  --platforms=ios \
  --out=lib/firebase_options_wolverinesqro.dart

flutterfire configure \
  --project=stopandgomx-4ab82 \
  --android-app-id=app.stopandgomx.bearsqro \
  --ios-bundle-id=app.stopandgomx.bearsqro \
  --platforms=android,ios \
  --out=lib/firebase_options_bearsqro.dart

flutterfire configure \
  --project=stopandgomx-4ab82 \
  --android-app-id=app.stopandgomx.celtas \
  --ios-bundle-id=app.stopandgomx.celtas \
  --platforms=android,ios \
  --out=lib/firebase_options_celtas.dart

Copiar el json de android a su carpeta en src

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


- Wolverines Queretaro - wolverinesqro
  
  # Bundle
    Android: app.stopandgomx.wolverinesqro
    iOS: app.stopandgomx.wolverinesqro
  # demo user
    manager@wolverines.com
    123456

- Celtas - celtas
  
  # Bundle
    Android: app.stopandgomx.celtas
    iOS: app.stopandgomx.celtas
