# Social Feed Club App API

Fecha: 2026-04-24

## Alcance

Contrato backend para el social feed de la app de clubes.

Incluye:

- feed paginado
- crear post
- detalle de post
- comentarios
- likes en posts
- likes en comentarios
- búsqueda de usuarios para mencionar
- borrado de post/comentario
- uploads de imágenes y videos con Cloudflare

No aplica para leagues.

## Auth

Todos los endpoints requieren:

- `Authorization: Bearer <token>`
- `auth:sanctum`

El backend siempre filtra por la organización activa del usuario autenticado.

## Reglas de negocio

- Un post pertenece a una organización.
- Un usuario solo ve posts de su organización.
- Un post puede tener:
  - `caption`
  - menciones
  - cero o más medios
- Un comentario pertenece a un post y a una organización.
- El owner puede borrar sus propios posts y comentarios.
- Un `admin` puede borrar cualquier post o comentario de su organización.
- `manager` y `coach` no pueden borrar contenido ajeno.
- Likes funcionan como toggle.
- Máximo 10 archivos por post.
- Para media se usa el mismo patrón que games:
  - `init upload`
  - upload directo desde app a Cloudflare
  - `confirm`

## Shape base de post

```json
{
  "id": 987,
  "author": {
    "id": 21,
    "name": "Juan Perez",
    "role_label": "Coach",
    "avatar_url": "https://midominio.com/storage/users/21/avatar.jpg"
  },
  "time_label": "hace 5 minutos",
  "created_at": "2026-04-24T18:30:00Z",
  "caption": "Gran entrenamiento hoy",
  "mentions": [
    {
      "id": 12,
      "name": "Luis Garcia"
    }
  ],
  "media": [
    {
      "id": 5001,
      "type": "image",
      "url": "https://imagedelivery.net/.../public",
      "thumbnail_url": "https://imagedelivery.net/.../public",
      "duration_label": null,
      "order": 0,
      "width": 1200,
      "height": 900
    },
    {
      "id": 5002,
      "type": "video",
      "url": "https://videodelivery.net/UID/manifest/video.m3u8",
      "thumbnail_url": "https://videodelivery.net/UID/thumbnails/thumbnail.jpg",
      "duration_label": "0:18",
      "order": 1,
      "width": 1080,
      "height": 1920
    }
  ],
  "likes_count": 10,
  "comments_count": 2,
  "is_liked": false,
  "comments_preview": [
    {
      "id": 701,
      "author": {
        "id": 90,
        "name": "Andrea Soto",
        "avatar_url": "https://midominio.com/storage/users/90/avatar.jpg"
      },
      "message": "Buenísimo",
      "time_label": "hace 1 minuto",
      "created_at": "2026-04-24T18:31:00Z",
      "likes_count": 1,
      "is_liked": false
    }
  ],
  "comments": null
}
```

## Shape base de comentario

```json
{
  "id": 7009,
  "author": {
    "id": 21,
    "name": "Juan Perez",
    "avatar_url": "https://midominio.com/storage/users/21/avatar.jpg"
  },
  "message": "Gran trabajo equipo",
  "time_label": "Ahora",
  "created_at": "2026-04-24T18:35:00Z",
  "likes_count": 0,
  "is_liked": false
}
```

## 1. Listar feed

`GET /api/social/posts?page=1&per_page=10`

### Query params

- `page`: opcional, default `1`
- `per_page`: opcional, min `1`, max `30`, default `10`

### Response `200`

```json
{
  "data": [
    {
      "id": 987,
      "author": {
        "id": 21,
        "name": "Juan Perez",
        "role_label": "Coach",
        "avatar_url": "https://midominio.com/storage/users/21/avatar.jpg"
      },
      "time_label": "hace 5 minutos",
      "created_at": "2026-04-24T18:30:00Z",
      "caption": "Gran entrenamiento hoy",
      "mentions": [
        {
          "id": 12,
          "name": "Luis Garcia"
        }
      ],
      "media": [],
      "likes_count": 14,
      "comments_count": 3,
      "is_liked": true,
      "comments_preview": [],
      "comments": null
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 10,
    "has_more": true,
    "next_cursor": null
  }
}
```

