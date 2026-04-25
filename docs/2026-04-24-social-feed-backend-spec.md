# Social Feed Backend Spec

Fecha: 2026-04-24

## Objetivo

Implementar el backend del feed social del dashboard móvil para soportar:

- Crear posts con texto
- Adjuntar múltiples fotos y/o videos
- Mencionar usuarios
- Ver feed paginado
- Dar like a posts
- Comentar posts
- Dar like a comentarios
- Buscar usuarios para mencionar

El frontend Flutter ya está preparado con esta experiencia:

- Composer compacto en dashboard
- Pantalla dedicada de `Crear post`
- Preview de múltiples medios
- Sección de menciones con buscador
- Feed con posts, comentarios y likes

El backend debe reemplazar el mock actual con respuestas consistentes y listas para producción.

## Reglas funcionales

- Un post puede tener `caption`, cero o más medios y cero o más menciones.
- Los medios pueden ser `image` o `video`.
- El feed debe regresar posts ordenados del más reciente al más antiguo.
- Cada post debe incluir autor, métricas, estado `is_liked`, comentarios recientes, medios y menciones.
- Cada comentario debe incluir autor, mensaje, fecha, likes y `is_liked`.
- El backend debe devolver URLs válidas para avatar, imágenes, videos y thumbnails.
- Para videos, el feed debe regresar thumbnail y duración cuando exista.
- La búsqueda de usuarios para mencionar debe soportar query parcial.
- Todo debe respetar organización/equipo/tenant del usuario autenticado.

## Sugerencia técnica Laravel

- Auth con Sanctum o el guard actual
- Uploads con Media Library o storage propio
- API versionada, por ejemplo `/api/social/...`
- Paginación por cursor o `page/per_page`
- Transactions en create post y create comment
- Policies para visibilidad y ownership
- Eager loading para evitar N+1

## Endpoints propuestos

### 1. Crear post

`POST /api/social/posts`

Request `multipart/form-data`:

- `caption`: string
- `mentions[]`: array de user ids
- `media[]`: archivos
- `media_meta[]`: opcional JSON por archivo si quieren mandar orden/tipo

Ejemplo:

- `caption`: `"Gran entrenamiento hoy"`
- `mentions[]`: `12`
- `mentions[]`: `45`
- `media[]`: `file1.jpg`
- `media[]`: `file2.mp4`

Response `201`:

```json
{
  "data": {
    "id": 987,
    "author": {
      "id": 21,
      "name": "Juan Perez",
      "role_label": "Coach",
      "avatar_url": "https://cdn.midominio.com/users/21/avatar.jpg"
    },
    "time_label": "Ahora",
    "created_at": "2026-04-24T18:30:00Z",
    "caption": "Gran entrenamiento hoy",
    "mentions": [
      {
        "id": 12,
        "name": "Luis Garcia"
      },
      {
        "id": 45,
        "name": "Andrea Soto"
      }
    ],
    "media": [
      {
        "id": 5001,
        "type": "image",
        "url": "https://cdn.midominio.com/social/posts/987/photo1.jpg",
        "thumbnail_url": "https://cdn.midominio.com/social/posts/987/thumb_photo1.jpg",
        "duration_label": null,
        "order": 1,
        "width": 1200,
        "height": 900
      },
      {
        "id": 5002,
        "type": "video",
        "url": "https://cdn.midominio.com/social/posts/987/video1.mp4",
        "thumbnail_url": "https://cdn.midominio.com/social/posts/987/video1_thumb.jpg",
        "duration_label": "0:18",
        "order": 2,
        "width": 1080,
        "height": 1920
      }
    ],
    "likes_count": 0,
    "comments_count": 0,
    "is_liked": false,
    "comments_preview": []
  }
}
```

### 2. Ver feed

`GET /api/social/posts?page=1&per_page=10`

Response `200`:

