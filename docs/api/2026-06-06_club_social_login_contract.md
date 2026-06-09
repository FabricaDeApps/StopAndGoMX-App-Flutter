# Club App Social Login Contract

Fecha: 2026-06-06  
Estado: Implementado en backend

Base path: `/api/auth`

## Alcance
Este documento cubre solo el endpoint de login social para la app de clubes/organizations:
- `POST /api/auth/login-social`

## Objetivo
Permitir login con Google o Apple usando un `id_token` de Firebase Auth ya validable por backend, sin enviar password del usuario.

Backend:
- valida el `id_token` contra Firebase
- exige `email_verified = true`
- toma el `email` del token
- busca un usuario existente por identidad social o por email
- vincula `firebase_uid`, `firebase_project` y `auth_provider`
- valida organización, membresía, rol y estado
- emite `access_token` y `refresh_token` con el mismo flujo actual

## Reglas generales
- `provider`: `google | apple`
- `id_token`: token de Firebase Auth entregado por el front
- `so`: `android | ios | web`
- `device_name`: opcional
- `device_token`: opcional
- `organization_id`: requerido
- No se crea usuario automáticamente si no existe uno previo con ese correo
- Si el token social ya está vinculado de forma inconsistente con otro registro, backend responde conflicto

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
- `USER_NOT_FOUND`
- `USER_INACTIVE`
- `ORG_USER_NOT_FOUND`
- `ORG_USER_INACTIVE`
- `SUBSCRIPTION_REQUIRED`

---

## `POST /api/auth/login-social`

Login social para usuarios existentes de la app de clubes.

### Request
```json
{
  "organization_id": 21,
  "provider": "google",
  "id_token": "firebase-id-token",
  "so": "ios",
  "device_name": "iPhone 15",
  "device_token": "fcm-token",
  "active_role": "coach"
}
```

### Campos
- `organization_id`: requerido, integer
- `provider`: requerido, `google | apple`
- `id_token`: requerido, string
- `so`: requerido, `android | ios | web`
- `device_name`: opcional, string
- `device_token`: opcional, string
- `active_role`: opcional, uno de los roles válidos del usuario en esa organización

### Reglas
- Backend usa el `email` del token social, no el email enviado por cliente
- El usuario debe existir previamente
- Si no es `superadmin`, además debe pertenecer a la `organization_id` enviada
- Si existe subdominio resuelto en backend, la organización del request debe coincidir
- Si la organización está bloqueada por suscripción y el usuario no es `superadmin`, responde error

### Response `200`
```json
{
  "user": {
    "id": 33,
    "name": "Luis Carlin",
    "email": "luis@gmail.com",
    "phone": "4421234567",
    "curp": null,
    "birthdate": null,
    "role": "coach",
    "roles": ["coach", "staff"],
    "primary_role": "coach",
    "active_role": "coach",
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

### Errores
- `401` si el token social es inválido o el usuario está inactivo
- `403` si no pertenece a la organización, no tiene rol permitido o la suscripción bloquea acceso
- `404` si no existe usuario con ese correo
- `409` si hay conflicto de vinculación social
- `422` error de validación

---

## Notas para frontend
- No mandar el email como fuente de verdad; backend usa el email del `id_token`
- `id_token` debe salir de Firebase Auth después de login con Google o Apple
- Si backend responde `USER_NOT_FOUND`, la cuenta social fue válida pero no existe usuario previo en nuestra base
- Si backend responde `SOCIAL_IDENTITY_CONFLICT`, hay que revisar manualmente una vinculación previa incorrecta
- Si mandan `active_role`, debe ser un rol realmente permitido para ese usuario en esa organización