## 2. Crear post

`POST /api/social/posts`

### Request JSON

```json
{
  "caption": "Gran entrenamiento hoy",
  "mentions": [12, 45]
}
```

### Reglas

- `caption`: `nullable|string|max:3000`
- `mentions`: `nullable|array`
- `mentions.*`: user ids válidos dentro de la organización visible
- por ahora el backend acepta crear post con:
  - caption
  - o menciones
- la media se adjunta después con endpoints Cloudflare sobre el `post`

### Response `201`

```json
{
  "data": {
    "id": 987,
    "author": {
      "id": 21,
      "name": "Juan Perez",
      "role_label": "Coach",
      "avatar_url": "https://midominio.com/storage/users/21/avatar.jpg"
    },
    "time_label": "Ahora",
    "created_at": "2026-04-24T18:30:00Z",
    "caption": "Gran entrenamiento hoy",
    "mentions": [
      {
        "id": 12,
        "name": "Luis Garcia"
      }
    ],
    "media": [],
    "likes_count": 0,
    "comments_count": 0,
    "is_liked": false,
    "comments_preview": [],
    "comments": null
  }
}
```

## 3. Ver detalle de post

`GET /api/social/posts/{post}`

### Response `200`

```json
{
  "data": {
    "id": 987,
    "author": {
      "id": 21,
      "name": "Juan Perez",
      "role_label": "Coach",
      "avatar_url": "https://midominio.com/storage/users/21/avatar.jpg"
    },
    "time_label": "hace 5 minutos",
    "created_at": "2026-04-24T18:30:00Z",
    "caption": "Gran entrenamiento hoy",
    "mentions": [],
    "media": [],
    "likes_count": 14,
    "comments_count": 3,
    "is_liked": true,
    "comments_preview": [],
    "comments": [
      {
        "id": 7001,
        "author": {
          "id": 33,
          "name": "Mariana Ruiz",
          "avatar_url": "https://midominio.com/storage/users/33/avatar.jpg"
        },
        "message": "Se ve brutal",
        "time_label": "hace 2 minutos",
        "created_at": "2026-04-24T18:33:00Z",
        "likes_count": 2,
        "is_liked": false
      }
    ]
  }
}
```

## 4. Crear comentario

`POST /api/social/posts/{post}/comments`

### Request JSON

```json
{
  "message": "Gran trabajo equipo"
}
```

### Validaciones

- `message`: `required|string|max:1000`

### Response `201`

```json
{
  "data": {
    "id": 7009,
    "author": {
      "id": 21,
      "name": "Juan Perez",
      "avatar_url": "https://midominio.com/storage/users/21/avatar.jpg"
    },
    "message": "Gran trabajo equipo",
    "time_label": "Ahora",
    "created_at": "2026-04-24T18:35:00Z",
    "likes_count": 0,
    "is_liked": false
  }
}
```

## 5. Like / unlike post

`POST /api/social/posts/{post}/like`

### Response `200`

```json
{
  "data": {
    "post_id": 987,
    "is_liked": true,
    "likes_count": 15
  }
}
```

## 6. Like / unlike comentario

`POST /api/social/comments/{comment}/like`

### Response `200`

```json
{
  "data": {
    "comment_id": 7001,
    "is_liked": true,
    "likes_count": 3
  }
}
```

## 7. Buscar usuarios para mencionar

`GET /api/social/mentionable-users?query=andr&limit=20`

### Query params

- `query`: opcional, búsqueda parcial por nombre o email
- `limit`: opcional, min `1`, max `50`, default `20`

### Response `200`