```json
{
  "data": [
    {
      "id": 987,
      "author": {
        "id": 21,
        "name": "Juan Perez",
        "role_label": "Coach",
        "avatar_url": "https://cdn.midominio.com/users/21/avatar.jpg"
      },
      "time_label": "Hace 5 min",
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
          "url": "https://cdn.midominio.com/social/posts/987/photo1.jpg",
          "thumbnail_url": "https://cdn.midominio.com/social/posts/987/thumb_photo1.jpg",
          "duration_label": null,
          "order": 1,
          "width": 1200,
          "height": 900
        }
      ],
      "likes_count": 14,
      "comments_count": 3,
      "is_liked": true,
      "comments_preview": [
        {
          "id": 7001,
          "author": {
            "id": 33,
            "name": "Mariana Ruiz",
            "avatar_url": "https://cdn.midominio.com/users/33/avatar.jpg"
          },
          "message": "Se ve brutal",
          "time_label": "Hace 2 min",
          "created_at": "2026-04-24T18:33:00Z",
          "likes_count": 2,
          "is_liked": false
        }
      ]
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

### 3. Ver detalle de post

`GET /api/social/posts/{post}`

Response:

```json
{
  "data": {
    "id": 987,
    "author": {
      "id": 21,
      "name": "Juan Perez",
      "role_label": "Coach",
      "avatar_url": "https://cdn.midominio.com/users/21/avatar.jpg"
    },
    "time_label": "Hace 5 min",
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
        "url": "https://cdn.midominio.com/social/posts/987/photo1.jpg",
        "thumbnail_url": "https://cdn.midominio.com/social/posts/987/thumb_photo1.jpg",
        "duration_label": null,
        "order": 1
      }
    ],
    "likes_count": 14,
    "comments_count": 3,
    "is_liked": true,
    "comments": [
      {
        "id": 7001,
        "author": {
          "id": 33,
          "name": "Mariana Ruiz",
          "avatar_url": "https://cdn.midominio.com/users/33/avatar.jpg"
        },
        "message": "Se ve brutal",
        "time_label": "Hace 2 min",
        "created_at": "2026-04-24T18:33:00Z",
        "likes_count": 2,
        "is_liked": false
      }
    ]
  }
}
```

### 4. Comentar post

`POST /api/social/posts/{post}/comments`

Request JSON:

```json
{
  "message": "Gran trabajo equipo"
}
```

Response `201`:

```json
{
  "data": {
    "id": 7009,
    "author": {
      "id": 21,
      "name": "Juan Perez",
      "avatar_url": "https://cdn.midominio.com/users/21/avatar.jpg"
    },
    "message": "Gran trabajo equipo",
    "time_label": "Ahora",
    "created_at": "2026-04-24T18:35:00Z",
    "likes_count": 0,
    "is_liked": false
  }
}
```

### 5. Like / unlike post

Opción toggle:

`POST /api/social/posts/{post}/like`

Response:

```json
{
  "data": {
    "post_id": 987,
    "is_liked": true,
    "likes_count": 15
  }
}
```

Opción REST recomendada:

- `POST /api/social/posts/{post}/likes`
- `DELETE /api/social/posts/{post}/likes`

### 6. Like / unlike comentario

Opción toggle:

`POST /api/social/comments/{comment}/like`

Response:

```json
{
  "data": {
    "comment_id": 7001,
    "is_liked": true,
    "likes_count": 3
  }
}
```

Opción REST recomendada:

- `POST /api/social/comments/{comment}/likes`
- `DELETE /api/social/comments/{comment}/likes`

### 7. Buscar usuarios para mencionar

`GET /api/social/mentionable-users?query=andr&limit=20`

Response:

```json
{
  "data": [
    {
      "id": 45,
      "name": "Andrea Soto",
      "avatar_url": "https://cdn.midominio.com/users/45/avatar.jpg",
      "role_label": "Jugador"
    },
    {
      "id": 46,
      "name": "Andres Lopez",
      "avatar_url": "https://cdn.midominio.com/users/46/avatar.jpg",
      "role_label": "Staff"
    }
  ]
}
```

### 8. Eliminar comentario

Opcional, pero recomendable.

`DELETE /api/social/comments/{comment}`

Response:

```json
{
  "message": "Comment deleted"
}
```

### 9. Eliminar post

Opcional, pero recomendable para owner/admin/coach según policy.

`DELETE /api/social/posts/{post}`

Response:

```json
{
  "message": "Post deleted"
}
```

## Shape exacto esperado por el front

```json
{
  "id": 987,
  "author": {
    "id": 21,
    "name": "Juan Perez",
    "role_label": "Coach",
    "avatar_url": "https://cdn.midominio.com/users/21/avatar.jpg"
  },
  "time_label": "Hace 5 min",
  "created_at": "2026-04-24T18:30:00Z",
  "caption": "Texto del post",
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
      "url": "https://cdn.midominio.com/file.jpg",
      "thumbnail_url": "https://cdn.midominio.com/thumb.jpg",
      "duration_label": null,
      "order": 1
    },
    {
      "id": 5002,
      "type": "video",
      "url": "https://cdn.midominio.com/file.mp4",
      "thumbnail_url": "https://cdn.midominio.com/thumb_video.jpg",
      "duration_label": "0:18",
      "order": 2
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
        "avatar_url": "https://cdn.midominio.com/users/90/avatar.jpg"
      },
      "message": "Buenísimo",
      "time_label": "Hace 1 min",
      "created_at": "2026-04-24T18:31:00Z",
      "likes_count": 1,
      "is_liked": false
    }
  ]
}
```

## Validaciones sugeridas

- `caption`: `nullable|string|max:3000`
- `media`: máximo 10 archivos por post
- imágenes: `jpg`, `jpeg`, `png`, `webp`
- videos: `mp4`, `mov`
- debe existir al menos uno:
  - `caption`
  - o `media`
- `mentions[]`: ids válidos y visibles en la organización actual
- comentario:
  - `message`: `required|string|max:1000`

## Tablas sugeridas

### `social_posts`

- `id`
- `organization_id`
- `user_id`
- `caption`
- `created_at`
- `updated_at`
- `deleted_at`

### `social_post_media`

- `id`
- `post_id`
- `type` (`image|video`)
- `path`
- `thumbnail_path`
- `duration_seconds`
- `sort_order`
- `width`
- `height`

### `social_post_mentions`

- `id`
- `post_id`
- `mentioned_user_id`

### `social_post_likes`

- `id`
- `post_id`
- `user_id`

### `social_post_comments`

- `id`
- `post_id`
- `user_id`
- `message`
- `created_at`
- `updated_at`
- `deleted_at`

### `social_comment_likes`

- `id`
- `comment_id`
- `user_id`

## Resources Laravel sugeridos

- `SocialPostResource`
- `SocialCommentResource`
- `MentionableUserResource`

## Campos computados necesarios

- `time_label`
- `likes_count`
- `comments_count`
- `is_liked`
- `duration_label`
- `comments_preview`

## Recomendaciones adicionales

- Paginación real
- Soft deletes
- Moderación o reportes opcional
- Permisos:
  - quién puede postear
  - quién puede borrar
  - quién puede ver
- Procesamiento async de thumbnails de video
- Compresión y optimización de imágenes
- Eventos o notificaciones al mencionar usuario
- Rate limit para comentarios y likes
- Tests de policies y resources

## Notas para backend

- El front ya soporta múltiples medios mixtos.
- El front ya soporta likes en post y comentario.
- El front ya soporta búsqueda de usuarios para mencionar.
- El front usa `avatar_url` para mostrar fotos de perfil.
- Para comentarios conviene regresar `author.avatar_url` desde ya.

