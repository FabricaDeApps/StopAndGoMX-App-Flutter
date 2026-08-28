# Alta automatizada de un flavor

Este documento define el proceso reproducible para dar de alta una aplicación
dedicada dentro del proyecto. Es la especificación funcional del futuro
generador de flavors; no debe depender de copiar credenciales o configuraciones
de otro club.

## Objetivo

El alta se divide en tres comandos o fases independientes:

1. `scaffold`: genera código, branding, Android, iOS y configuración local.
2. `firebase`: registra o conecta las apps y reemplaza los placeholders.
3. `stores`: prepara publicación, firma, textos y lanes de despliegue.

Separar las fases permite crear un flavor aunque Firebase o las cuentas de las
tiendas todavía no estén disponibles.

## Contrato de entrada

El generador debe recibir un manifiesto JSON. La plantilla se encuentra en
[`flavor_manifest.example.json`](flavor_manifest.example.json).

### Campos obligatorios para `scaffold`

| Campo | Regla | Ejemplo |
| --- | --- | --- |
| `name` | Nombre visible de la aplicación | `Academia Puebla FC MID` |
| `flavor` | Minúsculas, números; debe iniciar con letra | `academiapuebla` |
| `organizationId` | Entero positivo del backend | `81` |
| `organizationSlug` | Slug existente en backend | `academia-puebla-fc-mid` |
| `androidApplicationId` | Identificador único Android | `app.stopandgomx.academiapuebla` |
| `iosBundleId` | Identificador único iOS | `app.stopandgomx.academiapuebla` |
| `platforms` | `android`, `ios` o ambos | `["android", "ios"]` |
| `branding.logo` | PNG cuadrado, recomendado 1024×1024 | `branding/academiapuebla/logo.png` |

### Campos opcionales

- `tabs`: tabs por rol. Si se omite, se utiliza el conjunto estándar actual.
- `paymentProvider`: proveedor de pagos del flavor.
- `firebaseProjectId`: por defecto `stopandgomx-4ab82`.
- `iosTeamId`: por defecto el Team ID configurado en el proyecto.
- `store`: metadatos de Google Play y App Store.

Los colores no forman parte actualmente de `FlavorConfig`; el branding visual
adicional se obtiene de la organización remota. Si después se agregan colores
locales, deben incorporarse al contrato antes de automatizarlos.

## Preflight obligatorio

Antes de escribir archivos, el generador debe validar:

- El manifiesto es JSON válido y contiene todos los campos requeridos.
- `flavor` cumple `^[a-z][a-z0-9]*$`.
- `organizationId` es mayor que cero.
- El logo existe, es PNG, es cuadrado y mide al menos 1024×1024.
- El flavor no existe en Dart, Gradle, Xcode, VS Code ni Fastlane.
- Los application IDs no pertenecen a otro flavor.
- Los nombres derivados no colisionan:
  - `lib/main_<flavor>.dart`
  - `AppIcon<Flavor>.appiconset`
  - `Debug-<flavor>` y `Release-<flavor>`
  - scheme `<flavor>`
- El árbol de trabajo no contiene cambios que se solapen con los archivos que
  se modificarán.

El preflight debe terminar sin cambios si alguna validación falla.

## Fase 1: scaffold

### 1. Flutter

El generador debe:

1. Agregar el valor a `AppFlavor` en
   `lib/core/config/flavor_config.dart`.
2. Agregar la configuración de tabs por rol.
3. Crear `lib/main_<flavor>.dart` con:
   - nombre visible;
   - bundle ID;
   - `isCustom: true`;
   - `organizationId`.
4. Crear `lib/firebase_options_<flavor>.dart` como placeholder explícito si
   Firebase todavía no está configurado.

El placeholder debe fallar con un mensaje claro. Nunca debe copiar las
credenciales Firebase de otro flavor.

### 2. Branding e iconos

Entrada esperada:

```text
branding/<flavor>/logo.png
```