```json
{
  "data": [
    {
      "id": 45,
      "name": "Andrea Soto",
      "avatar_url": "https://midominio.com/storage/users/45/avatar.jpg",
      "role_label": "Jugador"
    },
    {
      "id": 46,
      "name": "Andres Lopez",
      "avatar_url": "https://midominio.com/storage/users/46/avatar.jpg",
      "role_label": "Staff"
    }
  ]
}
```

## 8. Eliminar comentario

`DELETE /api/social/comments/{comment}`

### Permisos

- owner del comentario
- admin de la organización

### Response `200`

```json
{
  "message": "Comment deleted"
}
```

## 9. Eliminar post

`DELETE /api/social/posts/{post}`

### Permisos

- owner del post
- admin de la organización

### Response `200`

```json
{
  "message": "Post deleted"
}
```

## 10. Imagen Cloudflare: init upload

`POST /api/social/posts/{post}/images/init`

### Uso

1. crear post
2. pedir `uploadURL`
3. subir archivo directo desde app a Cloudflare
4. confirmar en backend

### Response `200`

```json
{
  "imageId": "8f6d9f70-xxxx",
  "uploadURL": "https://upload.imagedelivery.net/..."
}
```

## 11. Imagen Cloudflare: confirm

`POST /api/social/posts/{post}/images/confirm`

### Request JSON

```json
{
  "imageId": "8f6d9f70-xxxx",
  "position": 0,
  "variant": "public",
  "width": 1200,
  "height": 900
}
```

### Response `201`

```json
{
  "data": {
    "id": 5001,
    "type": "image",
    "url": "https://imagedelivery.net/.../public",
    "thumbnail_url": "https://imagedelivery.net/.../public",
    "duration_label": null,
    "order": 0,
    "width": 1200,
    "height": 900
  }
}
```

## 12. Video Cloudflare: init upload

`POST /api/social/posts/{post}/videos/init`

### Response `200`

```json
{
  "uid": "4f8f2c6dxxxx",
  "uploadURL": "https://upload.videodelivery.net/..."
}
```

## 13. Video Cloudflare: confirm

`POST /api/social/posts/{post}/videos/confirm`

### Request JSON

```json
{
  "uid": "4f8f2c6dxxxx",
  "position": 1,
  "width": 1080,
  "height": 1920,
  "duration_seconds": 18
}
```

### Response `201`

```json
{
  "data": {
    "id": 5002,
    "type": "video",
    "url": "https://videodelivery.net/4f8f2c6dxxxx/manifest/video.m3u8",
    "thumbnail_url": "https://videodelivery.net/4f8f2c6dxxxx/thumbnails/thumbnail.jpg",
    "duration_label": "0:18",
    "order": 1,
    "width": 1080,
    "height": 1920
  }
}
```

## Errores comunes

### `403`

Cuando el usuario intenta borrar o adjuntar media a un post que no le pertenece y no es admin.

```json
{
  "message": "No puedes eliminar este post."
}
```

### `404`

Cuando el post o comentario no pertenece a la organización activa del usuario.

### `422`

Errores de validación.

Ejemplo:

```json
{
  "message": "The message field is required.",
  "errors": {
    "message": [
      "The message field is required."
    ]
  }
}
```

### `422` máximo de media

```json
{
  "message": "Este post ya alcanzó el máximo de 10 archivos."
}
```

## Recomendación de flujo para front

### Crear post con media

1. `POST /api/social/posts`
2. por cada imagen:
   - `POST /api/social/posts/{post}/images/init`
   - upload directo a Cloudflare
   - `POST /api/social/posts/{post}/images/confirm`
3. por cada video:
   - `POST /api/social/posts/{post}/videos/init`
   - upload directo a Cloudflare
   - `POST /api/social/posts/{post}/videos/confirm`
4. refrescar detalle o feed

### Pintado del feed

- usar `comments_preview` en feed
- usar `comments` solo en detalle
- usar `is_liked` para estado del botón
- `avatar_url` puede venir `null`
- `caption` puede venir `null`
- `media` puede venir vacío

