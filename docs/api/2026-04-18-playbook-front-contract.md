# Playbook Front Contract - 2026-04-18

Base: `/api/playbook`

Auth:
- `Authorization: Bearer {token}`
- `X-Organization-Id: {organizationId}` recomendado cuando el usuario maneja más de una organización

## Cambios de esta entrega

1. Se agregó soporte de instrucciones por token/posición en jugadas `mode = go`.
2. Se agregó like por jugada para confirmar quién ya la vio.
3. Se ajustó el borrado de feedback para que un `coach` con acceso real a la jugada sí pueda borrarlo.

## Roles

- `coach`, `admin`, `superadmin` pueden crear/editar/eliminar jugadas.
- `player` puede ver jugadas accesibles y dar like.
- `coach` con acceso a la jugada puede borrar feedback.

## Objeto `PlaybookPlayer`

Se usa dentro de `players` en jugadas `mode = go`.

### Request

```json
{
  "id": "QB",
  "name": "QB",
  "infoText": "Lee primero al safety y si baja ataca seam.",
  "x": 120,
  "y": 240,
  "isOffense": true
}
```

Campos:
- `id`: `string`, requerido. Identificador lógico del token.
- `name`: `string`, requerido, max `30`.
- `infoText`: `string|null`, opcional, max `3000`.
- `x`: `number`, requerido.
- `y`: `number`, requerido.
- `isOffense`: `boolean|null`, opcional.

### Response

```json
{
  "id": "QB",
  "name": "QB",
  "infoText": "Lee primero al safety y si baja ataca seam.",
  "hasInfo": true,
  "x": 120,
  "y": 240,
  "isOffense": true
}
```

Campos nuevos para frontend:
- `infoText`: texto guardado por el coach.
- `hasInfo`: `boolean`, útil para mostrar icono sin revisar manualmente el texto.

## Objeto `PlayLikes`

```json
{
  "count": 2,
  "is_liked": true,
  "users": [
    {
      "id": 9,
      "name": "Juan Coach",
      "role": "coach",
      "profile_photo_url": "https://...",
      "liked_at": "2026-04-18T16:00:00.000000Z"
    }
  ]
}
```

Campos:
- `count`: total de likes.
- `is_liked`: si el usuario autenticado actual ya dio like.
- `users`: lista de usuarios que ya confirmaron vista.

## Endpoint actualizado: Listar jugadas

`GET /api/playbook/plays`

Query params opcionales:
- `category_id`
- `type`
- `side` = `offense|defense`
- `mode` = `go|attachment`
- `q`
- `per_page`

### Response shape relevante

```json
{
  "data": [
    {
      "id": "15",
      "alias": "Trips Right 34",
      "type": "run",
      "side": "offense",
      "mode": "go",
      "playersCount": 7,
      "category_id": 12,
      "category": {
        "id": 12,
        "name": "Juvenil A",
        "code": "JVA",
        "slug": "juvenil-a"
      },
      "shared_categories": [],
      "notes": "Abrir con motion",
      "players": [
        {
          "id": "QB",
          "name": "QB",
          "infoText": "Lee primero al safety y si baja ataca seam.",
          "hasInfo": true,
          "x": 120,
          "y": 240,
          "isOffense": true
        }
      ],
      "routesByPlayer": {},
      "attachment": null,
      "likes": {
        "count": 2,
        "is_liked": true,
        "users": []
      },
      "created_at": "2026-04-13T15:00:00.000000Z",
      "updated_at": "2026-04-13T15:00:00.000000Z"
    }
  ],
  "links": {},
  "meta": {}
}
```

### Cambios importantes

- `players[].infoText` nuevo.
- `players[].hasInfo` nuevo.
- `likes` nuevo.

## Endpoint actualizado: Ver detalle de jugada

`GET /api/playbook/plays/{play}`

Devuelve exactamente la misma estructura de una jugada del listado, incluyendo:
- `players[].infoText`
- `players[].hasInfo`
- `likes`

## Endpoint actualizado: Crear jugada tipo pizarra

`POST /api/playbook/plays/go`

Content-Type:
- `application/json`

### Body