Generación actual:

```bash
./scripts/generate_flavor_icons.sh <flavor> AppIcon<Flavor>
```

Salidas:

```text
android/app/src/<flavor>/res/**
ios/Runner/Assets.xcassets/AppIcon<Flavor>.appiconset/**
```

El generador final también debe crear o copiar `Contents.json` del catálogo
iOS. El icono App Store de 1024×1024 debe quedar sin canal alpha.

### 3. Android

Modificar `android/app/build.gradle.kts`:

```kotlin
create("<flavor>") {
    dimension = "default"
    applicationId = "<androidApplicationId>"
    resValue("string", "app_name", "<name>")
}
```

Crear `android/app/src/<flavor>/README.md` indicando los datos del flavor y el
archivo Firebase pendiente. No crear un `google-services.json` falso.

### 4. iOS

El generador debe crear:

```text
ios/Debug-<flavor>.xcconfig
ios/Release-<flavor>.xcconfig
ios/Runner/Info-<flavor>.plist
ios/Runner.xcodeproj/xcshareddata/xcschemes/<flavor>.xcscheme
```

También debe modificar el proyecto Xcode para añadir `Debug-<flavor>` y
`Release-<flavor>` en:

- proyecto `Runner`;
- target `Runner`;
- target `RunnerTests`.

Configuración requerida del target:

- `PRODUCT_BUNDLE_IDENTIFIER=<iosBundleId>`
- `ASSETCATALOG_COMPILER_APPICON_NAME=AppIcon<Flavor>`
- `INFOPLIST_FILE=Runner/Info-<flavor>.plist`
- `INFOPLIST_KEY_CFBundleDisplayName=<name>`

La modificación de `project.pbxproj` debe hacerse con la gema `xcodeproj`, no
con sustituciones de texto sin estructura. Como plantilla se toma el flavor
dedicado más reciente, actualmente `cimarronesqro`.

Agregar las dos configuraciones al mapa del `ios/Podfile` y agregar el flavor
al Build Phase que selecciona `GoogleService-Info-<flavor>.plist`.

Mientras Firebase esté pendiente, el plist de la app no debe contener un
`GIDClientID` ni URL scheme perteneciente a otro flavor.

### 5. Herramientas de desarrollo

Agregar:

- configuración `Run <name>` en `.vscode/launch.json`;
- tarea `prepare-<flavor>-assets` en `.vscode/tasks.json`;
- lane Android de build AAB;
- lane Android de deploy a producción;
- entrypoint y lane iOS de deploy;
- registros correspondientes en los README generados de Fastlane;
- flavor en `FLAVORS.md` y comando en `DEPLOYS.md`.

### 6. Documentación de Firebase pendiente

Crear `docs/firebase_<flavor>_setup.md` con:

- IDs Android/iOS;
- proyecto Firebase;
- rutas de los tres archivos esperados;
- comando `flutterfire configure`;
- comandos de build posteriores.

## Fase 2: firebase

Esta fase requiere autenticación y acceso al proyecto Firebase.

Debe:

1. Comprobar si las apps Android/iOS ya existen.
2. Crearlas solamente si faltan.
3. Descargar:
   - `android/app/src/<flavor>/google-services.json`;
   - `ios/Runner/Firebase/GoogleService-Info-<flavor>.plist`.
4. Ejecutar `flutterfire configure` y reemplazar el placeholder Dart.
5. Verificar que los IDs internos coincidan con el manifiesto.
6. Incorporar `GIDClientID` y `CFBundleURLTypes` al Info.plist si se habilita
   Google Sign-In.

Esta fase no debe imprimir secretos ni contenidos completos de archivos de
Firebase en logs.

## Fase 3: stores

Requiere acceso a Google Play Console y App Store Connect.

La primera versión de esta fase ya está implementada mediante
`scripts/flavor_tool.sh stores`. El formato del manifiesto, comandos, lanes y
pendientes de captura se documentan en
[`store_automation.md`](store_automation.md).

