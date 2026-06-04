# App Usage Sessions Front Contract

Fecha: 2026-06-03

## Objetivo

Este documento define los endpoints que frontend debe consumir para medir:

- tiempo real de uso en app
- sesiones por usuario
- comparativo de uso entre `organization` y `league`

El backend ya expone estos endpoints y usa esta informacion para alimentar el dashboard CRM `App Usage`.

## Base

- Auth requerida: `Bearer token` con `auth:sanctum`
- Content-Type: `application/json`
- Prefijo API: `/api/app-usage/sessions`

## Endpoints

### 1. Iniciar sesion de uso

- Metodo: `POST`
- URL: `/api/app-usage/sessions/start`

Payload:

```json
{
  "session_key": "550e8400-e29b-41d4-a716-446655440000",
  "platform": "ios",
  "app_version": "2.8.0",
  "device_id": "ios-iphone15pro-9F2A",
  "device_name": "iPhone 15 Pro",
  "started_at": "2026-06-03T10:15:00-06:00",
  "meta": {
    "screen": "home",
    "source": "app_open"
  }
}
```

Notas:

- `session_key` es opcional, pero frontend debe generarlo y persistirlo durante la sesion activa.
- Si no se manda, backend genera uno.
- Recomendado usar UUID v4.
- `started_at` es opcional. Si no se manda, backend usa `now()`.

Response esperada:

```json
{
  "success": true,
  "session_key": "550e8400-e29b-41d4-a716-446655440000",
  "session_id": 123,
  "started_at": "2026-06-03T10:15:00-06:00",
  "last_seen_at": "2026-06-03T10:15:00-06:00"
}
```

### 2. Heartbeat de sesion activa

- Metodo: `POST`
- URL: `/api/app-usage/sessions/heartbeat`

Payload:

```json
{
  "session_key": "550e8400-e29b-41d4-a716-446655440000",
  "last_seen_at": "2026-06-03T10:18:00-06:00",
  "meta": {
    "screen": "payments",
    "network": "wifi"
  }
}
```

Response esperada:

```json
{
  "success": true,
  "session_key": "550e8400-e29b-41d4-a716-446655440000",
  "duration_seconds": 180,
  "last_seen_at": "2026-06-03T10:18:00-06:00"
}
```

### 3. Cerrar sesion de uso

- Metodo: `POST`
- URL: `/api/app-usage/sessions/end`

Payload:

```json
{
  "session_key": "550e8400-e29b-41d4-a716-446655440000",
  "ended_at": "2026-06-03T10:20:15-06:00",
  "meta": {
    "reason": "background"
  }
}
```

Response esperada:

```json
{
  "success": true,
  "session_key": "550e8400-e29b-41d4-a716-446655440000",
  "duration_seconds": 315,
  "ended_at": "2026-06-03T10:20:15-06:00"
}
```

## Reglas de frontend

Frontend debe seguir este flujo:

1. Generar un `session_key` nuevo cuando la app entra a foreground y no exista una sesion activa.
2. Llamar `start` una sola vez por sesion activa.
3. Llamar `heartbeat` cada `30` a `60` segundos mientras la app siga en foreground.
4. Llamar `end` cuando la app pase a background, logout o cierre de sesion.
5. Limpiar el `session_key` local despues de `end`.

## Recomendacion de frecuencia

- `heartbeat` recomendado: cada `45 segundos`
- Si la app cambia de pantalla, no es necesario abrir una sesion nueva
- Solo actualizar `meta.screen` en el siguiente heartbeat si se quiere trazabilidad ligera

## Comportamiento esperado

- `organization_user` se clasifica automaticamente como uso de organization
- `league_team_user` y `league_admin_user` se clasifican automaticamente como uso de league
- El frontend no necesita mandar manualmente `actor_type`
- El backend resuelve contexto con el usuario autenticado

## Errores esperados

### `401 Unauthorized`

Pasa cuando no hay token valido.

### `403 Forbidden`

Pasa cuando el `session_key` pertenece a otro usuario.

### `422 Unprocessable Entity`

Pasa cuando:

- falta `session_key` en `heartbeat` o `end`
- la sesion ya fue cerrada
- el payload no cumple validacion

## Recomendacion de implementacion

Persistir localmente estos campos mientras la sesion este activa:

```json
{
  "session_key": "550e8400-e29b-41d4-a716-446655440000",
  "started_at": "2026-06-03T10:15:00-06:00",
  "platform": "ios",
  "app_version": "2.8.0",
  "device_id": "ios-iphone15pro-9F2A"
}
```

## Ejemplo de flujo

### App abre

`POST /api/app-usage/sessions/start`

### 45 segundos despues

`POST /api/app-usage/sessions/heartbeat`

### 90 segundos despues

`POST /api/app-usage/sessions/heartbeat`

### Usuario manda app a background

`POST /api/app-usage/sessions/end`

## Checklist para frontend

- generar UUID v4 por sesion
- guardar `session_key` localmente
- mandar bearer token en los 3 endpoints
- lanzar `start` en foreground
- lanzar `heartbeat` periodico
- lanzar `end` en background/logout
- evitar multiples `start` con el mismo usuario al mismo tiempo en la misma sesion activa

