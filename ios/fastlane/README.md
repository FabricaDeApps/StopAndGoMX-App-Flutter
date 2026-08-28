fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios deploy

```sh
[bundle exec] fastlane ios deploy
```

Build & upload iOS (TestFlight) usando Flutter + flavors

### ios prepare_store_listing

```sh
[bundle exec] fastlane ios prepare_store_listing
```

Genera y valida metadata de App Store sin subirla

### ios upload_store_listing

```sh
[bundle exec] fastlane ios upload_store_listing
```

Sube ficha y screenshots a App Store Connect sin subir un binario

### ios deploy_mainapp

```sh
[bundle exec] fastlane ios deploy_mainapp
```

Deploy iOS mainapp (StopAndGo)

### ios deploy_zorros

```sh
[bundle exec] fastlane ios deploy_zorros
```

Deploy iOS Zorros

### ios deploy_raidersqro

```sh
[bundle exec] fastlane ios deploy_raidersqro
```

Deploy iOS Raiders Qro

### ios deploy_wolverinesqro

```sh
[bundle exec] fastlane ios deploy_wolverinesqro
```

Deploy iOS Wolverines Qro

### ios deploy_bearsqro

```sh
[bundle exec] fastlane ios deploy_bearsqro
```

Deploy iOS Bears Corregidora

### ios deploy_celtas

```sh
[bundle exec] fastlane ios deploy_celtas
```

Deploy iOS Celtas

### ios deploy_cimarronesqro

```sh
[bundle exec] fastlane ios deploy_cimarronesqro
```

Deploy iOS Cimarrones Qro

### ios deploy_academiapuebla

```sh
[bundle exec] fastlane ios deploy_academiapuebla
```

Deploy iOS Academia Puebla FC MID

### ios deploy_academiapuebla_testflight

```sh
[bundle exec] fastlane ios deploy_academiapuebla_testflight
```

Deploy iOS Academia Puebla FC MID a TestFlight

### ios prepare_academiapuebla_store

```sh
[bundle exec] fastlane ios prepare_academiapuebla_store
```

Preparar ficha App Store de Academia Puebla FC MID (sin upload)

### ios upload_academiapuebla_store

```sh
[bundle exec] fastlane ios upload_academiapuebla_store
```

Sincronizar ficha App Store de Academia Puebla FC MID (sin binario)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
