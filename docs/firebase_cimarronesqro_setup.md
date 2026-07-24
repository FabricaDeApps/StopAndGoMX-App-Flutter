# Firebase Setup: Cimarrones Qro

Comandos exactos para dar de alta y configurar Firebase del flavor `cimarronesqro`.

## Datos del Flavor

- Flavor: `cimarronesqro`
- Android app id: `app.stopandgomx.cimarronesqro`
- iOS bundle id: `app.stopandgomx.cimarronesqro`
- Archivo Dart esperado: `lib/firebase_options_cimarronesqro.dart`

## 1. Login y proyecto

```bash
firebase login
firebase use stopandgomx-4ab82
```

## 2. Crear apps en Firebase

Android:

```bash
firebase apps:create -a app.stopandgomx.cimarronesqro android cimarronesqro-android
```

iOS:

```bash
firebase apps:create --bundle-id app.stopandgomx.cimarronesqro ios cimarronesqro-ios
```

Nota:

- Si pide `Please specify your iOS app App Store ID:`
  puedes dar `Enter` si la app todavía no existe en App Store Connect.

## 3. Descargar archivos nativos

Android:

```bash
firebase apps:sdkconfig android -o android/app/src/cimarronesqro/google-services.json
```

iOS:

```bash
firebase apps:sdkconfig ios -o ios/Runner/Firebase/GoogleService-Info-cimarronesqro.plist
```

## 4. Generar FlutterFire options

```bash
flutterfire configure \
  --project=stopandgomx-4ab82 \
  --android-app-id=app.stopandgomx.cimarronesqro \
  --ios-bundle-id=app.stopandgomx.cimarronesqro \
  --platforms=android,ios \
  --out=lib/firebase_options_cimarronesqro.dart
```

## 5. Verificación rápida

Deben existir estos archivos:

```bash
android/app/src/cimarronesqro/google-services.json
ios/Runner/Firebase/GoogleService-Info-cimarronesqro.plist
lib/firebase_options_cimarronesqro.dart
```

## 6. Build esperados después de Firebase

Android:

```bash
flutter build aab --flavor cimarronesqro -t lib/main_cimarronesqro.dart
```

iOS:

```bash
flutter build ios --config-only --release --flavor cimarronesqro --target=lib/main_cimarronesqro.dart
```

## 7. Fastlane después de Firebase

Android:

```bash
cd android
fastlane android deploy_cimarronesqro_production
```

iOS:

```bash
cd ios
fastlane ios deploy_cimarronesqro
```
