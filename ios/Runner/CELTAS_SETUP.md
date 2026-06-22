Configuracion pendiente para iOS flavor `celtas`

Iconos iOS:

- Crea un nuevo asset catalog set en:
  `ios/Runner/Assets.xcassets/AppIconCeltas.appiconset`
- Ahi deben ir los PNGs y su `Contents.json`
- Puedes tomar como base:
  `ios/Runner/Assets.xcassets/AppIconBearsqro.appiconset`

Firebase iOS:

- Coloca el plist en:
  `ios/Runner/Firebase/GoogleService-Info-celtas.plist`

Xcode:

- Duplicar scheme/configs de otro flavor
- Crear `Info-celtas.plist`
- Crear `Debug-celtas` y `Release-celtas`
- Asignar bundle id `app.stopandgomx.celtas`
- Apuntar el App Icon a `AppIconCeltas`
