# Plan de implementación Gazzetta (Flutter + Laravel)

## Contexto actual del proyecto
- `baseUrl` ya incluye `/api` (`ApiEnv.baseUrl`), por lo que las rutas en `Dio` deben ir como `/gazetta/...`.
- Auth bearer y `X-Organization-Id` ya se inyectan por `AuthInterceptor` + `OrgInterceptor` y/o `_headers()` en `ApiRepository`.
- El proyecto ya usa:
  - GetX para DI/estado/navegación.
  - `ApiRepository` como capa de acceso HTTP.
  - `PaginatedResponse<T>` para paginación tipo Laravel (`data`, `current_page`, `last_page`, `next_page_url`).

## Objetivo funcional
Agregar módulo Gazzetta con:
- Feed (última gazetta visible)
- Histórico paginado
- Detalle renderizado por `json_payload`
- Meta ligera (incluye `seen`)
- Tracking de lectura (`markSeen` al abrir detalle)
- Integración de tab/menú en Home con comportamiento de módulo no disponible (404)

## Endpoints a consumir
Con `baseUrl=https://.../api`, usar:
- `GET /gazetta/feed`
- `GET /gazetta/history?from=YYYY-MM-DD&to=YYYY-MM-DD&week_start=YYYY-MM-DD&per_page=20&page=1`
- `GET /gazetta/{id}`
- `GET /gazetta/{id}/meta`
- `POST /gazetta/{id}/seen`

## Diseño propuesto por capas

### 1) Modelos (core/models/gazzetta)
Crear carpeta `lib/core/models/gazzetta/` con:

1. `gazetta_item.dart`
- Resumen para feed/history.
- Campos mínimos: `id`, `organizationId`, `weekStart`, `weekEnd`, `status`, `roleMode`, `subject`, `publishedAt`, `sentAt`, `updatedAt`.
- `factory fromJson` tolerante a `null`.

2. `gazetta_detail.dart`
- Misma base de `GazettaItem` + `jsonPayload` tipado.
- Excluir `html_version` y `deliveries` (no app end-user).

3. `gazetta_payload.dart`
- Tipado de `json_payload`:
  - `summary` (String?)
  - `highlights` (List<String>)
  - `matches` (List<GazettaMatch>)
  - `sections` (List<GazettaSection>)
- Modelos auxiliares: `GazettaMatch`, `GazettaSection`.
- Parse defensivo para cambios de backend.

4. `gazetta_meta.dart`
- `id`, `updatedAt`, `seen`, `seenAt` (si backend lo envía), etc.

5. `gazetta_feed_response.dart`
- Wrapper de feed: `{ data: GazettaDetail? }`.
- Debe aceptar `data: null`.

6. `gazzetta_models.dart`
- Barrel export para imports limpios.

Nota: si conviene evitar duplicación, `GazettaDetail` puede extender/componer `GazettaItem`.

### 2) Capa datos / repository

#### Opción recomendada (mínimo impacto)
Agregar métodos en `lib/core/network/api_repository.dart`:
- `Future<GazettaDetail?> getGazettaFeed()`
- `Future<PaginatedResponse<GazettaItem>> getGazettaHistory({...})`
- `Future<GazettaDetail> getGazettaDetail(int id)`
- `Future<GazettaMeta> getGazettaMeta(int id)`
- `Future<void> markGazettaSeen(int id)`

Ventaja: reutiliza el `ApiRepository` ya registrado en `AppBinding`.

#### Manejo de errores
Mapeo explícito con `DioException`:
- `404` en rutas Gazzetta => tratar como módulo no disponible.
- `401/403` => propagar para flujo auth existente (mensaje estándar de sesión/permisos).
- `connectionTimeout`, `receiveTimeout`, `connectionError` => mensaje consistente: “Sin conexión o tiempo de espera agotado”.

Recomendación técnica:
- Crear excepción de dominio simple:
  - `lib/core/network/gazzetta_exceptions.dart`
  - `class GazettaModuleUnavailableException implements Exception {}`
- Lanzarla sólo cuando `statusCode == 404` en endpoints Gazzetta.

### 3) Dominio / estado de pantalla
Crear módulo nuevo `lib/modules/gazzetta/`:
- `gazzetta_binding.dart`
- `gazzetta_controller.dart`
- `gazzetta_view.dart`
- `index.dart`

Y detalle:
- `lib/modules/gazzetta_detail/`
  - `gazzetta_detail_binding.dart`
  - `gazzetta_detail_controller.dart`
  - `gazzetta_detail_view.dart`
  - `index.dart`

#### Responsabilidades controller de listado
- Cargar feed + página 1 de history en paralelo.
- Paginación incremental (`loadMore`) usando `PaginatedResponse`.
- Estados: `isLoading`, `isLoadingMore`, `isModuleUnavailable`, `error`.
- Si feed retorna `null`, mostrar bloque vacío no fatal.

#### Responsabilidades controller detalle
- `onInit`: leer `gazettaId`.
- `loadDetail` + `loadMeta`.
- Ejecutar `markSeen(id)` al abrir (fire-and-forget con manejo de error no bloqueante).
- Reconsultar `meta` opcionalmente después de `markSeen` para refrescar badge/estado.

### 4) UI mínima

