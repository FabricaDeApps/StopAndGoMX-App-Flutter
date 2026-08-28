# Firebase Setup: Academia Puebla FC MID

Configuración completada para el flavor `academiapuebla` el 27 de agosto de
2026.

## Datos del flavor

- Nombre: `Academia Puebla FC MID`
- Flavor: `academiapuebla`
- Organization ID: `81`
- Organization slug: `academia-puebla-fc-mid`
- Android app ID: `app.stopandgomx.academiapuebla`
- iOS bundle ID: `app.stopandgomx.academiapuebla`
- Archivo Dart: `lib/firebase_options_academiapuebla.dart`
- Firebase Android app ID: `1:225171602574:android:f9285ba3cd6b7855cd9ddf`
- Firebase iOS app ID: `1:225171602574:ios:c905c1b81c8a7637cd9ddf`

## Archivos instalados

```text
android/app/src/academiapuebla/google-services.json
ios/Runner/Firebase/GoogleService-Info-academiapuebla.plist
lib/firebase_options_academiapuebla.dart
```

Los tres archivos corresponden a `app.stopandgomx.academiapuebla`.

## Comando FlutterFire de referencia

Las aplicaciones ya fueron creadas. Este es el comando de referencia para
regenerar la configuración en una versión de FlutterFire compatible:

```bash
flutterfire configure \
  --project=stopandgomx-4ab82 \
  --android-package-name=app.stopandgomx.academiapuebla \
  --ios-bundle-id=app.stopandgomx.academiapuebla \
  --platforms=android,ios \
  --out=lib/firebase_options_academiapuebla.dart
```

`GIDClientID` y `CFBundleURLTypes` ya están agregados a
`ios/Runner/Info-academiapuebla.plist`.

Nota: FlutterFire CLI 1.4.1 presentó un `RangeError` al combinar `ios-out` con
las múltiples build configurations de este proyecto. El archivo Dart se generó
de manera determinista a partir de los archivos SDK oficiales descargados con
Firebase CLI y se validaron los IDs de ambas plataformas.

## Builds esperados

```bash
flutter build aab --flavor academiapuebla -t lib/main_academiapuebla.dart
flutter build ios --config-only --release --flavor academiapuebla --target=lib/main_academiapuebla.dart
```
