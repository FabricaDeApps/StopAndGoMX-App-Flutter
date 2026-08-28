# Automatización de fichas de Google Play y App Store

## Objetivo

Cada flavor mantiene un manifiesto `branding/<flavor>/store.json`. A partir de
él se generan los formatos de Fastlane para ambas tiendas sin compartir archivos
entre organizaciones.

La salida es descartable y vive en `build/store/<flavor>/`:

```text
android/metadata/<locale>/
ios/metadata/<locale>/
ios/screenshots/<locale>/
validation-report.json
```

Los assets fuente y publicables permanecen en `branding/<flavor>/store/`. El
generador de imágenes crea el icono de Play Store, el gráfico promocional y
normaliza capturas desde los directorios `*-raw`:

```bash
dart run scripts/store_images.dart \
  --config branding/academiapuebla/store.json
```

## Comandos

Generar un borrador:

```bash
./scripts/flavor_tool.sh stores generate \
  --config branding/academiapuebla/store.json
```

Validar un borrador sin exigir datos externos:

```bash
./scripts/flavor_tool.sh stores validate \
  --config branding/academiapuebla/store.json
```

Validar antes de cualquier subida:

```bash
./scripts/flavor_tool.sh stores validate --publish \
  --config branding/academiapuebla/store.json
```

`--publish` exige política de privacidad, soporte, correo, credenciales de una
cuenta demo y por lo menos un screenshot por plataforma. La cuenta puede
guardarse en `store.review.username/password` cuando sea una cuenta controlada y
revocable desde el panel admin. Para repositorios con acceso más amplio se pueden
omitir esos campos y usar las variables de entorno indicadas en el manifiesto.

También exige `store.status: approved`. Este valor funciona como aprobación
humana explícita y solamente debe cambiarse después de revisar textos, imágenes
y declaraciones.

## Fastlane

Preparar metadata no produce cambios externos:

```bash
cd android && fastlane android prepare_academiapuebla_store
cd ios && fastlane ios prepare_academiapuebla_store
```

Las siguientes lanes sí escriben en las tiendas y solo avanzan si pasa la
validación estricta:

```bash
cd android && fastlane android upload_academiapuebla_store
cd ios && fastlane ios upload_academiapuebla_store
```

La sincronización de la ficha está separada del upload de AAB/IPA. Esto permite
revisar textos y screenshots sin generar una nueva versión binaria.

Lanes completas para Academia Puebla:

```bash
# Android
(cd android && fastlane android build_academiapuebla_aab)
(cd android && fastlane android deploy_academiapuebla_internal)
(cd android && fastlane android deploy_academiapuebla_production)
(cd android && fastlane android prepare_academiapuebla_store)
(cd android && fastlane android upload_academiapuebla_store)

# iOS
(cd ios && fastlane ios deploy_academiapuebla_testflight)
(cd ios && fastlane ios deploy_academiapuebla submit_review:true)
(cd ios && fastlane ios prepare_academiapuebla_store)
(cd ios && fastlane ios upload_academiapuebla_store)
```

Las lanes `deploy` y `upload` producen cambios externos. Para la primera
entrega se debe usar Internal/TestFlight antes de producción o App Review.

## Campos fuente

- Identidad: nombre, flavor, organization ID/slug y bundle/package IDs.
- Contacto: política de privacidad, soporte, marketing y correo.
- Localización: título, subtítulo, descripciones, keywords, texto promocional y
  notas de versión.
- Revisión: si requiere login y nombres de variables de entorno para la cuenta
  demo.
- Cumplimiento: confirmación de Data Safety, privacidad Apple, clasificación,
  audiencia objetivo e instrucciones de acceso.
- Screenshots: directorios por plataforma y escenarios esperados.
- Publicación: track, grupos TestFlight, precio y países.

El generador valida actualmente los límites comunes de Google Play y App Store:
30 caracteres para título/subtítulo, 80 para descripción corta, 4,000 para
descripción y notas, 170 para texto promocional y 100 para keywords iOS.
También valida dimensiones y alpha de screenshots, icono Android 512x512 y
gráfico promocional 1024x500.

## Estado de Academia Puebla

El manifiesto ya contiene los textos iniciales en español y los escenarios de
captura. Antes de habilitar las lanes de subida faltan:

- URL pública de política de privacidad;
- URL y correo de soporte;
- cambiar `store.status` de `draft` a `approved` tras la revisión;
- completar y confirmar los cuestionarios de cumplimiento de ambas tiendas;
- creación manual del registro inicial en ambas tiendas;
- revisión humana de textos y declaraciones legales.

La cuenta demo ya está integrada mediante variables de entorno y se generaron
tres capturas reproducibles (login, home y menú abierto) para Android e iPhone.
Al terminar cada corrida, el test cierra la sesión remota y limpia la sesión
local del dispositivo.

## Captura reproducible

La captura automática usa `integration_test/store_screenshots_test.dart`. Inicia
con la sesión local limpia, captura login, inicia sesión con las variables de
entorno, captura home y abre el menú lateral para la última imagen.

```bash
./scripts/capture_store_screenshots.sh android [device-id]
./scripts/capture_store_screenshots.sh ios [device-id]
```

Las variables `ACADEMIAPUEBLA_REVIEW_USERNAME` y
`ACADEMIAPUEBLA_REVIEW_PASSWORD` pueden sobrescribir temporalmente la cuenta del
manifiesto. El usuario demo debe tener información estable y ficticia, permisos
mínimos y poder revocarse desde el panel admin.

Las capturas originales se conservan para poder cambiar el renderer sin volver
a navegar la app. Las versiones publicables no contienen canal alpha.
