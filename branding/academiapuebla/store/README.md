# Assets de tienda — Academia Puebla FC MID

El manifiesto fuente es `../store.json`. La cuenta demo de revisión sí se guarda
ahí porque está controlada desde el panel admin. No guardes llaves de acceso de
Google Play o App Store Connect en esta carpeta.

## Screenshots fuente

La prueba de integración guarda las capturas originales en los directorios
`*-raw`. `scripts/store_images.dart` genera las versiones publicables sin alpha:

```text
screenshots/android/phone/01-login.png
screenshots/android/phone/02-home.png
screenshots/android/phone/03-home-menu.png

screenshots/ios/iphone-6.9/01-login.png
screenshots/ios/iphone-6.9/02-home.png
screenshots/ios/iphone-6.9/03-home-menu.png
```

Las capturas se generan mediante una prueba de integración. Por defecto usan la
cuenta demo de `store.json`; las variables de entorno permiten sobrescribirla.

```bash
./scripts/capture_store_screenshots.sh android [device-id]
./scripts/capture_store_screenshots.sh ios [device-id]
```

El flujo limpia la sesión local, captura login, inicia sesión, captura home y
abre el menú lateral para la tercera imagen. Después normaliza Android a
1080x1920, elimina alpha, genera el icono de 512x512 y el gráfico promocional de
1024x500, y finalmente regenera la metadata.

Los assets Android terminan en:

```text
android/icon.png
android/featureGraphic.png
```

Para regenerarlos sin volver a iniciar sesión:

```bash
dart run scripts/store_images.dart \
  --config branding/academiapuebla/store.json
```

## Generación local

```bash
./scripts/flavor_tool.sh stores generate \
  --config branding/academiapuebla/store.json
```

El resultado se escribe en `build/store/academiapuebla/`.

## Validación de publicación

```bash
ACADEMIAPUEBLA_REVIEW_USERNAME='usuario-demo' \
ACADEMIAPUEBLA_REVIEW_PASSWORD='contraseña-demo' \
./scripts/flavor_tool.sh stores validate --publish \
  --config branding/academiapuebla/store.json
```

Este comando no sube información. Falla mientras falten URLs, contacto,
credenciales de revisión o screenshots. También requiere cambiar `store.status`
de `draft` a `approved` después de la revisión humana.
