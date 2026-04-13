# Playbook API - 2026-04-13

Base: `/api/playbook`

Autenticación: `Authorization: Bearer {token}`

Organización activa:
- Se toma de `X-Organization-Id` si se envía.
- Si no, usa `organization_id` del usuario autenticado.

## Reglas de acceso

- `coach`, `admin`, `superadmin` pueden crear, editar, compartir y eliminar jugadas.
- `player` puede consultar jugadas de sus categorías y enviar feedback.
- El coach solo puede operar categorías que tenga asignadas.
- El coach puede borrar comentarios/feedback de la jugada.
- Una jugada se puede ver si pertenece a la categoría principal del usuario o a una categoría compartida con él.

## 1. Obtener categorías disponibles para playbook

`GET /api/playbook/categories`

Respuesta:

```json
{
  "data": [
    {
      "id": 12,
      "name": "Juvenil A",
      "code": "JVA",
      "slug": "juvenil-a"
    }
  ]
}
```

## 2. Listar jugadas

`GET /api/playbook/plays`

Query params opcionales:
- `category_id`
- `type`
- `side` = `offense|defense`
- `mode` = `go|attachment`
- `q`
- `per_page`

Respuesta:

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
      "shared_categories": [
        {
          "id": 14,
          "name": "Varsity",
          "code": "VAR",
          "slug": "varsity"
        }
      ],
      "notes": "Abrir con motion",
      "players": [],
      "routesByPlayer": {},
      "attachment": null,
      "created_at": "2026-04-13T15:00:00.000000Z",
      "updated_at": "2026-04-13T15:00:00.000000Z"
    }
  ],
  "links": {},
  "meta": {}
}
```

## 3. Ver detalle de jugada

`GET /api/playbook/plays/{play}`

Devuelve la misma estructura de una jugada.

## 4. Crear jugada tipo pizarra

`POST /api/playbook/plays/go`

Body JSON:

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

Notas:
- `shared_category_ids` es opcional.
- La categoría principal también controla ownership de la jugada.

## 5. Crear jugada con video/archivo adjunto

`POST /api/playbook/plays/attachment`

Content-Type: `multipart/form-data`

Campos:
- `category_id`
- `shared_category_ids[]` opcional
- `alias`
- `type`
- `side`
- `players_count`
- `notes` opcional
- `file`

Tipos permitidos en `file`:
- video `mp4`, `mov`, `webm`
- también acepta `pdf`, `jpg`, `png`, `webp`

Uso recomendado para frontend de clubes:
- mandar video cuando sea jugada para revisión de jugadores.

## 6. Editar jugada tipo pizarra

`PUT /api/playbook/plays/{play}`

Body JSON igual a `POST /plays/go`.

Notas:
- Solo aplica para jugadas `mode = go`.
- Si mandan `shared_category_ids`, reemplaza el set actual de categorías compartidas.

## 7. Compartir una jugada existente con más categorías

`POST /api/playbook/plays/{play}/share`

Body JSON:

```json
{
  "category_ids": [14, 16]
}
```

Notas:
- Agrega categorías compartidas nuevas.
- No cambia la categoría principal de la jugada.

## 8. Eliminar jugada

`DELETE /api/playbook/plays/{play}`

Respuesta:

```json
{
  "ok": true
}
```

## 9. Listar feedback de una jugada

`GET /api/playbook/plays/{play}/feedback`

Query params opcionales:
- `limit` default `50`

Respuesta:

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
      "attachment": {
        "url": "https://...",
        "name": "ajuste.mp4",
        "mimeType": "video/mp4",
        "sizeBytes": 1450012,
        "kind": "video"
      },
      "can_delete": true,
      "created_at": "2026-04-13T15:20:00.000000Z"
    }
  ]
}
```

## 10. Crear feedback en una jugada

`POST /api/playbook/plays/{play}/feedback`

Content-Type: `multipart/form-data`

Campos:
- `message` opcional si se manda `file`
- `file` opcional si se manda `message`

Regla:
- Debe venir al menos uno: texto o archivo.

Tipos permitidos en `file`:
- imagen `jpg`, `png`, `webp`, `heic`, `heif`
- video `mp4`, `mov`, `webm`

Ejemplo:

```bash
curl -X POST /api/playbook/plays/15/feedback \
  -H "Authorization: Bearer {token}" \
  -F "message=Creo que aquí la ruta debe romper antes" \
  -F "file=@/tmp/revision.mp4"
```

## 11. Eliminar feedback de una jugada

`DELETE /api/playbook/plays/{play}/feedback/{feedback}`

Respuesta:

```json
{
  "ok": true
}
```

Notas:
- Solo coach/admin/superadmin con acceso a la jugada pueden borrar feedback.

## Consideraciones para frontend

- `shared_categories` sirve para mostrar en qué categorías ya fue compartida la jugada.
- `mode = go` trae `players` y `routesByPlayer`.
- `mode = attachment` trae `attachment`.
- El feedback soporta texto, imagen o video.
- `can_delete` ayuda a pintar acción de borrar en el muro de feedback.
