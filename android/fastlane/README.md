fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android deploy

```sh
[bundle exec] fastlane android deploy
```

Build & upload a Google Play usando Flutter + flavors (lane genérica)

### android build_aab

```sh
[bundle exec] fastlane android build_aab
```

Build signed AAB usando Flutter + flavors (sin upload)

### android prepare_store_listing

```sh
[bundle exec] fastlane android prepare_store_listing
```

Genera y valida metadata de Google Play sin subirla

### android upload_store_listing

```sh
[bundle exec] fastlane android upload_store_listing
```

Sube ficha, imágenes y screenshots a Google Play sin subir un binario

### android deploy_mainapp_production

```sh
[bundle exec] fastlane android deploy_mainapp_production
```

Deploy Android mainapp (StopAndGo) a track PRODUCTION

### android deploy_zorros_production

```sh
[bundle exec] fastlane android deploy_zorros_production
```

Deploy Android Zorros a track PRODUCTION

### android deploy_raidersqro_production

```sh
[bundle exec] fastlane android deploy_raidersqro_production
```

Deploy Android RaidersQRO a track PRODUCTION

### android deploy_wolverinesqro_production

```sh
[bundle exec] fastlane android deploy_wolverinesqro_production
```

Deploy Android WOLVERINES QRO a track PRODUCTION

### android deploy_bearsqro_production

```sh
[bundle exec] fastlane android deploy_bearsqro_production
```

Deploy Android BEARS CORREGIDORA a track PRODUCTION

### android deploy_celtas_production

```sh
[bundle exec] fastlane android deploy_celtas_production
```

Deploy Android Celtas a track PRODUCTION

### android deploy_cimarronesqro_production

```sh
[bundle exec] fastlane android deploy_cimarronesqro_production
```

Deploy Android Cimarrones Qro a track PRODUCTION

### android build_cimarronesqro_aab

```sh
[bundle exec] fastlane android build_cimarronesqro_aab
```

Build signed AAB Android Cimarrones Qro (sin upload)

### android deploy_academiapuebla_internal

```sh
[bundle exec] fastlane android deploy_academiapuebla_internal
```

Deploy Android Academia Puebla FC MID a track INTERNAL

### android deploy_academiapuebla_production

```sh
[bundle exec] fastlane android deploy_academiapuebla_production
```

Deploy Android Academia Puebla FC MID a track PRODUCTION

### android build_academiapuebla_aab

```sh
[bundle exec] fastlane android build_academiapuebla_aab
```

Build signed AAB Android Academia Puebla FC MID (sin upload)

### android prepare_academiapuebla_store

```sh
[bundle exec] fastlane android prepare_academiapuebla_store
```

Preparar ficha Google Play de Academia Puebla FC MID (sin upload)

### android upload_academiapuebla_store

```sh
[bundle exec] fastlane android upload_academiapuebla_store
```

Sincronizar ficha Google Play de Academia Puebla FC MID (sin binario)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