#### Pantalla “Gazzetta”
- Sección superior: card del feed (última gazetta).
- Debajo: lista histórica paginada (ListView + loader al final).
- Estados:
  - Loading inicial
  - Vacío (sin feed e historial)
  - Error genérico
  - Módulo no disponible (si 404)

#### Pantalla detalle
Render desde `json_payload`:
- `summary` (bloque de texto)
- `highlights` (chips/lista)
- `matches` (imagen/foto + rival + marcador)
- `sections` (título + contenido)

Reglas de robustez:
- Si falta alguna sección, ocultar ese bloque.
- `image` inválida: fallback icono.

### 5) Navegación e integración Home

## Rutas
Actualizar:
- `lib/routes/app_routes_names.dart`
  - `static const gazzetta = '/gazzetta';`
  - `static const gazzettaDetail = '/gazzettaDetail';`
- `lib/routes/app_routes.dart`
  - importar módulos/bindings.
  - agregar `GetPage` para lista y detalle.

## Tab/menú
Patrón más consistente con la app actual:
1. Agregar tab key `gazzetta` en `FlavorConfig.tabsByFlavorAndRole` para roles objetivo.
2. En `HomeController`:
- registrar `GazzettaTabController` similar a `NoticesTabController`, o integrar con nuevo módulo completo según prefieras.
- al cargar tab, intentar feed/history.
- si recibe `GazettaModuleUnavailableException`, marcar estado para ocultar tab o mostrar estado.

Decisión recomendada para mañana:
- Primera entrega: **mostrar estado “Módulo no disponible” dentro del tab** (menos riesgo de romper `TabController.length`).
- Segunda iteración: ocultado dinámico del tab antes de construir `TabController`.

### 6) Pruebas

## Unit tests de modelos
Crear en `test/core/models/gazzetta/`:
- `gazetta_feed_response_test.dart`
- `gazetta_detail_test.dart`
- `gazetta_payload_test.dart`
- `gazetta_meta_test.dart`

Casos mínimos:
- parse normal
- campos opcionales null
- listas vacías
- payload parcial

## Tests repository con HTTP mock/fake
Crear en `test/core/network/api_repository_gazzetta_test.dart` usando `Fake Dio` (estilo existente):
- success feed/history/detail/meta/seen
- 404 -> `GazettaModuleUnavailableException`
- error de red (`DioExceptionType.connectionError`) -> excepción/mensaje esperado

## Smoke test UI (opcional si da tiempo)
- `gazzetta_controller_test.dart` con repository fake para estados (`loading/success/unavailable/error`).

## Plan de ejecución (mañana)
1. Crear modelos Gazzetta + tests de parseo.
2. Extender `ApiRepository` con métodos y mapeo de errores + tests.
3. Construir módulos `gazzetta` y `gazzetta_detail` (controlador + vista mínima).
4. Integrar rutas y tab en Home.
5. Ejecutar `flutter analyze` + `flutter test` y corregir.

## Riesgos y decisiones abiertas
- Forma exacta de `json_payload` puede variar entre organizaciones.
  - Mitigación: parser defensivo + UI tolerante.
- Ocultar tab en caliente puede desalinear `TabController.length`.
  - Mitigación: en v1 mostrar estado en tab; ocultado dinámico como mejora posterior.
- `history` puede devolver wrapper distinto (`data/meta` vs estructura Laravel plana).
  - Mitigación: validar primer response real y ajustar parser antes de cerrar.

## Lista estimada de archivos a crear/modificar mañana

### Nuevos
- `lib/core/models/gazzetta/gazetta_item.dart`
- `lib/core/models/gazzetta/gazetta_detail.dart`
- `lib/core/models/gazzetta/gazetta_payload.dart`
- `lib/core/models/gazzetta/gazetta_meta.dart`
- `lib/core/models/gazzetta/gazetta_feed_response.dart`
- `lib/core/models/gazzetta/gazzetta_models.dart`
- `lib/core/network/gazzetta_exceptions.dart`
- `lib/modules/gazzetta/gazzetta_binding.dart`
- `lib/modules/gazzetta/gazzetta_controller.dart`
- `lib/modules/gazzetta/gazzetta_view.dart`
- `lib/modules/gazzetta/index.dart`
- `lib/modules/gazzetta_detail/gazzetta_detail_binding.dart`
- `lib/modules/gazzetta_detail/gazzetta_detail_controller.dart`
- `lib/modules/gazzetta_detail/gazzetta_detail_view.dart`
- `lib/modules/gazzetta_detail/index.dart`
- `test/core/models/gazzetta/gazetta_feed_response_test.dart`
- `test/core/models/gazzetta/gazetta_detail_test.dart`
- `test/core/models/gazzetta/gazetta_payload_test.dart`
- `test/core/models/gazzetta/gazetta_meta_test.dart`
- `test/core/network/api_repository_gazzetta_test.dart`

### Modificados
- `lib/core/network/api_repository.dart`
- `lib/core/config/flavor_config.dart`
- `lib/modules/home/home_controller.dart`
- `lib/modules/home/home_view.dart`
- `lib/routes/app_routes_names.dart`
- `lib/routes/app_routes.dart`

## Criterio de aceptación
- Build compila.
- Feed, history y detalle renderizan.
- `markSeen` se ejecuta al abrir detalle.
- 404 de Gazzetta se presenta como módulo no disponible.
- Tests de parseo y repository verdes.
