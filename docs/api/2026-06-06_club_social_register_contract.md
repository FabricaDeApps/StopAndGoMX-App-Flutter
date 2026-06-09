# Club App Social Register Contract

Fecha: 2026-06-06  
Estado: Implementado en backend

Base path: `/api/auth`

## Alcance
Este documento cubre solo:
- `POST /api/auth/register-social`

## Objetivo
Registrar o anexar una cuenta social verificada a una organización del app de clubes, y devolver sesión lista para usar.

## Reglas generales
- Usa `id_token` de Firebase Auth
- Backend toma el `email` del token, no del payload
- Si el usuario no existe, lo crea
- Si el usuario ya existe y no pertenece a la organización, lo anexa
- Si ya existía y ya pertenecía a la organización, responde sesión válida de forma idempotente

## Roles permitidos
- `manager`
- `coach`
- `parent`
- `player`

## Error shape de negocio/auth
```json
{
  "message": "Texto legible",
  "code": "ERROR_CODE"
}
```

## Error shape de validación
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "field": ["mensaje"]
  }
}
```

Status: `422`

## Códigos de error esperados
- `SOCIAL_AUTH_INVALID`
- `SOCIAL_IDENTITY_CONFLICT`
- `PLAYER_ALREADY_LINKED`

---

## `POST /api/auth/register-social`

### Request
```json
{
  "organization_id": 21,
  "provider": "google",
  "id_token": "firebase-id-token",
  "role": "player",
  "name": "Luis Carlin",
  "phone": "4421234567",
  "curp": null,
  "birthdate": "2010-05-01",
  "so": "ios",
  "device_name": "iPhone 15",
  "device_token": "fcm-token",
  "active_role": "player"
}
```

### Campos
- `organization_id`: requerido, integer
- `provider`: requerido, `google | apple`
- `id_token`: requerido, string
- `role`: requerido, `manager | coach | parent | player`
- `name`: opcional, string
- `phone`: opcional, string
- `curp`: opcional, string de 18 caracteres
- `birthdate`: opcional, fecha
- `so`: requerido, `android | ios | web`
- `device_name`: opcional, string
- `device_token`: opcional, string
- `active_role`: opcional, uno de los roles válidos del usuario en esa organización

### Regla especial para `player`
- Si `role = player` y existe un jugador en esa organización con el mismo correo, backend lo enlaza a la cuenta
- Si ese jugador ya está ligado a otro usuario distinto, responde error

### Response `201` o `200`
```json
{
  "message": "Usuario registrado correctamente.",
  "user": {
    "id": 33,
    "name": "Luis Carlin",
    "email": "luis@gmail.com",
    "phone": "4421234567",
    "curp": null,
    "birthdate": "2010-05-01",
    "role": "player",
    "roles": ["player"],
    "primary_role": "player",
    "active_role": "player",
    "so": "ios",
    "device_token": "fcm-token",
    "device_name": "iPhone 15"
  },
  "organization": {
    "id": 21,
    "name": "Club Lite Norte",
    "slug": "club-lite-norte",
    "logo_url": null,
    "primary_color": "#18C490",
    "secondary_color": "#22D3EE",
    "pay_card_enabled": true
  },
  "token_type": "Bearer",
  "access_token": "xxx",
  "access_expires_in_minutes": 60,
  "refresh_token": "yyy",
  "refresh_expires_at": "2026-07-06T23:10:00-06:00"
}
```

### Status esperados
- `201` si creó usuario nuevo o anexó un usuario existente a la organización
- `200` si la cuenta ya estaba registrada y simplemente se inició sesión

### Errores
- `401` si el token social es inválido
- `409` si hay conflicto de vinculación social
- `422` si hay error de validación o el jugador ya está ligado a otro usuario

## Notas para frontend
- No mandar email en el request como fuente de verdad
- Si frontend ya sabe que el usuario no existe, puede ir directo a este endpoint
- Si frontend no sabe, el flujo sugerido sigue siendo:
1. `login-social`
2. si no existe, `register-social`
