# News API - Front Contract

## Base

- Base path: `/api/news`
- Auth requerida: `Authorization: Bearer {access_token}`
- Middleware: `auth:sanctum`
- Content type recomendado:
  - `Accept: application/json`
  - `Content-Type: application/json` para `PUT` y `POST`

## Deportes disponibles

Los valores actuales de `sport` que puede consumir el front son:

- `futbol_americano`
- `flag_football`
- `voleibol`
- `futbol`
- `basquetbol`

## News Item shape

Los endpoints de feed y detalle regresan noticias con esta forma:

```json
{
  "id": 39,
  "sport": "futbol_americano",
  "source_name": "ESPN",
  "source_country": "mx",
  "source_language": "es",
  "title": "Los playoffs arrancan este fin de semana",
  "summary": "Resumen corto de la noticia...",
  "article_url": "https://example.com/news/123",
  "image_url": "https://example.com/news/123.jpg",
  "status": "published",
  "relevance_score": 86,
  "published_at": "2026-04-23T18:30:00Z",
  "fetched_at": "2026-04-23T18:32:00Z",
  "seen_at": "2026-04-23T19:10:00Z",
  "is_seen": true
}
```

### Notas

- `status` para la app normalmente vendra como `published`
- `image_url` puede venir vacio `""`
- `seen_at` puede venir `null`
- `is_seen` indica si el usuario autenticado ya marco la noticia como vista

## 1. Feed

**GET** `/api/news/feed`

Devuelve el feed paginado de noticias publicadas para el usuario autenticado.

### Query params

- `sports` string o array opcional
  - acepta CSV: `futbol_americano,flag_football`
  - si no se manda, usa las preferencias activas del usuario
- `per_page` int opcional
  - default backend: `15`
  - max backend: `50`

### Ejemplos

```http
GET /api/news/feed
```

```http
GET /api/news/feed?per_page=10
```

```http
GET /api/news/feed?sports=futbol_americano,flag_football&per_page=20
```

### Response 200

```json
{
  "data": [
    {
      "id": 39,
      "sport": "futbol_americano",
      "source_name": "ESPN",
      "source_country": "mx",
      "source_language": "es",
      "title": "Los playoffs arrancan este fin de semana",
      "summary": "Resumen corto de la noticia...",
      "article_url": "https://example.com/news/123",
      "image_url": "https://example.com/news/123.jpg",
      "status": "published",
      "relevance_score": 86,
      "published_at": "2026-04-23T18:30:00Z",
      "fetched_at": "2026-04-23T18:32:00Z",
      "seen_at": null,
      "is_seen": false
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 15,
    "total": 39,
    "last_page": 3,
    "sports": [
      "futbol_americano",
      "flag_football"
    ]
  }
}
```

### Notas

- solo regresa noticias con `status = published`
- `meta.sports` indica los deportes efectivos usados para ese feed
- si el usuario aun no ha guardado preferencias, el backend usa los defaults configurados

## 2. News Detail

**GET** `/api/news/{newsItem}`

Devuelve el detalle de una noticia publicada.

### Path params

- `newsItem` int requerido

### Response 200

```json
{
  "item": {
    "id": 39,
    "sport": "futbol_americano",
    "source_name": "ESPN",
    "source_country": "mx",
    "source_language": "es",
    "title": "Los playoffs arrancan este fin de semana",
    "summary": "Resumen corto de la noticia...",
    "article_url": "https://example.com/news/123",
    "image_url": "https://example.com/news/123.jpg",
    "status": "published",
    "relevance_score": 86,
    "published_at": "2026-04-23T18:30:00Z",
    "fetched_at": "2026-04-23T18:32:00Z",
    "seen_at": null,
    "is_seen": false
  }
}
```

### Error 404

Sucede si la noticia no existe o no esta publicada.

```json
{
  "message": "Not Found"
}
```

## 3. Mark News As Seen

**POST** `/api/news/{newsItem}/seen`

Marca la noticia como vista para el usuario autenticado.

### Path params

- `newsItem` int requerido

### Response 200

```json
{
  "ok": true,
  "seen_at": "2026-04-23T19:10:00Z"
}
```

### Notas

- es idempotente
- si se vuelve a llamar, actualiza `seen_at`

## 4. Get News Preferences

**GET** `/api/news/preferences`

Devuelve la configuracion de noticias del usuario.

### Response 200

```json
{
  "news_push_enabled": true,
  "sports": [
    {
      "sport": "futbol_americano",
      "label": "Futbol Americano",
      "is_enabled": true,
      "push_enabled": true
    },
    {
      "sport": "flag_football",
      "label": "Flag Football",
      "is_enabled": true,
      "push_enabled": false
    },
    {
      "sport": "voleibol",
      "label": "Voleibol",
      "is_enabled": false,
      "push_enabled": false
    }
  ]
}
```

### Significado

- `news_push_enabled`
  - switch global para push de noticias
- `sports[].is_enabled`
  - define si ese deporte entra en el feed/preferencias del usuario
- `sports[].push_enabled`
  - define si ese deporte puede disparar push para el usuario

### Notas

- si el usuario aun no tiene rows en `user_news_preferences`, el backend responde usando defaults configurados
- hoy el feed usa `is_enabled`
- el envio de push usa `news_push_enabled` + `push_enabled`

## 5. Update News Preferences

**PUT** `/api/news/preferences`

Guarda la configuracion de noticias del usuario.

### Body

```json
{
  "news_push_enabled": true,
  "enabled_sports": [
    "futbol_americano",
    "flag_football"
  ],
  "push_enabled_sports": [
    "futbol_americano"
  ]
}
```

### Campos

- `news_push_enabled` boolean opcional
- `enabled_sports` array requerido, minimo 1
- `push_enabled_sports` array opcional

### Reglas de backend

- `enabled_sports` define los deportes activos del usuario
- si `push_enabled_sports` no se manda, backend usa el mismo set de `enabled_sports`
- si `push_enabled_sports` se manda, puede ser un subconjunto de `enabled_sports`
- valores desconocidos son filtrados por backend

### Response 200

```json
{
  "message": "Preferencias de noticias actualizadas correctamente.",
  "news_push_enabled": true,
  "sports": [
    {
      "sport": "futbol_americano",
      "label": "Futbol Americano",
      "is_enabled": true,
      "push_enabled": true
    },
    {
      "sport": "flag_football",
      "label": "Flag Football",
      "is_enabled": true,
      "push_enabled": false
    },
    {
      "sport": "voleibol",
      "label": "Voleibol",
      "is_enabled": false,
      "push_enabled": false
    }
  ]
}
```

### Error 422 example

```json
{
  "message": "The given data was invalid.",
  "errors": {
    "enabled_sports": [
      "The enabled sports field is required."
    ]
  }
}
```

## Recomendacion de front

Pantalla sugerida:

- switch global: `Recibir notificaciones de noticias`
- checklist de deportes para feed: `enabled_sports`
- checklist de deportes para push: `push_enabled_sports`

Flujo sugerido:

1. cargar `GET /api/news/preferences`
2. renderizar deportes con `label`
3. guardar con `PUT /api/news/preferences`
4. consumir feed con `GET /api/news/feed`
5. al abrir detalle, llamar `POST /api/news/{id}/seen`

## Resumen rapido

- `GET /api/news/feed`
- `GET /api/news/{newsItem}`
- `POST /api/news/{newsItem}/seen`
- `GET /api/news/preferences`
- `PUT /api/news/preferences`