Debe validar:

- aplicación creada en ambas tiendas;
- firma Android y perfil/certificado iOS;
- política de privacidad, soporte y países;
- nombre, subtítulo, descripciones y keywords;
- screenshots con el branding correcto;
- módulos realmente habilitados para no prometer funciones inexistentes;
- track Android y grupo TestFlight iniciales.

La plantilla Android está en
[`android_store_listing_template.md`](android_store_listing_template.md).

## Validaciones automáticas

Después de `scaffold`:

```bash
dart format lib/main_<flavor>.dart \
  lib/firebase_options_<flavor>.dart \
  lib/core/config/flavor_config.dart

flutter analyze lib/main_<flavor>.dart \
  lib/firebase_options_<flavor>.dart \
  lib/core/config/flavor_config.dart

JAVA_HOME=/opt/homebrew/opt/openjdk@17 \
  ./android/gradlew -p android :app:assemble<Flavor>Debug \
  --dry-run --console=plain

ruby -c android/fastlane/Fastfile
ruby -c ios/fastlane/Fastfile
plutil -lint ios/Runner/Info-<flavor>.plist
xmllint --noout \
  ios/Runner.xcodeproj/xcshareddata/xcschemes/<flavor>.xcscheme
ruby -rxcodeproj -e \
  'Xcodeproj::Project.open("ios/Runner.xcodeproj"); puts "Xcode project OK"'
git diff --check
```

Después de `firebase`, agregar builds reales:

```bash
flutter build apk --debug --flavor <flavor> -t lib/main_<flavor>.dart
flutter build ios --config-only --debug --flavor <flavor> \
  --target=lib/main_<flavor>.dart
```

## Resultado esperado de cada fase

### Scaffold completo

- Flutter analiza sin errores nuevos.
- Android reconoce las tareas del flavor.
- Xcode contiene scheme y configuraciones Debug/Release.
- Los iconos existen y el catálogo iOS está completo.
- Firebase está configurado o bloqueado mediante un placeholder explícito.

### Firebase completo

- Los tres archivos Firebase existen y corresponden a los IDs correctos.
- Android e iOS alcanzan el build nativo.
- Analytics, push y autenticación pueden inicializarse.

### Stores completo

- Lanes pueden generar artefactos firmados.
- Metadatos y assets están preparados para publicación.

## Requisitos del futuro generador

El comando propuesto es:

```bash
./scripts/flavor_tool.sh scaffold --config path/al/flavor.json --dry-run
./scripts/flavor_tool.sh scaffold --config path/al/flavor.json
./scripts/flavor_tool.sh firebase --config path/al/flavor.json
./scripts/flavor_tool.sh stores --config path/al/flavor.json
./scripts/flavor_tool.sh validate --config path/al/flavor.json
```

Debe cumplir estas propiedades:

- **Idempotente:** ejecutarlo dos veces no duplica enums, configs ni lanes.
- **Transaccional:** si falla, revierte solamente los archivos creados por esa
  ejecución.
- **Dry-run:** muestra archivos y cambios sin escribir.
- **Validable:** termina con un resumen `creado / existente / pendiente / error`.
- **Seguro:** nunca toma Firebase, bundle IDs o firma de otro flavor como
  fallback.
- **Acotado:** no formatea ni reescribe archivos ajenos al alta del flavor.

## Checklist de revisión humana

- [ ] Nombre visible correcto.
- [ ] Flavor y bundle IDs aprobados.
- [ ] Organization ID y slug coinciden con backend.
- [ ] Logo revisado en iconos Android e iOS.
- [ ] Tabs y módulos confirmados por rol.
- [ ] Firebase pertenece al flavor correcto.
- [ ] Firma y tiendas pertenecen a la organización correcta.
- [ ] Build Android probado.
- [ ] Build iOS probado.
- [ ] Textos y screenshots revisados antes de publicar.