```json
{
  "category_id": 12,
  "shared_category_ids": [14, 16],
  "alias": "Trips Right 34",
  "type": "run",
  "side": "offense",
  "notes": "Abrir con motion",
  "players": [
    {
      "id": "QB",
      "name": "QB",
      "infoText": "Lee primero al safety y si baja ataca seam.",
      "x": 120,
      "y": 240,
      "isOffense": true
    }
  ],
  "routesByPlayer": {
    "QB": [
      {
        "origin": { "x": 120, "y": 240 },
        "points": [
          { "x": 120, "y": 240 },
          { "x": 180, "y": 260 }
        ]
      }
    ]
  }
}
```

### Validaciones relevantes

- `category_id`: requerido.
- `alias`: requerido, `string`, max `120`.
- `type`: requerido, `string`, max `40`.
- `side`: opcional, `offense|defense`.
- `players`: requerido, array con mínimo `1`.
- `players.*.id`: requerido, max `32`.
- `players.*.name`: requerido, max `30`.
- `players.*.infoText`: opcional, max `3000`.
- `routesByPlayer`: opcional.

### Response

Devuelve la jugada creada con la misma estructura de `GET /plays/{play}`.

## Endpoint actualizado: Editar jugada tipo pizarra

`PUT /api/playbook/plays/{play}`

Content-Type:
- `application/json`

### Body

Misma estructura que `POST /api/playbook/plays/go`.

### Comportamiento importante

- Si mandan `players`, se reemplaza completamente el set previo de tokens.
- Si mandan `infoText`, se guarda por token.
- Si mandan `infoText: ""`, backend lo normaliza a `null`.
- Si mandan `shared_category_ids`, se reemplaza el set actual de categorías compartidas.

### Response

Devuelve la jugada actualizada con:
- `players[].infoText`
- `players[].hasInfo`
- `likes`

## Endpoint nuevo: Toggle like de una jugada

`POST /api/playbook/plays/{play}/like`

### Uso

- Si el usuario no había dado like, lo crea.
- Si ya había dado like, lo elimina.

### Quién puede usarlo

- `coach`
- `player`
- `admin`
- `superadmin`

Siempre que el usuario tenga acceso a la jugada.

### Response

```json
{
  "ok": true,
  "is_liked": true,
  "likes": {
    "count": 3,
    "is_liked": true,
    "users": [
      {
        "id": 9,
        "name": "Juan Coach",
        "role": "coach",
        "profile_photo_url": "https://...",
        "liked_at": "2026-04-18T16:00:00.000000Z"
      }
    ]
  }
}
```

Notas:
- `likes.is_liked` refleja el estado final después del toggle.
- Este like puede usarse como confirmación de que ya vieron la jugada.

## Endpoint con comportamiento actualizado: Listar feedback

`GET /api/playbook/plays/{play}/feedback`

### Response relevante

```json
{
  "data": [
    {
      "id": 22,
      "play_id": 15,
      "category_id": 12,
      "category_name": "Juvenil A",
      "author_name": "Juan Coach",
      "author": {
        "id": 9,
        "name": "Juan Coach",
        "role": "coach",
        "profile_photo_url": "https://..."
      },
      "message": "Revisen el timing del slot",
      "attachment": null,
      "can_delete": true,
      "created_at": "2026-04-13T15:20:00.000000Z"
    }
  ]
}
```

### Cambio importante

- `can_delete` ahora sí representa correctamente si el `coach` autenticado puede borrar ese feedback por tener acceso a la jugada.

## Endpoint con comportamiento actualizado: Eliminar feedback

`DELETE /api/playbook/plays/{play}/feedback/{feedback}`

### Response

```json
{
  "ok": true
}
```

### Cambio importante

- Un `coach` con acceso por categoría principal o categoría compartida puede borrar feedback.

## Recomendaciones para frontend

- Usar `players[].hasInfo` para mostrar el icono de ayuda/detalle.
- Al abrir el detalle del token, leer `players[].infoText`.
- Usar `likes.users` para avatar stack o lista de confirmación.
- Usar `likes.is_liked` para pintar el estado del botón actual.
- Si quieren refresco ligero tras like, pueden actualizar solo el bloque `likes` con la respuesta del `POST /like`.
